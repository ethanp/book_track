# book_track database

Source of truth for the book_track Postgres schema and PowerSync sync rules.

| Path | Purpose |
|---|---|
| `init.sql` | Full current schema (fresh DB bootstrap) |
| `migrations/` | Incremental numbered SQL migrations |
| `powersync.yaml` | PowerSync service config + sync rules |
| `bootstrap.sql` | Role setup (`book_track` login + replication) |
| `infra.yaml` | Compose ports (PowerSync 8087, PostgREST 3010) |

## Migrations

From this app repo:

```bash
./scripts/migrate.sh migrations/001_initial.sql
./scripts/migrate.sh --full migrations/001_initial.sql
```
