# Progress Log — explorer_perf_state_1

**Last visited**: 2026-09-12T23:17:00Z
**Current Status**: Starting investigation

## Tasks
- [x] Step 1: Record dispatch and initialize BRIEFING.md & progress.md
- [ ] Step 2: Investigate State Management & Widget Tree Rebuilding
  - [ ] Inspect PondsDashboardScreen, BitacoraScreen, IcaCertificationScreen
  - [ ] Audit `ref.watch` vs `select` in screens and providers
  - [ ] Check for missing `const` constructors causing element rebuilds
  - [ ] Audit build method side-effects (async calls/mutations in `build()`)
- [ ] Step 3: Investigate Memory Leaks & Resource Lifecycle
  - [ ] Supabase realtime subscriptions & sensor subscriptions uncancelled
  - [ ] Undisposed controllers: TextEditingController, AnimationController, ScrollController, FocusNode, Timer
  - [ ] Context across async gaps without mounted checks
- [ ] Step 4: Investigate Database & Query Performance
  - [ ] Unbounded queries (lack of `.limit()` / pagination)
  - [ ] Missing PostgreSQL composite indexes / unindexed foreign keys (parametros_calidad_agua, alimentacion_diaria, lotes, biometrias, mortalidad, traslados_lotes)
  - [ ] N+1 query patterns, redundant fetches, lack of caching / offline resilience
- [ ] Step 5: Synthesize findings and write `perf_state_report.md`
- [ ] Step 6: Write `handoff.md` and notify parent orchestrator via `send_message`
