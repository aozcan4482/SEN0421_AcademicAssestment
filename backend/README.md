# Backend (REST API)

Node.js / Express API of the Academic Assessment & Audit Management System.

## Structure

```
backend/
  src/
    server.js          Entry point: starts the HTTP server, graceful shutdown
    app.js             Builds the Express app (also used by tests)
    config/env.js      Reads and validates environment variables
    db/pool.js         PostgreSQL connection pool, query and transaction helpers
    routes/            URL -> controller mapping
    controllers/       HTTP layer: reads the request, sends the response
    repositories/      SQL only (parameterised queries)
    services/          Business rules (authentication, CATS client, audit)
    middleware/        Cross-cutting concerns: authentication, authorisation,
                       rate limiting, error handling
    utils/             Shared helpers (HttpError)
  scripts/             Maintenance commands (set-admin-password)
```

A request flows `route → controller → (service) → repository → database`.
Each layer has one responsibility, so new modules can be added as new files
without editing existing ones.

## Requirements

- Node.js 18 or later
- PostgreSQL with the schema applied (see `database/README.md`)

## Setup

```powershell
cd backend
npm install
copy .env.example .env      # then fill in DB_PASSWORD and JWT_SECRET
npm run dev                 # restarts automatically on file changes
```

`npm start` runs the server without auto-restart.

Generate a `JWT_SECRET`:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Set the administrator's local password (typed interactively, stored as a
bcrypt hash):

```powershell
npm run set-admin-password -- admin
```

## Authentication and authorisation

| Account       | Signs in with           | Notes                                                                                                                           |
| ------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Admin         | Local password (bcrypt) | Works even when CATS is unreachable                                                                                             |
| Jury, Student | CATS credentials        | CATS password is forwarded once, never stored or logged. The user must also be registered in the system, which assigns the role |

A successful login returns a signed JWT. Send it on every protected request:
`Authorization: Bearer <token>`.

- `requireRole(...)` restricts a route to the given roles.
- `requireJuryAssignment()` lets a jury member act only on projects assigned
  to them.
- Failed logins are rate-limited per IP address (default 10 per 15 minutes).
- Logins, failed logins and denied requests are written to the immutable
  audit log; evaluation changes are logged by a database trigger.

**Development without CATS accounts:** set `CATS_MODE=mock` and
`CATS_MOCK_PASSWORD` in `.env`; every registered jury/student account then
signs in with that password. The server refuses to start in mock mode when
`NODE_ENV=production`.

## Endpoints

| Method | Path                                                           | Access          | Description                                                            |
| ------ | -------------------------------------------------------------- | --------------- | ---------------------------------------------------------------------- |
| GET    | `/api/health`                                                  | Public          | `200` if the API and database are up, `503` if not                     |
| POST   | `/api/auth/login`                                              | Public          | `{ username, password }` → `{ token, user }`                           |
| GET    | `/api/auth/me`                                                 | Signed in       | Profile of the signed-in user                                          |
| GET    | `/api/criteria`                                                | Signed in       | Evaluation criteria and their weights                                  |
| GET    | `/api/jury/projects`                                           | Jury            | Projects assigned to the jury member, with member progress             |
| GET    | `/api/jury/projects/:projectId`                                | Jury (assigned) | Project, criteria and the jury member's own scores per student         |
| PUT    | `/api/jury/projects/:projectId/students/:studentId/evaluation` | Jury (assigned) | Save a student's scores as draft, or submit them with `"submit": true` |
| GET    | `/api/admin/audit-log`                                         | Admin           | Audit entries, newest first (`?limit=&before=`)                        |
| GET    | `/api/admin/audit-log/verify`                                  | Admin           | Recomputes the hash chain; `intact: false` reveals tampering           |

### Score entry

```json
PUT /api/jury/projects/1/students/4/evaluation
{
  "scores": [
    { "criteria_id": 1, "score": 85, "comment": "Solid architecture" },
    { "criteria_id": 2, "score": 90 }
  ],
  "submit": false
}
```

- Scores are whole numbers from 0 to 100; each student is scored individually.
- Drafts can be saved repeatedly. Submitting requires a score for every
  criterion; submitted scores are locked (`409 Conflict` on further changes).
- When a jury member has submitted every student, their assignment is marked
  completed; when all assigned jury members have completed, the project
  status becomes `Completed`.

Errors are always returned as `{ "error": "<message>" }`. Internal details
(SQL errors, stack traces) are logged on the server and never sent to the client.

## Quick check

```powershell
curl http://localhost:3000/api/health
```

## Scoring

A jury member's total for a student is the weighted sum of their criterion
scores (weights sum to 1.0, so totals are on the 0–100 scale). The final score
is the mean of the totals of all jury members who submitted a complete set,
rounded to two decimals. Drafts and incomplete sets are not counted. Results
can be calculated only after every assigned jury member has submitted.

## Code quality and tests

```powershell
npm run lint            # ESLint
npm run format:check    # Prettier (npm run format fixes formatting)
npm run test:unit       # unit tests, no database needed
npm test                # unit + integration tests (needs the database)
```

Integration tests run against the database configured in `.env`. They create
their own uniquely named users and project and remove them afterwards, so
they can be run repeatedly. CATS is always mocked during tests.

The same checks run automatically on GitHub Actions for every push and pull
request to `main` (`.github/workflows/ci.yml`), against a fresh PostgreSQL
database migrated with `database/scripts/migrate.ps1`.
