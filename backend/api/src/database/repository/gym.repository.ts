import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { SuggestGymsParams } from '../../gyms/interface';
import { escapeLike } from '../util/escape-like.util';
import { GymEntity } from '../entity/gym.entity';

@Injectable()
export class GymRepository {
  constructor(
    @InjectRepository(GymEntity)
    private readonly gyms: Repository<GymEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<GymEntity>): GymEntity {
    return this.gyms.create(data);
  }

  /**
   *
   */
  async save(entity: GymEntity): Promise<GymEntity> {
    return this.gyms.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<GymEntity | null> {
    return this.gyms.findOne({ where: { id } });
  }

  /**
   *
   */
  async findByDedupeKey(dedupeKey: string): Promise<GymEntity | null> {
    return this.gyms.findOne({ where: { dedupeKey } });
  }

  /**
   * Атомарно создаёт зал; при гонке двух тренеров возвращает уже созданный.
   */
  async insertIfAbsent(data: Partial<GymEntity>): Promise<GymEntity> {
    await this.gyms
      .createQueryBuilder()
      .insert()
      .values(data)
      .orIgnore()
      .execute();
    const gym = await this.findByDedupeKey(data.dedupeKey as string);
    if (!gym) {
      throw new Error('Gym was not persisted');
    }

    return gym;
  }

  /**
   *
   */
  async suggest(params: SuggestGymsParams): Promise<GymEntity[]> {
    const qb = this.gyms.createQueryBuilder('gym');
    if (params.query) {
      qb.andWhere(
        '(gym.name ILIKE :query ESCAPE \'\\\' OR gym.address ILIKE :query ESCAPE \'\\\')',
        { query: `%${escapeLike(params.query)}%` },
      );
    }
    if (params.city) {
      qb.andWhere('gym.city ILIKE :city ESCAPE \'\\\'', {
        city: `%${escapeLike(params.city)}%`,
      });
    }

    return qb
      .orderBy('gym.name', 'ASC')
      .addOrderBy('gym.id', 'ASC')
      .limit(params.limit)
      .getMany();
  }
}
