import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository, SelectQueryBuilder } from 'typeorm';
import type {
  ListTrainersParams,
  TrainerDiscoveryRecord,
  TrainerDiscoveryRecords,
} from '../../social/interface';
import { escapeLike } from '../util/escape-like.util';
import { UserProfileEntity } from '../entity/user-profile.entity';

@Injectable()
export class UserProfileRepository {
  constructor(
    @InjectRepository(UserProfileEntity)
    private readonly profiles: Repository<UserProfileEntity>,
  ) {}

  /**
   *
   */
  async findByUserId(userId: string): Promise<UserProfileEntity | null> {
    return this.profiles.findOne({ where: { userId } });
  }

  /**
   *
   */
  async findByUserIds(userIds: string[]): Promise<UserProfileEntity[]> {
    if (userIds.length === 0) {
      return [];
    }

    return this.profiles.find({ where: { userId: In(userIds) } });
  }

  /**
   *
   */
  create(data: Partial<UserProfileEntity>): UserProfileEntity {
    return this.profiles.create(data);
  }

  /**
   *
   */
  async save(entity: UserProfileEntity): Promise<UserProfileEntity> {
    return this.profiles.save(entity);
  }

  /**
   *
   */
  async findDiscoverableTrainer(
    userId: string,
  ): Promise<UserProfileEntity | null> {
    return this.profiles
      .createQueryBuilder('profile')
      .innerJoin('users', 'user', 'user.id = profile.user_id')
      .innerJoin('user_roles', 'ur', 'ur.user_id = user.id')
      .innerJoin(
        'roles',
        'role',
        'role.id = ur.role_id AND role.slug = \'trainer\'',
      )
      .where('profile.user_id = :userId', { userId })
      .andWhere('profile.is_discoverable = true')
      .andWhere('profile.display_name IS NOT NULL')
      .getOne();
  }

  /**
   *
   */
  async listDiscoverable(
    params: ListTrainersParams,
  ): Promise<TrainerDiscoveryRecords> {
    const base = this.profiles
      .createQueryBuilder('profile')
      .innerJoin('users', 'user', 'user.id = profile.user_id')
      .innerJoin('user_roles', 'ur', 'ur.user_id = user.id')
      .innerJoin(
        'roles',
        'role',
        'role.id = ur.role_id AND role.slug = \'trainer\'',
      )
      .leftJoin('session_reviews', 'review', 'review.coach_id = profile.user_id')
      .where('profile.is_discoverable = true')
      .andWhere('profile.display_name IS NOT NULL');

    if (params.query) {
      base.andWhere(
        '(profile.display_name ILIKE :query OR profile.city ILIKE :query OR EXISTS (SELECT 1 FROM trainer_gyms tgq INNER JOIN gyms gq ON gq.id = tgq.gym_id WHERE tgq.coach_id = profile.user_id AND gq.city ILIKE :query))',
        { query: `%${params.query}%` },
      );
    }
    if (params.specialty) {
      base.andWhere(':specialty = ANY(profile.specialties)', {
        specialty: params.specialty,
      });
    }
    if (params.mode) {
      base.andWhere(':mode = ANY(profile.training_modes)', {
        mode: params.mode,
      });
    }

    this.applyGymFilters(base, params);

    const countQb = base.clone().select('COUNT(DISTINCT profile.user_id)', 'count');
    const countRaw = (await countQb.getRawOne()) as { count?: string; } | undefined;

    const rows = (await base
      .select([
        'profile.user_id AS "userId"',
        'profile.display_name AS "displayName"',
        'profile.avatar_url AS "avatarUrl"',
        'profile.bio AS "bio"',
        'profile.city AS "city"',
        'profile.specialties AS "specialties"',
        'profile.training_modes AS "trainingModes"',
        'profile.show_rating AS "showRating"',
        'AVG(review.rating)::float AS "averageRating"',
        'COUNT(review.id)::int AS "reviewCount"',
      ])
      .groupBy('profile.user_id')
      .orderBy('AVG(review.rating)', 'DESC', 'NULLS LAST')
      .addOrderBy('COUNT(review.id)', 'DESC')
      .addOrderBy('profile.user_id', 'ASC')
      .offset((params.page - 1) * params.limit)
      .limit(params.limit)
      .getRawMany()) as Array<{
      userId: string;
      displayName: string;
      avatarUrl: string | null;
      bio: string | null;
      city: string | null;
      specialties: string[];
      trainingModes: Array<'online' | 'offline'>;
      showRating: boolean;
      averageRating: number | null;
      reviewCount: number;
    }>;

    const items: TrainerDiscoveryRecord[] = rows.map(row => ({
      profile: {
        userId: row.userId,
        displayName: row.displayName,
        avatarUrl: row.avatarUrl,
        bio: row.bio,
        city: row.city,
        specialties: row.specialties,
        trainingModes: row.trainingModes,
        showRating: row.showRating,
      },
      averageRating:
        row.averageRating === null ? null : Number(row.averageRating),
      reviewCount: Number(row.reviewCount),
    }));

    return { items, total: Number(countRaw?.count ?? 0) };
  }

  /**
   * Фильтры по залам и городу. Условия по залу проверяются на одном и том же
   * зале тренера (EXISTS), поэтому строки профиля не дублируются.
   */
  private applyGymFilters(
    qb: SelectQueryBuilder<UserProfileEntity>,
    params: ListTrainersParams,
  ): void {
    const gymConditions: string[] = [];
    const gymParams: Record<string, string> = {};
    if (params.gymId) {
      gymConditions.push('g.id = :gymId');
      gymParams['gymId'] = params.gymId;
    }
    if (params.district) {
      gymConditions.push('g.district ILIKE :district ESCAPE \'\\\'');
      gymParams['district'] = `%${escapeLike(params.district)}%`;
    }
    if (params.gymQuery) {
      gymConditions.push(
        '(g.name ILIKE :gymQuery ESCAPE \'\\\' OR g.address ILIKE :gymQuery ESCAPE \'\\\')',
      );
      gymParams['gymQuery'] = `%${escapeLike(params.gymQuery)}%`;
    }
    /**
     *
     */
    function gymExists(extra: string[]): string {
      const conditions = extra.map(condition => ` AND ${condition}`).join('');

      return `EXISTS (SELECT 1 FROM trainer_gyms tg INNER JOIN gyms g ON g.id = tg.gym_id WHERE tg.coach_id = profile.user_id${conditions})`;
    }

    if (gymConditions.length > 0) {
      qb.andWhere(gymExists(gymConditions), gymParams);
    }
    if (params.city) {
      qb.andWhere(
        `(profile.city ILIKE :city ESCAPE '\\' OR ${gymExists(['g.city ILIKE :city ESCAPE \'\\\''])})`,
        { city: `%${escapeLike(params.city)}%` },
      );
    }
  }
}
