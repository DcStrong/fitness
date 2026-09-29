import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrainingPlanTagEntity } from '../entity/training-plan-tag.entity';

@Injectable()
export class TrainingPlanTagRepository {
  constructor(
    @InjectRepository(TrainingPlanTagEntity)
    private readonly planTags: Repository<TrainingPlanTagEntity>,
  ) {}

  /**
   *
   */
  async findByPlanId(planId: string): Promise<TrainingPlanTagEntity[]> {
    return this.planTags.find({
      where: { planId },
      relations: { tag: true },
    });
  }

  /**
   *
   */
  async findByPlanIds(planIds: string[]): Promise<TrainingPlanTagEntity[]> {
    if (planIds.length === 0) {
return Promise.resolve([]);
}

    return this.planTags
      .createQueryBuilder('pt')
      .leftJoinAndSelect('pt.tag', 'tag')
      .where('pt.plan_id IN (:...planIds)', { planIds })
      .getMany();
  }

  /**
   *
   */
  async findByTagId(tagId: string): Promise<TrainingPlanTagEntity[]> {
    return this.planTags.find({
      where: { tagId },
      relations: { plan: true, tag: true },
    });
  }

  /**
   *
   */
  async replaceForPlan(planId: string, tagIds: string[]): Promise<void> {
    await this.planTags.delete({ planId });
    if (tagIds.length === 0) {
return;
}
    const rows = tagIds.map(tagId =>
      this.planTags.create({ planId, tagId }));
    await this.planTags.save(rows);
  }
}
