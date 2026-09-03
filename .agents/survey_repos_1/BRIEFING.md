# BRIEFING — 2026-08-28T23:10:20Z

## Mission
Investigate the data layer, repositories, services, and models supporting the Bitácora module (water quality, nutrition, biometrics, mortality), identify schema/model discrepancies, double-writes, hardcoded UUIDs, and missing repository methods.

## 🔒 My Identity
- Archetype: explorer
- Roles: Codebase & Repository Explorer
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_repos_1
- Original parent: 8d9d3925-2638-4c57-8043-da837c0e440b
- Milestone: Bitácora technical audit & repository survey

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Keep all notes, analysis, and handoff files within .agents/survey_repos_1/
- Produce complete evidence chains (file paths, line numbers, exact code snippets)

## Current Parent
- Conversation ID: 8d9d3925-2638-4c57-8043-da837c0e440b
- Updated: 2026-08-28T23:10:20Z

## Investigation State
- **Explored paths**:
  - `lib/modules/water_quality/` (models, repositories, providers, dialogs, screens)
  - `lib/modules/ponds_batches/` (models, repositories, providers, dialogs, screens)
  - `lib/modules/feeding_nutrition/` (models, repositories, providers)
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`
  - `lib/modules/auth_tenant/` (repositories, providers)
  - `lib/modules/sales_harvest/`, `lib/modules/warehouse_inventory/`, `lib/modules/finance_payroll/`, `lib/modules/equipment_capex/`
  - Supabase database schema via `execute_sql` & `list_tables`
  - Canonical SQL files: `supabase_schema_canonical_v10.sql`, `supabase_migration_v10_canonical_v2.sql`, `supabase_data_sync_legacy_to_v2.sql`
- **Key findings**:
  - `recordParameters()` double writes to `parametros_calidad_agua` and legacy `water_quality`. `empresa_id` is omitted in primary insert.
  - `fetchRecentParametersByUnit()` queries `water_quality` first, uses in-memory hardcoded UUID filtering, falls back to `parametros_calidad_agua`, and falls back to `_demoParameters`.
  - `parametros_calidad_agua` has RLS enabled with 0 policies, blocking all client access.
  - Hardcoded UUIDs (`3500cc63-5477-4f83-b4a3-7758b7cd6509`, `54dedaac-9099-475a-8bfc-635ef8494c2a`) identified in 8 repositories.
  - No read methods exist for biometrics and mortality; UI displays batch summaries rather than historical event records.
  - `alimentacion_diaria` insert tries to write non-existent columns (`unidad_acuicola_id`, `insumo_id`).
- **Unexplored areas**: None within the scope of Bitácora data layer survey.

## Key Decisions Made
- Fully documented all 5 survey objectives with line numbers and database schema evidence in `analysis.md` and `handoff.md`.

## Artifact Index
- `.agents/survey_repos_1/DISPATCH.md` — Initial user request / dispatch log
- `.agents/survey_repos_1/BRIEFING.md` — Agent briefing and persistent working memory
- `.agents/survey_repos_1/progress.md` — Liveness heartbeat and progress tracking
- `.agents/survey_repos_1/analysis.md` — Comprehensive technical analysis report
- `.agents/survey_repos_1/handoff.md` — Structured 5-component handoff report
