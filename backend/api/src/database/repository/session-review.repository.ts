import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type {
  EligibleReviewSession,
  PaginationParams,
  RatingAggregate,
} from '../../social/interface';
import { SessionReviewEntity } from '../entity/session-review.entity';

@Injectable()
export class SessionReviewRepository {
  constructor(
    @InjectRepository(SessionReviewEntity)
    private readonly reviews: Repository<SessionReviewEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<SessionReviewEntity>): SessionReviewEntity {
    return this.reviews.create(data);
  }

  /**
   *
   */
  async save(entity: SessionReviewEntity): Promise<SessionReviewEntity> {
    return this.reviews.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<SessionReviewEntity | null> {
    return this.reviews.findOne({
      where: { id },
      relations: { session: true },
    });
  }

  /**
   *
   */
  async findBySessionId(sessionId: string): Promise<SessionReviewEntity | null> {
    return this.reviews.findOne({ where: { sessionId } });
  }

  /**
   *
   */
  async findByStudentId(studentId: string): Promise<SessionReviewEntity[]> {
    return this.reviews.find({
      where: { studentId },
      relations: { session: true },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   *
   */
  async findByCoachId(
    coachId: string,
    params: PaginationParams,
  ): Promise<[SessionReviewEntity[], number]> {
    return this.reviews.findAndCount({
      where: { coachId },
      relations: { session: true },
      order: { createdAt: 'DESC', id: 'ASC' },
      skip: (params.page - 1) * params.limit,
      take: params.limit,
    });
  }

  /**
   *
   */
  async ratingForCoach(coachId: string): Promise<RatingAggregate> {
    const raw = (await this.reviews
      .createQueryBuilder('review')
      .select('AVG(review.rating)::float', 'averageRating')
      .addSelect('COUNT(review.id)::int', 'reviewCount')
      .where('review.coach_id = :coachId', { coachId })
      .getRawOne()) as
      | { averageRating: number | null; reviewCount: number; }
      | undefined;

    return {
      averageRating:
        raw?.averageRating === null || raw?.averageRating === undefined? null: Number(raw.averageRating),
      reviewCount: Number(raw?.reviewCount ?? 0),
    };
  }

  /**
   *
   */
  async findEligible(studentId: string): Promise<EligibleReviewSession[]> {
    const rows = (await this.reviews.manager
      .createQueryBuilder()
      .select([
        'session.id AS "sessionId"',
        'session.coach_id AS "coachId"',
        'profile.display_name AS "coachDisplayName"',
        'session.starts_at AS "startsAt"',
        'session.ends_at AS "endsAt"',
        'session.mode AS "mode"',
      ])
      .from('sessions', 'session')
      .leftJoin(
        'session_reviews',
        'review',
        'review.session_id = session.id',
      )
      .leftJoin('user_profiles', 'profile', 'profile.user_id = session.coach_id')
      .where('session.student_id = :studentId', { studentId })
      .andWhere('session.status = \'completed\'')
      .andWhere('review.id IS NULL')
      .orderBy('session.starts_at', 'DESC')
      .getRawMany()) as Array<{
      sessionId: string;
      coachId: string;
      coachDisplayName: string | null;
      startsAt: Date;
      endsAt: Date;
      mode: 'online' | 'offline';
    }>;

    return rows;
  }
}
