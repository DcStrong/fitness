import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import type { DataSource } from 'typeorm';
import { ExerciseEntity } from './entity/exercise.entity';
import { PlanExerciseEntity } from './entity/plan-exercise.entity';
import { PlanSetEntity } from './entity/plan-set.entity';
import { TrainingPlanEntity } from './entity/training-plan.entity';
import { UserEntity } from './entity/user.entity';
import type { ExerciseKind } from '../exercises/interface';
import type { PlanGoal } from '../plans/interface';

export const CATALOG_OWNER_USER_ID = 'a0000000-0000-4000-8000-000000000001';
export const CATALOG_OWNER_EMAIL = 'catalog@internal.fitness-yoda';

const EX = {
  bench: 'e0000000-0000-4000-8000-000000000001',
  squat: 'e0000000-0000-4000-8000-000000000002',
  deadlift: 'e0000000-0000-4000-8000-000000000003',
  latPulldown: 'e0000000-0000-4000-8000-000000000004',
  dbPress: 'e0000000-0000-4000-8000-000000000005',
  rdl: 'e0000000-0000-4000-8000-000000000006',
  lunges: 'e0000000-0000-4000-8000-000000000007',
  bentOverRow: 'e0000000-0000-4000-8000-000000000008',
  legPress: 'e0000000-0000-4000-8000-000000000009',
  curl: 'e0000000-0000-4000-8000-000000000010',
  pushUps: 'e0000000-0000-4000-8000-000000000011',
  pullUps: 'e0000000-0000-4000-8000-000000000012',
  crunches: 'e0000000-0000-4000-8000-000000000013',
  plank: 'e0000000-0000-4000-8000-000000000014',
  dips: 'e0000000-0000-4000-8000-000000000015',
  hyperextension: 'e0000000-0000-4000-8000-000000000016',
  legExtension: 'e0000000-0000-4000-8000-000000000017',
  hangingLegRaise: 'e0000000-0000-4000-8000-000000000018',
} as const;

const CATALOG_EXERCISES: Array<{
  id: string;
  name: string;
  kind: ExerciseKind;
}> = [
  { id: EX.bench, name: 'Жим штанги лёжа', kind: 'weight_reps' },
  { id: EX.squat, name: 'Приседания со штангой', kind: 'weight_reps' },
  { id: EX.deadlift, name: 'Становая тяга', kind: 'weight_reps' },
  { id: EX.latPulldown, name: 'Тяга верхнего блока', kind: 'weight_reps' },
  { id: EX.dbPress, name: 'Жим гантелей сидя', kind: 'weight_reps' },
  { id: EX.rdl, name: 'Румынская тяга', kind: 'weight_reps' },
  { id: EX.lunges, name: 'Выпады с гантелями', kind: 'weight_reps' },
  { id: EX.bentOverRow, name: 'Тяга штанги в наклоне', kind: 'weight_reps' },
  { id: EX.legPress, name: 'Жим ногами', kind: 'weight_reps' },
  { id: EX.curl, name: 'Подъём на бицепс', kind: 'weight_reps' },
  { id: EX.pushUps, name: 'Отжимания', kind: 'bodyweight_reps' },
  { id: EX.pullUps, name: 'Подтягивания', kind: 'bodyweight_reps' },
  { id: EX.crunches, name: 'Скручивания', kind: 'bodyweight_reps' },
  { id: EX.plank, name: 'Планка', kind: 'duration' },
  { id: EX.dips, name: 'Отжимания на брусьях', kind: 'bodyweight_reps' },
  { id: EX.hyperextension, name: 'Гиперэкстензия', kind: 'weight_reps' },
  { id: EX.legExtension, name: 'Разгибание ног', kind: 'weight_reps' },
  { id: EX.hangingLegRaise, name: 'Подъём ног в висе', kind: 'bodyweight_reps' },
];

type SeedSet = {
  reps: number | null;
  weightKg: number | null;
  durationSeconds: number | null;
};

type SeedPlanExercise = {
  exerciseId: string;
  restSeconds: number;
  sets: SeedSet[];
};

type SeedPlan = {
  id: string;
  title: string;
  goal: PlanGoal;
  notes: string;
  exercises: SeedPlanExercise[];
};

/**
 *
 */
function identicalSets(
  count: number,
  set: SeedSet,
): SeedSet[] {
  return Array.from({ length: count }, () => ({ ...set }));
}

const HYP = { reps: 10, weightKg: null, durationSeconds: null };
const FAT = { reps: 15, weightKg: null, durationSeconds: null };
const GEN = { reps: 12, weightKg: null, durationSeconds: null };
const PLANK = { reps: null, weightKg: null, durationSeconds: 45 };

const CATALOG_PLANS: SeedPlan[] = [
  {
    id: 'b0000000-0000-4000-8000-000000000001',
    title: 'Верх тела — набор',
    goal: 'hypertrophy',
    notes: 'Жим и тяги на гипертрофию верха.',
    exercises: [
      { exerciseId: EX.bench, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.latPulldown, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.dbPress, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.bentOverRow, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.curl, restSeconds: 90, sets: identicalSets(3, HYP) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000002',
    title: 'Верх тела — похудение',
    goal: 'fat_loss',
    notes: 'Короткие паузы, больше повторов.',
    exercises: [
      { exerciseId: EX.pushUps, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.latPulldown, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.crunches, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.pullUps, restSeconds: 45, sets: identicalSets(3, FAT) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000003',
    title: 'Низ тела — набор',
    goal: 'hypertrophy',
    notes: 'База на ноги и ягодицы.',
    exercises: [
      { exerciseId: EX.squat, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.rdl, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.legPress, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.lunges, restSeconds: 90, sets: identicalSets(3, HYP) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000004',
    title: 'Низ тела — похудение',
    goal: 'fat_loss',
    notes: 'Объём на низ тела.',
    exercises: [
      { exerciseId: EX.squat, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.lunges, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.legExtension, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.hyperextension, restSeconds: 45, sets: identicalSets(3, FAT) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000005',
    title: 'Фулбоди — набор',
    goal: 'hypertrophy',
    notes: 'Базовые движения на всё тело.',
    exercises: [
      { exerciseId: EX.squat, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.bench, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.bentOverRow, restSeconds: 90, sets: identicalSets(3, HYP) },
      { exerciseId: EX.deadlift, restSeconds: 90, sets: identicalSets(3, HYP) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000006',
    title: 'Фулбоди — похудение',
    goal: 'fat_loss',
    notes: 'Круговой объём на всё тело.',
    exercises: [
      { exerciseId: EX.squat, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.pushUps, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.lunges, restSeconds: 45, sets: identicalSets(3, FAT) },
      { exerciseId: EX.dips, restSeconds: 45, sets: identicalSets(3, FAT) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000007',
    title: 'Верх тела — общее',
    goal: 'general',
    notes: 'Универсальный верх без акцента на цель.',
    exercises: [
      { exerciseId: EX.bench, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.latPulldown, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.pushUps, restSeconds: 60, sets: identicalSets(3, GEN) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000008',
    title: 'Низ тела — общее',
    goal: 'general',
    notes: 'Универсальный низ.',
    exercises: [
      { exerciseId: EX.squat, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.rdl, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.lunges, restSeconds: 60, sets: identicalSets(3, GEN) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-000000000009',
    title: 'Фулбоди — общее',
    goal: 'general',
    notes: 'Смешанный состав на всё тело.',
    exercises: [
      { exerciseId: EX.squat, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.bench, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.latPulldown, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.plank, restSeconds: 60, sets: identicalSets(3, PLANK) },
    ],
  },
  {
    id: 'b0000000-0000-4000-8000-00000000000a',
    title: 'Круговая — общее',
    goal: 'general',
    notes: 'Короткая круговая без гендерных форков.',
    exercises: [
      { exerciseId: EX.dips, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.pushUps, restSeconds: 60, sets: identicalSets(3, GEN) },
      { exerciseId: EX.plank, restSeconds: 60, sets: identicalSets(3, PLANK) },
      { exerciseId: EX.hangingLegRaise, restSeconds: 60, sets: identicalSets(3, GEN) },
    ],
  },
];

/**
 * Идемпотентный upsert каталога упражнений и шаблонов.
 */
export async function seedCatalogWorkouts(dataSource: DataSource): Promise<void> {
  const users = dataSource.getRepository(UserEntity);
  let owner = await users.findOne({ where: { id: CATALOG_OWNER_USER_ID } });
  if (!owner) {
    owner = await users.findOne({ where: { email: CATALOG_OWNER_EMAIL } });
  }
  if (!owner) {
    const passwordHash = await bcrypt.hash(randomBytes(24).toString('hex'), 10);
    owner = await users.save(
      users.create({
        id: CATALOG_OWNER_USER_ID,
        email: CATALOG_OWNER_EMAIL,
        passwordHash,
      }),
    );
  }

  const exercises = dataSource.getRepository(ExerciseEntity);
  for (const item of CATALOG_EXERCISES) {
    const existing = await exercises.findOne({ where: { id: item.id } });
    if (existing) {
      existing.name = item.name;
      existing.kind = item.kind;
      existing.ownerCoachId = null;
      await exercises.save(existing);
    } else {
      await exercises.save(
        exercises.create({
          id: item.id,
          name: item.name,
          kind: item.kind,
          ownerCoachId: null,
        }),
      );
    }
  }

  const plans = dataSource.getRepository(TrainingPlanEntity);
  const planExercises = dataSource.getRepository(PlanExerciseEntity);
  for (const plan of CATALOG_PLANS) {
    const existing = await plans.findOne({ where: { id: plan.id } });
    if (existing) {
      existing.title = plan.title;
      existing.body = plan.notes;
      existing.kind = 'catalog_seed';
      existing.goal = plan.goal;
      existing.ownerCoachId = owner.id;
      existing.parentTemplateId = null;
      existing.assignedStudentId = null;
      await plans.save(existing);
    } else {
      await plans.save(
        plans.create({
          id: plan.id,
          ownerCoachId: owner.id,
          title: plan.title,
          body: plan.notes,
          kind: 'catalog_seed',
          goal: plan.goal,
          parentTemplateId: null,
          assignedStudentId: null,
        }),
      );
    }
    await planExercises.delete({ planId: plan.id });
    for (const [index, row] of plan.exercises.entries()) {
      const saved = await planExercises.save(
        planExercises.create({
          planId: plan.id,
          exerciseId: row.exerciseId,
          sortOrder: index,
          restSeconds: row.restSeconds,
          notes: '',
        }),
      );
      await dataSource.getRepository(PlanSetEntity).save(
        row.sets.map((set, setIndex) =>
          dataSource.getRepository(PlanSetEntity).create({
            planExerciseId: saved.id,
            sortOrder: setIndex,
            reps: set.reps,
            weightKg: set.weightKg === null ? null : set.weightKg.toFixed(2),
            durationSeconds: set.durationSeconds,
          })),
      );
    }
  }
}
