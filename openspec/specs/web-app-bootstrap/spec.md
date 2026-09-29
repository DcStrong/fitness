# web-app-bootstrap Specification

## Purpose
Next.js TypeScript application bootstrap under `web_app/`, with configurable API URL and documented local startup.

## Requirements

### Requirement: Web app lives under web_app with Next.js
The repository SHALL contain a Next.js TypeScript application rooted at `web_app/` (sibling of `app/` and `backend/`). Developers MUST be able to start it in local mode against a configurable API base URL.

#### Scenario: Project scaffold exists
- **WHEN** the change is implemented
- **THEN** `web_app/package.json` exists and a documented `dev` script starts the Next.js app

#### Scenario: API base URL is configurable
- **WHEN** `NEXT_PUBLIC_API_BASE_URL` (or equivalent) points at the local Nest API
- **THEN** the web client sends HTTP requests to that base URL

### Requirement: README documents how to run web_app
The project documentation SHALL briefly explain how to install and run `web_app` alongside the API.

#### Scenario: Developer finds run steps
- **WHEN** a developer opens `web_app/README.md` or the root README web section
- **THEN** they can find install + `dev` + required env for API URL
