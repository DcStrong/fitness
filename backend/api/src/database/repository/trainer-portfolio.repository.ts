import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { TrainerPortfolioItemEntity } from '../entity/trainer-portfolio-item.entity';

@Injectable()
export class TrainerPortfolioRepository {
  constructor(
    @InjectRepository(TrainerPortfolioItemEntity)
    private readonly items: Repository<TrainerPortfolioItemEntity>,
  ) {}

  /**
   *
   */
  create(data: Partial<TrainerPortfolioItemEntity>): TrainerPortfolioItemEntity {
    return this.items.create(data);
  }

  /**
   *
   */
  async save(
    entity: TrainerPortfolioItemEntity,
  ): Promise<TrainerPortfolioItemEntity> {
    return this.items.save(entity);
  }

  /**
   *
   */
  async saveMany(
    entities: TrainerPortfolioItemEntity[],
  ): Promise<TrainerPortfolioItemEntity[]> {
    return this.items.save(entities);
  }

  /**
   *
   */
  async findByCoachId(coachId: string): Promise<TrainerPortfolioItemEntity[]> {
    return this.items.find({
      where: { coachId },
      order: { sortOrder: 'ASC', id: 'ASC' },
    });
  }

  /**
   *
   */
  async findById(id: string): Promise<TrainerPortfolioItemEntity | null> {
    return this.items.findOne({ where: { id } });
  }

  /**
   *
   */
  async findByIds(ids: string[]): Promise<TrainerPortfolioItemEntity[]> {
    return this.items.find({ where: { id: In(ids) } });
  }

  /**
   *
   */
  async countByCoachId(coachId: string): Promise<number> {
    return this.items.count({ where: { coachId } });
  }

  /**
   *
   */
  async deleteById(id: string): Promise<void> {
    await this.items.delete({ id });
  }
}
