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
    middleware/        Cross-cutting concerns (errors; later auth, RBAC)
    utils/             Shared helpers (HttpError)
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
copy .env.example .env      # then set DB_PASSWORD in .env
npm run dev                 # restarts automatically on file changes
```

`npm start` runs the server without auto-restart.

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/health` | `200` if the API and database are up, `503` if the database is unreachable |
| GET | `/api/criteria` | Evaluation criteria and their weights |

Errors are always returned as `{ "error": "<message>" }`. Internal details
(SQL errors, stack traces) are logged on the server and never sent to the client.

## Quick check

```powershell
curl http://localhost:3000/api/health
curl http://localhost:3000/api/criteria
```
