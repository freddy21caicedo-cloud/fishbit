## 2026-08-29T04:12:03Z
You are the Database Migration Worker for Milestone 1 (M1).
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1_1
Workspace root: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Supabase Project ID: oakovawlwjpnoydpwtam

Milestone 1 Scope & Objectives:
Apply idempotent SQL migrations to Supabase project oakovawlwjpnoydpwtam using Supabase MCP tools (execute_sql or apply_migration) or standard SQL scripts:
1. `parametros_calidad_agua`
2. `alimentacion_diaria`
3. `biometrias`
4. `mortalidad`
5. Deprecate / handle legacy table `calidad_agua` safely and idempotently.
6. Verify migration idempotency: ensure running the migration twice succeeds cleanly.
7. Also create or update a migration SQL file in the codebase (e.g., `supabase/migrations/` or relevant directory) so migrations are tracked in version control.
