import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CoachStudentLinkRepository } from '../database/repository/coach-student-link.repository';
import { UserProfileRepository } from '../database/repository/user-profile.repository';
import { SessionPackageRepository } from '../database/repository/session-package.repository';
import { SessionPackageEntity } from '../database/entity/session-package.entity';
import type {
  ArchiveSessionPackageParams,
  CreateSessionPackageParams,
  ExtendSessionPackageParams,
  GetSessionPackageParams,
  ListSessionPackagesParams,
  SessionPackageReturns,
} from './interface';
import type { SessionPackageStatus } from './interface/session-package.types';

@Injectable()
export class SessionPackagesService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly packages: SessionPackageRepository,
    private readonly links: CoachStudentLinkRepository,
    private readonly profiles: UserProfileRepository,
  ) {}

  async create(
    params: CreateSessionPackageParams,
  ): Promise<SessionPackageReturns> {
    const link = await this.links.findByPair(params.coachId, params.studentId);
    if (!link) {
      throw new ForbiddenException('Coach and student are not linked');
    }

    const existing = await this.packages.findActiveByPair(
      params.coachId,
      params.studentId,
    );
    if (existing) {
      const refreshed = await this.applyLazyExpire(existing);
      if (refreshed.status === 'active') {
        throw new ConflictException(
          'Active session package already exists for this pair; extend it instead',
        );
      }
    }

    const expiresAt = params.expiresAt ?? null;
    if (expiresAt !== null && expiresAt.getTime() <= Date.now()) {
      throw new ConflictException('expiresAt must be in the future');
    }

    const created = await this.packages.save(
      this.packages.create({
        coachId: params.coachId,
        studentId: params.studentId,
        totalSessions: params.totalSessions,
        remainingSessions: params.totalSessions,
        expiresAt,
        status: 'active',
        archivedAt: null,
      }),
    );

    const withPeople = await this.packages.findById(created.id);
    if (!withPeople) {
      throw new NotFoundException('Session package not found after create');
    }
    return await this.toPublic(withPeople);
  }

  async list(
    params: ListSessionPackagesParams,
  ): Promise<SessionPackageReturns[]> {
    const rows = await this.packages.findByParticipant(params.actorId);
    const result: SessionPackageReturns[] = [];
    for (const row of rows) {
      const refreshed = await this.applyLazyExpire(row);
      result.push(await this.toPublic(refreshed));
    }
    return result;
  }

  async get(params: GetSessionPackageParams): Promise<SessionPackageReturns> {
    const pkg = await this.packages.findById(params.packageId);
    if (!pkg) {
      throw new NotFoundException('Session package not found');
    }
    if (
      pkg.coachId !== params.actorId &&
      pkg.studentId !== params.actorId
    ) {
      throw new ForbiddenException('Not a participant of this package');
    }
    const refreshed = await this.applyLazyExpire(pkg);
    return await this.toPublic(refreshed);
  }

  async extend(
    params: ExtendSessionPackageParams,
  ): Promise<SessionPackageReturns> {
    await this.dataSource.transaction(async manager => {
      const pkg = await manager.findOne(SessionPackageEntity, {
        where: { id: params.packageId, coachId: params.coachId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!pkg) {
        throw new NotFoundException('Session package not found');
      }
      if (pkg.status === 'archived') {
        throw new ConflictException('Archived package cannot be extended');
      }

      await this.applyLazyExpireInManager(manager, pkg);

      if (params.expiresAt !== undefined) {
        if (
          params.expiresAt !== null &&
          params.expiresAt.getTime() <= Date.now()
        ) {
          throw new ConflictException('expiresAt must be in the future');
        }
        pkg.expiresAt = params.expiresAt;
      }

      pkg.totalSessions += params.addSessions;
      pkg.remainingSessions += params.addSessions;

      const now = new Date();
      const notExpired =
        pkg.expiresAt === null || pkg.expiresAt.getTime() > now.getTime();
      if (pkg.remainingSessions > 0 && notExpired) {
        pkg.status = 'active';
        pkg.archivedAt = null;
      } else if (pkg.remainingSessions === 0) {
        pkg.status = 'exhausted';
      }

      await manager.save(pkg);
    });

    const withPeople = await this.packages.findById(params.packageId);
    if (!withPeople) {
      throw new NotFoundException('Session package not found after extend');
    }
    return await this.toPublic(withPeople);
  }

  async archive(
    params: ArchiveSessionPackageParams,
  ): Promise<SessionPackageReturns> {
    const pkg = await this.packages.findById(params.packageId);
    if (!pkg || pkg.coachId !== params.coachId) {
      throw new NotFoundException('Session package not found');
    }
    if (pkg.status === 'archived') {
      return await this.toPublic(pkg);
    }
    pkg.status = 'archived';
    pkg.archivedAt = new Date();
    const saved = await this.packages.save(pkg);
    return await this.toPublic(saved);
  }

  private async applyLazyExpire(
    pkg: SessionPackageEntity,
  ): Promise<SessionPackageEntity> {
    if (
      pkg.status === 'active' &&
      pkg.expiresAt !== null &&
      pkg.expiresAt.getTime() < Date.now()
    ) {
      pkg.status = 'expired' satisfies SessionPackageStatus;
      return this.packages.save(pkg);
    }
    return pkg;
  }

  private async applyLazyExpireInManager(
    manager: {
      save: (entity: SessionPackageEntity) => Promise<SessionPackageEntity>;
    },
    pkg: SessionPackageEntity,
  ): Promise<void> {
    if (
      pkg.status === 'active' &&
      pkg.expiresAt !== null &&
      pkg.expiresAt.getTime() < Date.now()
    ) {
      pkg.status = 'expired';
      await manager.save(pkg);
    }
  }

  private async toPublic(
    pkg: SessionPackageEntity,
  ): Promise<SessionPackageReturns> {
    const profiles = await this.profiles.findByUserIds([
      pkg.coachId,
      pkg.studentId,
    ]);
    const nameById = new Map(profiles.map(p => [p.userId, p.displayName]));
    return {
      id: pkg.id,
      coachId: pkg.coachId,
      studentId: pkg.studentId,
      totalSessions: pkg.totalSessions,
      remainingSessions: pkg.remainingSessions,
      expiresAt: pkg.expiresAt?.toISOString() ?? null,
      status: pkg.status,
      createdAt: pkg.createdAt.toISOString(),
      updatedAt: pkg.updatedAt.toISOString(),
      archivedAt: pkg.archivedAt?.toISOString() ?? null,
      coachEmail: pkg.coach?.email ?? null,
      studentEmail: pkg.student?.email ?? null,
      coachDisplayName: nameById.get(pkg.coachId) ?? null,
      studentDisplayName: nameById.get(pkg.studentId) ?? null,
    };
  }
}
