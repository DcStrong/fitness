import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { GymEntity } from '../entity/gym.entity';
import { TrainerGymEntity } from '../entity/trainer-gym.entity';

@Injectable()
export class TrainerGymRepository {
  constructor(
    @InjectRepository(TrainerGymEntity)
    private readonly links: Repository<TrainerGymEntity>,
  ) {}

  /**
   *
   */
  async countByCoachId(coachId: string): Promise<number> {
    return this.links.count({ where: { coachId } });
  }

  /**
   *
   */
  async exists(coachId: string, gymId: string): Promise<boolean> {
    return this.links.exists({ where: { coachId, gymId } });
  }

  /**
   * Привязка идемпотентна: повторная вставка пары игнорируется.
   */
  async attach(coachId: string, gymId: string): Promise<void> {
    await this.links
      .createQueryBuilder()
      .insert()
      .values({ coachId, gymId })
      .orIgnore()
      .execute();
  }

  /**
   * @returns `true`, если привязка существовала и удалена
   */
  async detach(coachId: string, gymId: string): Promise<boolean> {
    const result = await this.links.delete({ coachId, gymId });

    return (result.affected ?? 0) > 0;
  }

  /**
   *
   */
  async findGymsByCoachId(coachId: string): Promise<GymEntity[]> {
    const rows = await this.links.find({
      where: { coachId },
      relations: { gym: true },
      order: { createdAt: 'ASC', gymId: 'ASC' },
    });

    return rows.map(row => row.gym);
  }

  /**
   * Залы нескольких тренеров одним запросом.
   */
  async findGymsByCoachIds(
    coachIds: string[],
  ): Promise<Map<string, GymEntity[]>> {
    const result = new Map<string, GymEntity[]>();
    if (coachIds.length === 0) {
      return result;
    }
    const rows = await this.links.find({
      where: { coachId: In(coachIds) },
      relations: { gym: true },
      order: { createdAt: 'ASC', gymId: 'ASC' },
    });
    for (const row of rows) {
      const list = result.get(row.coachId) ?? [];
      list.push(row.gym);
      result.set(row.coachId, list);
    }

    return result;
  }
}
