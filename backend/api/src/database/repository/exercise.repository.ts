import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import type {
  CreateExerciseEntityParams,
  FindExerciseByOwnerAndNameParams,
} from '../../exercises/interface';
import { ExerciseEntity } from '../entity/exercise.entity';

@Injectable()
export class ExerciseRepository {
  constructor(
    @InjectRepository(ExerciseEntity)
    private readonly exercises: Repository<ExerciseEntity>,
  ) {}

  /**
   *
   */
  create(data: CreateExerciseEntityParams): ExerciseEntity {
    return this.exercises.create(data);
  }

  /**
   *
   */
  async save(entity: ExerciseEntity): Promise<ExerciseEntity> {
    return this.exercises.save(entity);
  }

  /**
   *
   */
  async findById(id: string): Promise<ExerciseEntity | null> {
    return this.exercises.findOne({ where: { id } });
  }

  /**
   *
   */
  async findByIds(ids: string[]): Promise<ExerciseEntity[]> {
    if (ids.length === 0) {
      return [];
    }

    return this.exercises.find({ where: { id: In(ids) } });
  }

  /**
   *
   */
  async findOwnAndCatalog(ownerCoachId: string): Promise<ExerciseEntity[]> {
    return this.exercises
      .createQueryBuilder('exercise')
      .where(
        'exercise.owner_coach_id = :ownerCoachId OR exercise.owner_coach_id IS NULL',
        { ownerCoachId },
      )
      .orderBy('exercise.name', 'ASC')
      .getMany();
  }

  /**
   *
   */
  async findByOwnerAndLowerName(
    params: FindExerciseByOwnerAndNameParams,
  ): Promise<ExerciseEntity | null> {
    const qb = this.exercises
      .createQueryBuilder('exercise')
      .where('LOWER(exercise.name) = LOWER(:name)', { name: params.name });
    if (params.ownerCoachId === null) {
      qb.andWhere('exercise.owner_coach_id IS NULL');
    } else {
      qb.andWhere('exercise.owner_coach_id = :ownerCoachId', {
        ownerCoachId: params.ownerCoachId,
      });
    }

    return qb.getOne();
  }

  /**
   *
   */
  async deleteById(id: string): Promise<void> {
    await this.exercises.delete({ id });
  }

  /**
   *
   */
  async upsertById(entity: Partial<ExerciseEntity> & { id: string }): Promise<void> {
    await this.exercises.upsert(entity, ['id']);
  }

  /**
   *
   */
  async findCatalog(): Promise<ExerciseEntity[]> {
    return this.exercises.find({
      where: { ownerCoachId: IsNull() },
      order: { name: 'ASC' },
    });
  }
}
