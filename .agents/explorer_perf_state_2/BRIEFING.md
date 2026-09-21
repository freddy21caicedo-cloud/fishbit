# BRIEFING — 2026-09-13T23:28:00Z

## Mission
Perform a rigorous, read-only audit of FishBit's Flutter state management (Riverpod/widgets), memory leaks/resource lifecycles, and Supabase/PostgreSQL query performance and indexing.

## 🔒 My Identity
- Archetype: explorer
- Roles: Performance, State Management & Database Audit Explorer
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_2
- Original parent: 8e16dd4a-70fc-4f0d-b4c7-04c36298c6bd
- Milestone: M3 (Performance, Leaks & DB)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement or modify application or database files.
- Strictly analytical and advisory.
- Provide file path, line numbers, impact, and concrete solution code snippets for every finding.
- Generate `perf_state_report.md` and `handoff.md` in `.agents\explorer_perf_state_2`.

## Current Parent
- Conversation ID: 8e16dd4a-70fc-4f0d-b4c7-04c36298c6bd
- Updated: not yet

## Investigation State
- **Explored paths**:
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart`
  - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`
  - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`
  - `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart`
  - `lib/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart`
  - `lib/core/reports/ica_official_reports_engine.dart`
  - `lib/app/router.dart`
  - `lib/app/main_navigation_shell.dart`
  - `lib/core/design_system/video_background_widget.dart`
  - `lib/core/design_system/glass_container.dart`
  - `lib/core/design_system/glass_card.dart`
  - `lib/modules/auth_tenant/presentation/screens/login_screen.dart`
  - `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart`
  - `lib/modules/auth_tenant/presentation/screens/onboarding_empresa_screen.dart`
  - `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`
  - `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart`
  - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart`
  - `lib/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart`
  - `lib/core/storage/offline_sync_queue.dart`
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql`
  - `supabase_schema_canonical_v10.sql`
- **Key findings**:
  - Identified 6 state management & rebuild hotspots (Bitacora monolithic over-watch, inline GDP calculations, ICA multi-provider cascade, Ponds ephemeral setState rebuilds, PondBentoCard double face build, GoRouter destructive re-instantiation).
  - Identified 5 memory leaks & resource lifecycle flaws (login controller leak, video controller async race, deactivated context access post-go, heavy UI thread Excel zip compression, BackdropFilter excessive GPU fill rate).
  - Identified 8 database & query bottlenecks (ponds screen-wiping reload cascade, unbounded batch/pond queries without limit, missing composite (empresa_id, fecha DESC) indexes, dual table sales writes, unindexed transfer pond lookups, disconnected dead offline queue, 3x sequential auth roundtrips, RLS OR-clause index degradation).
- **Unexplored areas**: None. All core screens, providers, repositories, and SQL schemas audited.

## Key Decisions Made
- Prioritized high-impact screens: PondsDashboardScreen, BitacoraScreen, IcaCertificationScreen, and critical DB tables: parametros_calidad_agua, alimentacion_diaria, lotes, biometrias, mortalidad, traslados_lotes.
- Formulate concrete, production-ready Dart and PostgreSQL code snippets for every finding.

## Artifact Index
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_2\perf_state_report.md` — Final audit report
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_2\handoff.md` — Handoff report

