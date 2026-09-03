# Project Progress

## Current Status
Last visited: 2026-08-31T19:50:05-05:00

## Iteration Status
Current iteration: 1 / 32

## Milestones Summary
- [ ] **Milestone 1: PostgreSQL & Supabase Database Optimization**
  - [x] Apply SQL migration `20260831_database_performance_and_rls_optimization.sql` to Supabase & disk
  - [x] Add composite indexes and FK indexes
  - [x] Refactor RLS policies to use InitPlan subqueries `(SELECT get_auth_empresa_id())`
  - [x] Secure unshielded tables & set views to `SECURITY INVOKER`
  - [x] Update Dart data access layer repositories (`supabase_warehouse_repository.dart`, `supabase_finance_repository.dart`, `supabase_sales_repository.dart`, `supabase_equipment_repository.dart`) with explicit tenant filters and limits
  - [ ] Running flutter tests & completing worker handoff (in-progress)
- [ ] **Milestone 2: Flutter Frontend Performance Optimization**
  - [ ] Riverpod state selectors in `PondsDashboardScreen`
  - [ ] Parallelize network waterfalls (`Future.wait`)
  - [ ] Virtualize all `ListView` in `BitacoraScreen` and `IcaCertificationScreen`
  - [ ] Memoize biometry sorting, GDP deltas, and report engines
  - [ ] Fix `PondBentoCard` 3D flip repainting and controller lifecycle
  - [ ] Fix responsive layout overflows (360px–1920px) in `FishBitHeader`, `PondsDashboardScreen`, and `FinanceScreen`
  - [ ] Clean up controller memory leaks in `warehouse_screen.dart` and `nueva_factura_modal.dart`
  - [ ] Worker, Reviewer, Challenger, and Auditor verification
- [ ] **Milestone 3: Production Hardening, Analysis & Test Suite**
  - [ ] Fix domain model deserialization safety in `BiometriaRecord` and `MortalityRecord`
  - [ ] Harden `analysis_options.yaml` (strict rules and lints)
  - [ ] Inject secrets via `--dart-define` / `const String.fromEnvironment()`
  - [ ] Wire `FlutterSecureStorage` in `LocalStorageService`
  - [ ] Expand test suite across all modules
  - [ ] Run `flutter analyze --no-fatal-infos` (0 issues)
  - [ ] Run `flutter test` (100% pass)
  - [ ] Worker, Reviewer, Challenger, and Auditor verification
