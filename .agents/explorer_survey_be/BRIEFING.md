# BRIEFING — 2026-08-31T19:57:00Z

## Mission
Comprehensive investigation and diagnostic of database schema, SQL migrations, RLS policies, indexes, and Dart query patterns in FishBit for performance optimization and reliability.

## 🔒 My Identity
- Archetype: Explorer
- Roles: Database Architecture, SQL Optimization, Supabase / PostgreSQL Specialist
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_be
- Original parent: e27bafd7-e85f-4b1c-9050-6519a2d76545
- Milestone: Database & Backend Optimization Diagnostic

## 🔒 Key Constraints
- Read-only investigation — do NOT modify source code or database schemas directly
- Synthesize all findings into a structured, evidence-based handoff report
- Check tables: parametros_calidad_agua, alimentacion_diaria, lotes, biometrias, mortalidad, traslados_lotes and related schemas
- Check composite indexes, RLS performance traps, and Dart repository query patterns

## Current Parent
- Conversation ID: e27bafd7-e85f-4b1c-9050-6519a2d76545
- Updated: 2026-08-31T19:57:00Z

## Investigation State
- **Explored paths**:
  - Live Supabase project `oakovawlwjpnoydpwtam` via MCP tools (`get_advisors`, `execute_sql`, `list_tables`, `list_projects`)
  - SQL migrations in `supabase/migrations/` and root `.sql` canonical schemas
  - Repositories in `lib/modules/*/infrastructure/repositories/`
  - Presentation providers in `lib/modules/*/presentation/providers/`
  - Official reports engine in `lib/core/reports/ica_official_reports_engine.dart`
- **Key findings**:
  - Identified multiple permissive RLS policies on 22 tables causing double evaluation on every SELECT.
  - Identified missing `(SELECT ...)` InitPlan wrappers in helper functions and RLS policies.
  - Identified missing functional index on `miembros_equipo(LOWER(email))` causing seq scans on auth checks.
  - Identified open multi-tenant vulnerability in `traslados_lotes` (`USING(true)`).
  - Identified missing composite indexes on `(empresa_id, estanque_id, fecha DESC)`, `(empresa_id, lote_id, fecha DESC)`, `(empresa_id, estado)`, etc.
  - Identified unindexed foreign keys across 10+ tables.
  - Identified 5 sequential async roundtrips in `PondsNotifier.loadPondsAndBatches()` that can be parallelized with `Future.wait()`.
  - Identified queries in Warehouse, Finance, Equipment, and Sales repositories missing `limit()` and explicit `empresa_id` filters.
- **Unexplored areas**: None, full audit completed.

## Key Decisions Made
- Structured the diagnostic report into `handoff.md` conforming to the 5-component protocol (Observation, Logic Chain, Caveats, Conclusion, Verification Method).
- Prepared an idempotent SQL migration script with composite index creation, foreign key indexing, RLS policy restructuring (splitting modify to INSERT/UPDATE/DELETE), and security definer view fixes.

## Artifact Index
- `.agents/explorer_survey_be/DISPATCH.md` — Task dispatch log
- `.agents/explorer_survey_be/BRIEFING.md` — Working memory and situational awareness
- `.agents/explorer_survey_be/progress.md` — Progress tracker
- `.agents/explorer_survey_be/handoff.md` — Authoritative database optimization & query analysis handoff report
