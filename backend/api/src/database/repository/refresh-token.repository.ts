import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RefreshTokenEntity } from '../entity/refresh-token.entity';

@Injectable()
export class RefreshTokenRepository {
  constructor(
    @InjectRepository(RefreshTokenEntity)
    private readonly tokens: Repository<RefreshTokenEntity>,
  ) {}

  /**
   *
   */
  async findByTokenHash(tokenHash: string): Promise<RefreshTokenEntity | null> {
    return this.tokens.findOne({ where: { tokenHash } });
  }

  /**
   *
   */
  async createToken(params: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<RefreshTokenEntity> {
    const entity = this.tokens.create(params);

    return this.tokens.save(entity);
  }

  /**
   *
   */
  async revoke(id: string): Promise<void> {
    await this.tokens.update({ id }, { revokedAt: new Date() });
  }
}
