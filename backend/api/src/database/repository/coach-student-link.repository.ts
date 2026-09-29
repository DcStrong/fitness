import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { UpsertLinkParams } from '../../invitations/interface/upsert-link.params';
import { CoachStudentLinkEntity } from '../entity/coach-student-link.entity';

@Injectable()
export class CoachStudentLinkRepository {
  constructor(
    @InjectRepository(CoachStudentLinkEntity)
    private readonly links: Repository<CoachStudentLinkEntity>,
  ) {}

  /**
   *
   */
  async findByPair(
    coachId: string,
    studentId: string,
  ): Promise<CoachStudentLinkEntity | null> {
    return this.links.findOne({ where: { coachId, studentId } });
  }

  /**
   *
   */
  async upsertLink(
    input: UpsertLinkParams,
  ): Promise<{ link: CoachStudentLinkEntity; created: boolean; }> {
    const existing = await this.findByPair(input.coachId, input.studentId);
    if (existing) {
      return { link: existing, created: false };
    }

    const link = this.links.create({
      coachId: input.coachId,
      studentId: input.studentId,
      sourceInvitationId: input.sourceInvitationId,
    });
    const saved = await this.links.save(link);

    return { link: saved, created: true };
  }

  /**
   *
   */
  async findForUser(userId: string): Promise<CoachStudentLinkEntity[]> {
    return this.links
      .createQueryBuilder('link')
      .leftJoinAndSelect('link.coach', 'coach')
      .leftJoinAndSelect('link.student', 'student')
      .where('link.coach_id = :userId OR link.student_id = :userId', { userId })
      .orderBy('link.created_at', 'DESC')
      .getMany();
  }
}
