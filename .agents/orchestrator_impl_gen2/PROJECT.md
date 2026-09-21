# Project: FishBit Finance 2.0 — Audit Resolution & Hardening

## Architecture
- **Framework**: Flutter (Dart >=3.0.0 <4.0.0) with Riverpod state management.
- **Backend**: Supabase PostgreSQL with Row Level Security (RLS) policies.
- **Design System**: Glassmorphic theme system with reactive light/dark modes and WCAG 2.2 AA compliance.
- **Storage & Offline**: `SharedPreferences` backed `OfflineSyncQueue` with automatic network sync.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | SEC-01: Remove hardcoded credentials | Remove Supabase URL and anonKey fallback strings from `lib/main.dart`; enforce `--dart-define` with startup pre-validation / asserts | M1 | ORIGINAL_REQUEST §R1 |
| 2 | SEC-01: Strict RLS multi-tenancy | Eliminate `OR empresa_id IS NULL` across all 8 transactional tables in `supabase_migration_v10_canonical_v2.sql` and protect profile escalation | M1 | ORIGINAL_REQUEST §R1 |
| 3 | SEC-02: Auth bypass elimination | Remove passwordless login bypass on `miembros_equipo` in `supabase_auth_repository.dart` | M1 | ORIGINAL_REQUEST §R1 |
| 4 | SEC-03: Invitation backdoor removal | Eliminate mock user backdoor on invalid/expired tokens in `registerWithInvitationToken` | M1 | ORIGINAL_REQUEST §R1 |
| 5 | SEC-03: Admin role validation | Validate caller's admin privileges before allowing `createTeamMember` | M1 | ORIGINAL_REQUEST §R1 |
| 6 | DATA-01: Water quality zero-defaults | Initialize all 11 parameter controllers empty in `parametro_modal.dart`; remove fallback `??` operators | M2 | ORIGINAL_REQUEST §R2 |
| 7 | DATA-01: Mandatory parameter validation | Enforce required validation on O2 (0-30 mg/L), Temp (5-45 °C), pH (0-14) and pond selection before saving; support decimal comma | M2 | ORIGINAL_REQUEST §R2 |
| 8 | UX-01: Bento card touch targets | Restructure micro-buttons in `pond_bento_card.dart` to >=48x48 dp (WCAG 2.5.5) via primary action button and operational bottom sheet | M3 | ORIGINAL_REQUEST §R3 |
| 9 | UX-02: System gesture bar safe area | Add `SafeArea(bottom: true)` and dynamic insets to `main_navigation_shell.dart`; eliminate cascading `bottom: 78` padding hacks | M3 | ORIGINAL_REQUEST §R3 |
| 10 | A11Y-01: High-contrast typography | Decouple hardcoded dark colors from `AppTypography`; configure reactive light/dark `TextTheme` in `theme_provider.dart` (>=4.5:1 contrast) | M3 | ORIGINAL_REQUEST §R3 |
| 11 | DATA-02: Offline mutation queueing | Wire `OfflineSyncQueue` into `SupabasePondsRepository`, `SupabaseWaterQualityRepository`, and `SupabaseNutritionRepository` | M4 | ORIGINAL_REQUEST §R4 |
| 12 | DATA-02: Idempotent queue flush | Upgrade `OfflineSyncQueue.flushQueue` to use `.upsert()` preventing duplicate key errors on reconnect | M4 | ORIGINAL_REQUEST §R4 |
| 13 | PERF-01: Typed AppFailure errors | Make `AppFailure` implement `Exception`, add `NetworkFailure`/`StorageFailure`, and replace silent `catch (_)` blocks with typed user error reporting | M4 | ORIGINAL_REQUEST §R4 |
| 14 | QUAL-01: Test suite & analysis pass | Fix pre-existing test failures, add tests for R1-R4, and verify `flutter analyze --no-fatal-infos` returns 0 issues | M5 | ORIGINAL_REQUEST Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Security & Multi-Tenancy | SEC-01, SEC-02, SEC-03: `main.dart`, `supabase_migration_v10_canonical_v2.sql`, `supabase_auth_repository.dart` | none | DONE |
| 2 | M2: Regulatory Data Integrity | DATA-01: `parametro_modal.dart` zero defaults, required validation (O2, Temp, pH), pond check | none | DONE |
| 3 | M3: Field Ergonomics & WCAG A11y | UX-01, UX-02, A11Y-01: `pond_bento_card.dart`, `main_navigation_shell.dart`, `app_typography.dart`, `theme_provider.dart` | none | IN_PROGRESS |
| 4 | M4: Offline Data Resilience | DATA-02, PERF-01: `offline_sync_queue.dart`, 3 Supabase repos, `app_failure.dart` | M1, M2 | PLANNED |
| 5 | M5: E2E Testing & Final Verification | Fix existing tests, add regression/integration tests, run `flutter analyze --no-fatal-infos` | M1, M2, M3, M4 | PLANNED |

## Interface Contracts
### Auth & Multi-Tenancy ↔ App Startup
- `lib/main.dart` extracts `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `String.fromEnvironment` without defaults.
- Asserts/validates: `url.isNotEmpty && Uri.parse(url).hasScheme`, `anonKey.isNotEmpty`. Throws descriptive `StateError` if missing in production.

### Water Quality Modal ↔ ICA Compliance
- `ParametroModal` requires: `estanqueId != null` (active pond), `oxigenoMgL != null && in (0, 30)`, `temperatura != null && in (5, 45)`, `ph != null && in (0, 14)`.
- All input fields start completely empty `text = ''` (no deceptive default 7.4 or 6.2).
- Form validation blocks submission otherwise with descriptive SnackBars.
- Concurrency locked via `_isSubmitting` with `GlassButton` loading feedback.

### UI Field Ergonomics & WCAG A11y (M3)
- `pond_bento_card.dart`: Touch targets >=48x48 dp (WCAG 2.5.5) via primary action button / bottom sheet.
- `main_navigation_shell.dart`: Dynamic `SafeArea(bottom: true)` insets.
- `AppTypography` / `theme_provider.dart`: Contrast ratio >=4.5:1 (WCAG 2.2 AA).

### Repositories ↔ OfflineSyncQueue (M4)
- `OfflineSyncQueue.enqueue({required OfflineActionType type, required String table, required Map<String, dynamic> payload})`: stores mutation in persistent JSON queue.
- `OfflineSyncQueue.flushQueue(SupabaseClient supabase)`: iterates queue with `.upsert(item.payload)`.

## Code Layout
- `lib/main.dart` — App entry point and Supabase bootstrap
- `lib/core/design_system/` — `app_typography.dart`, `app_colors.dart`, `theme_provider.dart`, `glass_button.dart`
- `lib/core/storage/` — `offline_sync_queue.dart`
- `lib/core/errors/` — `app_failure.dart`
- `lib/app/` — `main_navigation_shell.dart`
- `lib/modules/auth_tenant/` — `infrastructure/repositories/supabase_auth_repository.dart`
- `lib/modules/water_quality/` — `presentation/dialogs/parametro_modal.dart`, `infrastructure/repositories/supabase_water_quality_repository.dart`
- `lib/modules/ponds_batches/` — `presentation/widgets/pond_bento_card.dart`, `infrastructure/repositories/supabase_ponds_repository.dart`
- `lib/modules/feeding_nutrition/` — `infrastructure/repositories/supabase_nutrition_repository.dart`
- `supabase_migration_v10_canonical_v2.sql` — Canonical SQL schema and RLS policies
