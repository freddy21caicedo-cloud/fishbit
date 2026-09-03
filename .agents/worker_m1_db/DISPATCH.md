## 2026-08-31T19:40:57-05:00
You are the Database & Backend Specialist Worker for Milestone 1: PostgreSQL & Supabase Database Optimization.

Your working directory is:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1_db

Read the authoritative documents first:
1. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
2. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_be\handoff.md
3. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\PROJECT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Tasks:
1. Create the migration file at `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` with the complete SQL script detailed in `explorer_survey_be/handoff.md § 4.1` (including functional index `LOWER(email)` on `miembros_equipo`, STABLE helper functions, composite indexes, foreign key indexes, RLS split policies with InitPlan caching `(SELECT public.get_auth_empresa_id())`, multi-tenant security fixes on `traslados_lotes` and unshielded tables, and `v_estanques_inconsistencias` security invoker view).
2. Apply/execute this migration on the live Supabase project `oakovawlwjpnoydpwtam` using the Supabase MCP tool (`execute_sql` or `apply_migration`).
3. Query Supabase advisors (`get_advisors` for type 'performance' and 'security') and verify the reduction of RLS, initplan, and security issues.
4. Update the Dart repositories with explicit tenant filtering and `.limit(100)`:
   - `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart`
   - `lib/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart`
   - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart`
   - `lib/modules/equipment_capex/infrastructure/repositories/supabase_equipment_repository.dart`
5. Run `flutter test` via `run_command` to ensure all existing repository and model unit tests pass cleanly.
6. Write a comprehensive `handoff.md` in `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1_db\handoff.md` detailing all changes made, SQL execution outputs, Supabase advisor results, and test verification logs. Send a completion message when finished.
