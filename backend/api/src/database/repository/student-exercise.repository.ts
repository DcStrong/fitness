import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import type { CreateStudentExerciseParams } from '../../exercises/interface';
import { StudentExerciseEntity } from '../entity/student-exercise.entity';

@Injectable()
export class StudentExerciseRepository {
  constructor(
    @InjectRepository(StudentExerciseEntity)
    private readonly studentExercises: Repository<StudentExerciseEntity>,
  ) {}

  /**
   *
   */
  create(data: CreateStudentExerciseParams): StudentExerciseEntity {
    return this.studentExercises.create(data);
  }

  /**
   *
   */
  async save(entity: StudentExerciseEntity): Promise<StudentExerciseEntity> {
    return this.studentExercises.save(entity);
  }

  /**
   *
   */
  async findPair(
    coachId: string,
    studentId: string,
    exerciseId: string,
  ): Promise<StudentExerciseEntity | null> {
    return this.studentExercises.findOne({
      where: { coachId, studentId, exerciseId },
    });
  }

  /**
   *
   */
  async findAssignedExerciseIdsForStudent(
    studentId: string,
  ): Promise<string[]> {
    const rows = await this.studentExercises
      .createQueryBuilder('se')
      .innerJoin(
        'coach_student_links',
        'link',
        'link.coach_id = se.coach_id AND link.student_id = se.student_id',
      )
      .where('se.student_id = :studentId', { studentId })
      .select('DISTINCT se.exercise_id', 'exerciseId')
      .getRawMany<{ exerciseId: string }>();

    return rows.map(row => row.exerciseId);
  }

  /**
   *
   */
  async deletePair(
    coachId: string,
    studentId: string,
    exerciseId: string,
  ): Promise<void> {
    await this.studentExercises.delete({ coachId, studentId, exerciseId });
  }
}
