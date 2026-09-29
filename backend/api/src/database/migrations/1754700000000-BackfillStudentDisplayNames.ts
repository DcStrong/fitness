import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Backfill user_profiles.display_name for students (and a few demo trainers)
 * so calendar/lists can show Имя Фамилия instead of email.
 */
export class BackfillStudentDisplayNames1754700000000
  implements MigrationInterface
{
  name = 'BackfillStudentDisplayNames1754700000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    // Explicit demo / known accounts.
    await queryRunner.query(`
      INSERT INTO "user_profiles" ("user_id", "display_name")
      SELECT u.id, v.display_name
      FROM "users" u
      INNER JOIN (
        VALUES
          ('olga.demo@mail.ru', 'Ольга Смирнова'),
          ('pavel.demo@mail.ru', 'Павел Иванов'),
          ('ilya.demo@mail.ru', 'Илья Козлов'),
          ('maria.demo@mail.ru', 'Мария Петрова'),
          ('anna.demo@mail.ru', 'Анна Волкова'),
          ('test2@mail.ru', 'Алексей Новиков'),
          ('wait.kirill@mail.ru', 'Кирилл Орлов'),
          ('wait.anna@mail.ru', 'Анна Морозова'),
          ('wait.dmitry@mail.ru', 'Дмитрий Соколов'),
          ('wait.lena@mail.ru', 'Елена Кузнецова'),
          ('wait.olga2@mail.ru', 'Ольга Лебедева'),
          ('test@mail.ru', 'Илья Тренер'),
          ('test1@mail.ru', 'Анна Тренер')
      ) AS v(email, display_name) ON lower(u.email) = lower(v.email)
      ON CONFLICT ("user_id") DO UPDATE
      SET "display_name" = EXCLUDED."display_name",
          "updated_at" = now()
      WHERE "user_profiles"."display_name" IS NULL
         OR btrim("user_profiles"."display_name") = ''
         OR "user_profiles"."display_name" LIKE '%(ожидание)'
    `);

    // Remaining students without a usable display_name get deterministic fake names.
    await queryRunner.query(`
      WITH students AS (
        SELECT
          u.id AS user_id,
          u.email,
          row_number() OVER (ORDER BY u.created_at, u.email) AS rn
        FROM "users" u
        INNER JOIN "user_roles" ur ON ur.user_id = u.id
        INNER JOIN "roles" r ON r.id = ur.role_id AND r.slug = 'student'
        LEFT JOIN "user_profiles" p ON p.user_id = u.id
        WHERE p.user_id IS NULL
           OR p.display_name IS NULL
           OR btrim(p.display_name) = ''
      ),
      named AS (
        SELECT
          s.user_id,
          (
            ARRAY[
              'Артём', 'Борис', 'Виктор', 'Глеб', 'Денис',
              'Егор', 'Жанна', 'Зоя', 'Ирина', 'Кира',
              'Лев', 'Мила', 'Никита', 'Оксана', 'Пётр',
              'Роман', 'Света', 'Тарас', 'Ульяна', 'Фёдор'
            ]
          )[((s.rn - 1) % 20) + 1]
          || ' ' ||
          (
            ARRAY[
              'Белов', 'Громов', 'Ершов', 'Жуков', 'Зайцев',
              'Климов', 'Лапин', 'Малов', 'Никитин', 'Осипов',
              'Панов', 'Родин', 'Савин', 'Титов', 'Усов',
              'Фомин', 'Харитонов', 'Цветков', 'Чернов', 'Шилов'
            ]
          )[((s.rn - 1) % 20) + 1]
          AS display_name
        FROM students s
      )
      INSERT INTO "user_profiles" ("user_id", "display_name")
      SELECT user_id, display_name FROM named
      ON CONFLICT ("user_id") DO UPDATE
      SET "display_name" = EXCLUDED."display_name",
          "updated_at" = now()
      WHERE "user_profiles"."display_name" IS NULL
         OR btrim("user_profiles"."display_name") = ''
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    // Keep profiles; only clear names that look like migration fakes is unsafe.
    // No-op reverse: display names are user-facing data once written.
    await queryRunner.query(`SELECT 1`);
  }
}
