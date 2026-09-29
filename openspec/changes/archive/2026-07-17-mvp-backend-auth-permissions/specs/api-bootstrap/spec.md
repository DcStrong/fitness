## ADDED Requirements

### Requirement: API process starts with health check
The system SHALL expose a health endpoint that confirms the API process is running.

#### Scenario: Health check succeeds
- **WHEN** a client sends `GET /health`
- **THEN** the API responds with HTTP 200 and a JSON body indicating status `ok`

### Requirement: Local PostgreSQL is available via Compose
The system SHALL provide a Docker Compose PostgreSQL service suitable for local development of the API.

#### Scenario: Developer starts database
- **WHEN** a developer runs the documented Compose command for the database
- **THEN** PostgreSQL becomes reachable for the API using documented connection settings

### Requirement: Schema migrations apply cleanly
The system SHALL manage the database schema through Prisma migrations that apply to a fresh database without manual SQL.

#### Scenario: Fresh database migrate
- **WHEN** migrations are applied against an empty PostgreSQL instance
- **THEN** the required tables for auth and access-control exist and the API can start successfully
