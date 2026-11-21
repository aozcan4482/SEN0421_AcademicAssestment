# Database

PostgreSQL schema of the Academic Assessment & Audit Management System.
The design is documented in `docs/sprint-1/WP-04_veritabani/`.

```
database/
  migrations/   Versioned schema changes, applied in file-name order
  seeds/        Reference data (criteria) and demo data for development
  scripts/      migrate.ps1 - the single entry point for schema changes
```

## Requirements

- PostgreSQL 14 or later (developed and tested on 17)
- `psql` available on `PATH` (Windows: `C:\Program Files\PostgreSQL\17\bin`)

## First-time setup

Run once as the `postgres` superuser. The application never connects as
superuser; it uses its own role that owns only this database
(ISO/IEC 27001:2022 – A 8.2).

```powershell
psql -U postgres -c "CREATE ROLE aams_app LOGIN PASSWORD '<choose-a-password>';"
psql -U postgres -c "CREATE DATABASE academic_assessment OWNER aams_app ENCODING 'UTF8';"
```

Then, from the repository root:

```powershell
.\database\scripts\migrate.ps1 -WithSeed
```

If PowerShell blocks the script, allow local scripts for the current session:
`Set-ExecutionPolicy -Scope Process Bypass`

## Daily use

- Pull the latest `main`, then run `.\database\scripts\migrate.ps1`.
  Only migrations that are not yet recorded in `schema_migrations` are applied.
- **Never edit a migration that is already on `main`.** To change the schema,
  add a new file with the next number, e.g. `002_add_audit_log.sql`.
- Seed files are idempotent and can be re-run at any time.

## Integrity rules enforced by the database

| Rule | Mechanism |
|---|---|
| Role is Admin, Jury or Student | `CHECK` on `users.role` |
| Only local Admin accounts store a password hash | `CHECK users_password_only_for_admin` |
| Score between 0 and 100 | `CHECK` on `evaluations.score` |
| Each jury scores each student once per criterion | `UNIQUE (jury_id, project_id, student_id, criteria_id)` |
| Only a jury member assigned to the project can score it | FK `evaluations_jury_assigned` → `jury_assignments` |
| Only a member of the project can be scored | FK `evaluations_student_is_member` → `project_members` |
| Criterion weight between 0 and 1 | `CHECK` on `criteria.weight` |
| Weights of all criteria sum to 1.0 | Deferred constraint trigger `trg_criteria_weight_total` (checked at `COMMIT`) |
| Deleting a project removes its members, assignments, evaluations and results | `ON DELETE CASCADE` |

## Reset (development only)

```powershell
psql -U postgres -c "DROP DATABASE academic_assessment;"
psql -U postgres -c "CREATE DATABASE academic_assessment OWNER aams_app ENCODING 'UTF8';"
.\database\scripts\migrate.ps1 -WithSeed
```
