import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import type {
  ListTrainersParams,
  TrainerDiscoveryRecord,
  TrainerDiscoveryRecords,
} from '../../social/interface';
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
        '(profile.display_name ILIKE :query OR profile.city ILIKE :query)',
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
}
