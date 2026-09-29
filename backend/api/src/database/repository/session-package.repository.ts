import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SessionPackageEntity } from '../entity/session-package.entity';
import type { SessionPackageStatus } from '../../session-packages/interface/session-package.types';

@Injectable()
export class SessionPackageRepository {
  constructor(
    @InjectRepository(SessionPackageEntity)
    private readonly packages: Repository<SessionPackageEntity>,
  ) {}

  create(data: Partial<SessionPackageEntity>): SessionPackageEntity {
    return this.packages.create(data);
  }

  async save(entity: SessionPackageEntity): Promise<SessionPackageEntity> {
    return this.packages.save(entity);
  }

  async findById(id: string): Promise<SessionPackageEntity | null> {
    return this.packages.findOne({
      where: { id },
      relations: { coach: true, student: true },
    });
  }

  async findActiveByPair(
    coachId: string,
    studentId: string,
  ): Promise<SessionPackageEntity | null> {
    return this.packages.findOne({
      where: {
        coachId,
        studentId,
        status: 'active' satisfies SessionPackageStatus,
      },
    });
  }

  async findByCoachId(coachId: string): Promise<SessionPackageEntity[]> {
    return this.packages.find({
      where: { coachId },
      relations: { coach: true, student: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findByStudentId(studentId: string): Promise<SessionPackageEntity[]> {
    return this.packages.find({
      where: { studentId },
      relations: { coach: true, student: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findByParticipant(actorId: string): Promise<SessionPackageEntity[]> {
    return this.packages
      .createQueryBuilder('pkg')
      .leftJoinAndSelect('pkg.coach', 'coach')
      .leftJoinAndSelect('pkg.student', 'student')
      .where('pkg.coach_id = :actorId OR pkg.student_id = :actorId', {
        actorId,
      })
      .orderBy('pkg.created_at', 'DESC')
      .getMany();
  }
}
