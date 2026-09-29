## 1. Dependencies & config

- [x] 1.1 Add `@nestjs/typeorm`, `typeorm`, `pg`; wire `TypeOrmModule.forRootAsync` from env
- [x] 1.2 Set `synchronize: false`; document migrate/seed scripts in `package.json` + README
- [x] 1.3 Keep `.env` / `.env.example` compatible (`DATABASE_URL` + DB_* + JWT + ADMIN_*)

## 2. Entities & repositories

- [x] 2.1 Create TypeORM entities: User, Role, Permission, UserRole, RolePermission, RefreshToken
- [x] 2.2 Add repositories (or DataSource access) used by Auth; register `TypeOrmModule.forFeature`
- [x] 2.3 Align with platform patterns where practical (entity only in persistence layer)

## 3. Switch auth persistence

- [x] 3.1 Rewrite `AuthService` register/login/refresh/logout/profile to TypeORM (no Prisma calls)
- [x] 3.2 Remove `PrismaModule` / `PrismaService` from app wiring
- [x] 3.3 Ensure permission resolution still returns union of role permissions

## 4. Migrations & seed

- [x] 4.1 Add TypeORM DataSource CLI config and initial migration for auth schema (empty DB)
- [x] 4.2 Port seed (permissions, roles, optional admin) to TypeORM
- [x] 4.3 Run migrate + seed on the already-empty local database (no Prisma leftover cleanup needed)

## 5. Remove Prisma

- [x] 5.1 Delete `prisma/` schema, migrations, seed entirely
- [x] 5.2 Uninstall `prisma` / `@prisma/client`; remove prisma npm scripts
- [x] 5.3 Update `docs/architecture/stack.md` ORM line to TypeORM in use

## 6. Verification

- [x] 6.1 Fresh migrate + seed succeeds against local Postgres
- [x] 6.2 Existing auth e2e still pass (health, register/login/me/refresh/logout, admin reject)
- [x] 6.3 Manual smoke: register trainer + student flows
