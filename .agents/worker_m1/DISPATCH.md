## 2026-08-31T19:58:00Z
You are a Worker subagent assigned to implement Milestone 1: Database & SQL Optimization, RLS InitPlan & Dart Repositories for FishBit.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1

The authoritative request is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\ORIGINAL_REQUEST.md
The project master plan is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\PROJECT.md
The detailed diagnostic report is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_be\handoff.md

Scope & Tasks:
1. Read ORIGINAL_REQUEST.md, PROJECT.md, and .agents/explorer_survey_be/handoff.md.
2. Create the complete SQL migration file at `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\supabase\migrations\20260831_database_performance_and_rls_optimization.sql` with:
   - Functional index `idx_miembros_lower_email` on `miembros_equipo(LOWER(email))`.
   - Optimized `get_auth_empresa_id()`, `get_auth_user_role()`, `is_superadmin()` functions with `STABLE SECURITY DEFINER` and explicit `SET search_path TO 'public'`.
   - Composite indexes:
     * `parametros_calidad_agua(empresa_id, estanque_id, fecha DESC)`
     * `parametros_calidad_agua(empresa_id, unidad_acuicola_id, fecha DESC)`
     * `alimentacion_diaria(empresa_id, lote_id, fecha DESC)`
     * `alimentacion_diaria(empresa_id, estanque_id, fecha DESC)`
     * `lotes(empresa_id, estado)`
     * `lotes(empresa_id, creado_en DESC)`
     * `biometrias(empresa_id, lote_id, date DESC)`
     * `biometrias(empresa_id, lote_id, fecha DESC)`
     * `mortalidad(empresa_id, lote_id, date DESC)`
     * `mortalidad(empresa_id, estanque_id, date DESC)`
     * `traslados_lotes(empresa_id, lote_origen_id, fecha_operacion DESC)`
     * `traslados_lotes(empresa_id, lote_destino_id, fecha_operacion DESC)`
     * 15+ FK covering indexes for `unidad_acuicola_id`, `lote_id`, `cliente_id`, etc.
   - Refactored RLS policies on all 22 tables: split `_tenant_modify` into separate `FOR INSERT`, `FOR UPDATE`, `FOR DELETE` policies with `(SELECT public.get_auth_empresa_id())` to eliminate multiple permissive policy warnings and enable single InitPlan evaluation.
   - Strict RLS on `traslados_lotes` (replacing `USING (true)` with tenant matching), `bioseguridad_*`, `sanidad_*`, `compras_mat_biologico`, `equipos`, `mantenimientos`, `recibos_energia`.
3. Apply the SQL migration to the Supabase database using MCP `call_mcp_tool(ServerName="supabase", ToolName="execute_sql", Arguments={"query": ...})`. Verify execution and verify with `get_advisors`.
4. Refactor Dart repositories in `lib/modules/`:
   - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`
   - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart`
   - `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart`
   - `lib/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart`
   - `lib/modules/equipment_capex/infrastructure/repositories/supabase_equipment_repository.dart`
   Ensure queries use explicit `.eq('empresa_id', empresaId)`, bounded `.limit(100)` (or appropriate pagination/time bounds), and concurrent async operations where applicable.
5. Run tests via `run_command` (`flutter test`) and static analysis (`flutter analyze --no-fatal-infos`).
6. Write a comprehensive completion and handoff report in `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1\handoff.md`.
7. Send a message to the orchestrator with your results.
