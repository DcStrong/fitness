import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';
import { RefreshTokenRepository } from '../database/repository/refresh-token.repository';
import { RoleRepository } from '../database/repository/role.repository';
import { UserRepository } from '../database/repository/user.repository';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import type { AuthProfile, AuthResponse, LogoutReturns } from './interface';
import { PermissionEntity } from '../database/entity';

const BCRYPT_ROUNDS = 10;

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UserRepository,
    private readonly roles: RoleRepository,
    private readonly refreshTokens: RefreshTokenRepository,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  /**
   *
   */
  async register(dto: RegisterDto): Promise<AuthResponse> {
    const email = dto.email.toLowerCase().trim();
    const existing = await this.users.findByEmail(email);
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const role = await this.roles.findBySlug(dto.role);
    if (!role) {
      throw new ConflictException('Role not found');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = await this.users.createWithRole(email, passwordHash, role);

    return this.issueAuthForUser(user.id);
  }

  /**
   *
   */
  async login(dto: LoginDto): Promise<AuthResponse> {
    const email = dto.email.toLowerCase().trim();
    const user = await this.users.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.issueAuthForUser(user.id);
  }

  /**
   *
   */
  async refresh(refreshToken: string): Promise<AuthResponse> {
    const tokenHash = this.hashToken(refreshToken);
    const stored = await this.refreshTokens.findByTokenHash(tokenHash);

    if (!stored || stored.revokedAt || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    await this.refreshTokens.revoke(stored.id);

    return this.issueAuthForUser(stored.userId);
  }

  /**
   *
   */
  async logout(refreshToken: string): Promise<LogoutReturns> {
    const tokenHash = this.hashToken(refreshToken);
    const stored = await this.refreshTokens.findByTokenHash(tokenHash);

    if (stored && !stored.revokedAt) {
      await this.refreshTokens.revoke(stored.id);
    }

    return { success: true };
  }

  /**
   *
   */
  async getProfile(userId: string): Promise<AuthProfile> {
    return this.buildProfile(userId);
  }

  /**
   *
   */
  private async issueAuthForUser(userId: string): Promise<AuthResponse> {
    const profile = await this.buildProfile(userId);
    const accessTtl = (this.config.get<string>('JWT_ACCESS_TTL') ??
      '15m') as `${number}m`;
    const accessToken = await this.jwt.signAsync(
      {
        sub: profile.id,
        email: profile.email,
        roles: profile.roles,
        permissions: profile.permissions,
      },
      {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: accessTtl,
      },
    );

    const refreshToken = randomBytes(48).toString('hex');
    const days = Number(this.config.get('JWT_REFRESH_TTL_DAYS') ?? 30);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + days);

    await this.refreshTokens.createToken({
      userId,
      tokenHash: this.hashToken(refreshToken),
      expiresAt,
    });

    return { accessToken, refreshToken, user: profile };
  }

  /**
   *
   */
  private async buildProfile(userId: string): Promise<AuthProfile> {
    const user = await this.users.findByIdWithAccess(userId);
    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const roles = (user.roles ?? []).map(role => role.slug);
    const permissions = [
      ...new Set(
        (user.roles ?? []).flatMap(role =>
          (role.permissions ?? []).map((permission: PermissionEntity) => permission.code)),
      ),
    ];

    return {
      id: user.id,
      email: user.email,
      roles,
      permissions,
    };
  }

  /**
   *
   */
  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
