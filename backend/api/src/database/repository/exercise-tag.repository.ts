import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { ExerciseTagEntity } from '../entity/exercise-tag.entity';

@Injectable()
export class ExerciseTagRepository {
  constructor(
    @InjectRepository(ExerciseTagEntity)
    private readonly exerciseTags: Repository<ExerciseTagEntity>,
  ) {}

  /**
   *
   */
  async findByExerciseIds(
    exerciseIds: string[],
  ): Promise<ExerciseTagEntity[]> {
    if (exerciseIds.length === 0) {
      return [];
    }

    return this.exerciseTags
      .createQueryBuilder('et')
      .leftJoinAndSelect('et.tag', 'tag')
      .where('et.exercise_id IN (:...exerciseIds)', { exerciseIds })
      .getMany();
  }

  /**
   *
   */
  async findByTagId(tagId: string): Promise<ExerciseTagEntity[]> {
    return this.exerciseTags.find({
      where: { tagId },
      relations: { exercise: true, tag: true },
    });
  }

  /**
   * Visible exercise ids: shared tag with a linked coach.
   */
  async findVisibleExerciseIdsForStudent(
    studentId: string,
  ): Promise<string[]> {
    const rows = await this.exerciseTags
      .createQueryBuilder('et')
      .innerJoin('tags', 'tag', 'tag.id = et.tag_id')
      .innerJoin(
        'user_tags',
        'ut',
        'ut.tag_id = et.tag_id AND ut.user_id = :studentId',
        { studentId },
      )
      .innerJoin(
        'coach_student_links',
        'link',
        'link.coach_id = tag.creator_id AND link.student_id = :studentId',
        { studentId },
      )
      .select('DISTINCT et.exercise_id', 'exerciseId')
      .getRawMany<{ exerciseId: string }>();

    return rows.map(row => row.exerciseId);
  }

  /**
   * Replaces only tags created by this trainer on the exercise.
   */
  async replaceForTrainer(
    exerciseId: string,
    trainerId: string,
    tagIds: string[],
  ): Promise<void> {
    await this.exerciseTags
      .createQueryBuilder()
      .delete()
      .from(ExerciseTagEntity)
      .where(
        `exercise_id = :exerciseId AND tag_id IN (
          SELECT id FROM tags WHERE creator_id = :trainerId
        )`,
        { exerciseId, trainerId },
      )
      .execute();
    if (tagIds.length === 0) {
      return;
    }
    const unique = [...new Set(tagIds)];
    const rows = unique.map(tagId =>
      this.exerciseTags.create({ exerciseId, tagId }),
    );
    await this.exerciseTags.save(rows);
  }

  /**
   *
   */
  async findByExerciseIdsForCreator(
    exerciseIds: string[],
    creatorId: string,
  ): Promise<ExerciseTagEntity[]> {
    if (exerciseIds.length === 0) {
      return [];
    }

    return this.exerciseTags
      .createQueryBuilder('et')
      .leftJoinAndSelect('et.tag', 'tag')
      .where('et.exercise_id IN (:...exerciseIds)', { exerciseIds })
      .andWhere('tag.creator_id = :creatorId', { creatorId })
      .getMany();
  }

  /**
   *
   */
  async findExerciseIdsByTagId(tagId: string): Promise<string[]> {
    const rows = await this.exerciseTags.find({
      where: { tagId },
      select: { exerciseId: true },
    });

    return [...new Set(rows.map(row => row.exerciseId))];
  }

  /**
   *
   */
  async findByExerciseIdAndTagIds(
    exerciseId: string,
    tagIds: string[],
  ): Promise<ExerciseTagEntity[]> {
    if (tagIds.length === 0) {
      return [];
    }

    return this.exerciseTags.find({
      where: { exerciseId, tagId: In(tagIds) },
    });
  }
}
