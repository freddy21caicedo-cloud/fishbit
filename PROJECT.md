# Project: FishBit Production Performance & Hardening

## Architecture
- **Frontend**: Flutter 3.x / Dart (Riverpod 2.5 state management, GoRouter navigation, Glassmorphism design system)
- **Backend & Database**: Supabase (PostgreSQL 15+, Row Level Security, Composite Indexes, Realtime)
- **QA & Reliability**: Static analysis (strict mode), Unit/Widget/Stress test suites, Secret injection via `--dart-define`

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | SQL Helper & Index Optimization | Functional index on `miembros_equipo(LOWER(email))`, `STABLE` helper functions | M1 (DONE) | BE Survey |
| 2 | High-Performance Composite Indexes | Composite indexes on `parametros_calidad_agua`, `alimentacion_diaria`, `lotes`, `biometrias`, `mortalidad`, `traslados_lotes` | M1 (DONE) | BE Survey |
| 3 | Foreign Key Indexes | Coverage indexes on unindexed FKs (`unidad_acuicola_id`, `lote_id`, `cliente_id`, etc.) | M1 (DONE) | BE Survey |
| 4 | RLS InitPlan Caching & Split Policies | Split `_tenant_modify` into INSERT/UPDATE/DELETE and wrap subqueries `(SELECT get_auth_empresa_id())` | M1 (DONE) | BE Survey |
| 5 | Multi-Tenant Security Hardening | Replace `USING (true)` in `traslados_lotes`, add policies to unshielded tables, set views to `SECURITY INVOKER` | M1 (DONE) | BE Survey |
| 6 | Dart Repositories Query Optimization | Add `.eq('empresa_id', ...)` and `.limit(100)` in Warehouse, Finance, Sales, Equipment repositories | M1 (DONE) | BE Survey |
| 7 | Riverpod State Selectors & Provider Granularization | Prevent full dashboard invalidation using `.select()` on `pondsProvider` & family providers | M2 (DONE) | FE Survey |
| 8 | Network Waterfall Parallelization | Replace sequential repository `await` cascades with `Future.wait` in Ponds, Finance, Ica notifiers | M2 (DONE) | FE Survey |
| 9 | List Viewport Virtualization | Convert all `ListView(children: ...)` in `BitacoraScreen` and `IcaCertificationScreen` to `ListView.builder` / `SliverList` | M2 (DONE) | FE Survey |
| 10 | Memoized In-Memory Computations | Move O(N log N) sorting, delta weight gain (GDP), and batch grouping out of UI `build()` into memoized providers | M2 (DONE) | FE Survey |
| 11 | Animation & Repaint Boundaries | Cache static card subtree in `PondBentoCard` 3D flip animation and add `RepaintBoundary` | M2 (DONE) | FE Survey |
| 12 | Controller Lifecycle & Memory Leak Fix | Dispose `TextEditingController` instances in dialogs and modals; add debounce to search | M2 (DONE) | FE Survey |
| 13 | Responsive Layout Hardening (360px–1920px) | Fix `childAspectRatio` in `PondsDashboardScreen`, flexible `FishBitHeader`, speed-dial in `FinanceScreen` FAB | M2 (DONE) | FE Survey |
| 14 | Domain Model Deserialization Safety | Fix unsafe `(raw as num?)` casting in `BiometriaRecord` & `MortalityRecord` to handle String / null safely | M3 | QA Survey |
| 15 | Static Analysis & Linter Hardening | Enable `strict-casts`, `strict-inference`, `strict-raw-types`, and production linter rules in `analysis_options.yaml` | M3 | QA Survey |
| 16 | Secrets & Environment Configuration | Inject Supabase credentials via `const String.fromEnvironment()` and wire `FlutterSecureStorage` | M3 | QA Survey |
| 17 | Global Error Boundaries & Clean Assets | Set up `FlutterError.onError` / `PlatformDispatcher.instance.onError`, clean web manifest and asset declarations | M3 | QA Survey |
| 18 | Comprehensive Unit, Integration & Stress Test Suite | Expand test suite coverage across all modules and verify 100% test pass | M3 | QA Survey |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | PostgreSQL & Supabase Database Optimization | Features 1-6: SQL migration, index coverage, RLS InitPlan, tenant security, Dart repos | none | DONE |
| 2 | Flutter Frontend Performance Optimization | Features 7-13: UI virtualization, Riverpod selectors, parallel Future.wait, layout overflows | M1 | DONE |
| 3 | Production Hardening, Analysis & Test Suite | Features 14-18: Type safety, strict linter, secrets injection, 100% test passing, 0 lint issues | M2 | IN_PROGRESS |

## Code Layout
- `lib/modules/ponds_batches/`: Ponds dashboard, Bento cards, batches, biometries, mortality, transfers
- `lib/modules/bitacora/`: Master aquaculture logbook, tab views, daily logs
- `lib/modules/ica_compliance/`: ICA sanitary records, official reporting engine, certification
- `lib/modules/finance_payroll/`: Payroll engine, production cost, financial dashboard
- `lib/modules/warehouse_inventory/`: Warehouse stock, suppliers, purchase invoices
- `lib/modules/sales_harvest/`: Harvest orders, commercial sales, pricing
- `lib/modules/water_quality/`: Water parameters, sensors, alerts
- `lib/modules/auth_tenant/`: Multi-tenant authentication, profiles, permissions
- `lib/core/`: Design system, glassmorphism, local storage, security, reports
- `supabase/migrations/`: Canonical SQL migrations
- `test/`: Unit, widget, and stress test suites
