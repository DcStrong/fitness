# persistence-typeorm Specification

## Purpose
TBD - created by archiving change migrate-prisma-to-typeorm. Update Purpose after archive.
## Requirements
### Requirement: Application persists data via TypeORM
The system SHALL use TypeORM with PostgreSQL as the sole persistence layer for the API. Prisma SHALL NOT remain as a runtime dependency after this change.

#### Scenario: API starts with TypeORM
- **WHEN** the API starts with a valid `DATABASE_URL` (or equivalent DB env vars)
- **THEN** TypeORM connects successfully and the application boots without Prisma client initialization

### Requirement: Schema is managed by TypeORM migrations
The system SHALL manage database schema through TypeORM migrations that can be applied to a fresh PostgreSQL database.

#### Scenario: Fresh database migrate
- **WHEN** TypeORM migrations are run against an empty database
- **THEN** tables for users, roles, permissions, join tables, and refresh tokens exist

### Requirement: Seed recreates baseline access data
The system SHALL provide a seed that creates permissions `users:read_self` and `admin:access`, roles `trainer` / `student` / `admin` with their permission bundles, and optionally an admin user from env.

#### Scenario: Seed on empty roles table
- **WHEN** seed runs after migrations
- **THEN** the three roles and baseline permissions exist and can be used by registration/login

