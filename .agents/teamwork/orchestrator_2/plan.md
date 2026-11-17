# Master Remediation Plan — FishBit Finance 2.0

## Objective
Implement and verify all 16 architectural, performance, data traceability, and UX/ergonomics findings identified in `FINAL_AUDIT_REPORT.md` across 4 structured milestones plus final verification and forensic auditing.

---

## Milestone 1: Database Schema, Atomic RPC & Data Traceability (R1)
1. **Scope & Targets**:
   - `supabase/migrations/20261027_master_traceability_and_rls_hardening.sql`:
     - Create `public.traslados_lotes` DDL with composite indexes and strict RLS tenant isolation.
     - Harden RLS policies for `compras_mat_biologico`, `equipos`, `mantenimientos`, `facturas`, `inventario_insumos` to enforce `empresa_id = (SELECT public.get_auth_empresa_id())`.
     - Implement atomic RPC `public.split_or_transfer_batch`.
   - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
     - Invoke `public.split_or_transfer_batch` instead of 5 separate un-atomic REST calls.
     - Fix polyculture biomass overwriting in biometry and mortality updates by calculating pond biomass via SQL aggregation or summing all active lots.
   - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` & `sales_provider.dart`:
     - Deduct fish count proportionally on partial harvest sales.
   - `lib/core/reports/web_download_helper_stub.dart` & `ica_official_reports_engine.dart`:
     - Implement non-web report download/sharing via `path_provider` and `share_plus`.
   - 8 Field Dialogs:
     - Clear hardcoded defaults in `parametro_modal.dart`, `siembra_modal.dart`, `mortalidad_modal.dart`, `biometria_modal.dart`, `traslado_modal.dart`, `venta_rapida_modal.dart`, `crear_colaborador_modal.dart`, `ica_biosecurity_modals.dart`.
2. **Success Criteria**:
   - Schema and RPC syntax validated.
   - Polyculture ponds preserve multi-species biomass.
   - Proportional fish deduction in sales.
   - Official reports downloadable on mobile/desktop.
   - All 8 dialogs initialize with empty inputs and mandatory validation.

---

## Milestone 2: Dual Platform Performance Optimization (R2)
1. **Scope & Targets**:
   - `lib/core/design_system/glass_container.dart`:
     - Add `enableBlur: false` option and bypass `BackdropFilter` when `blur <= 0.0 || effectiveOpacity >= 0.85`.
   - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`:
     - Disable blur on virtualized list items.
     - Replace broad provider watching with `.select(...)` and modularize tabs.
   - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`:
     - Optimize 3D flip card animation by lazily instantiating only the visible face based on rotation angle.
   - `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart`:
     - Scope broad Riverpod watchers with `.select(...)`.
   - `lib/app/app.dart` & Dashboard screens:
     - Apply `maxWidth: 1200` constraints to large-screen layouts (1920px).
     - Set up `AppScrollBehavior` with desktop mouse drag support.
   - `lib/core/design_system/dock_bottom_spacer.dart` (or Bitacora):
     - Replace hardcoded `SizedBox(height: 80)` with adaptive `DockBottomSpacer` respecting SafeArea.
2. **Success Criteria**:
   - Smooth 60 FPS scrolling in Bitacora and Ponds screens.
   - Bento card does not instantiate hidden face.
   - Web view bounded at 1200px max width.
   - Bottom items in Bitacora are not occluded by the 104 dp dock.

---

## Milestone 3: UI/UX Interaction Design & Field Ergonomics (WCAG 2.2) (R3)
1. **Scope & Targets**:
   - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart`:
     - Enlarge primary action button height to 48 dp (WCAG 2.5.5).
     - Fix inverted color tokens (`isDark ? Colors.white : AppColors.textPrimaryLight`).
   - `lib/core/design_system/glass_action_hub_sheet.dart`:
     - Enlarge close button to minimum 48x48 dp touch target.
   - `lib/core/design_system/app_colors.dart` & `app_typography.dart`:
     - Verify and wire high-contrast text tokens (`cyanWaterTextLight`, `greenBiomassTextLight`, etc.) ensuring >= 4.5:1 contrast against light backgrounds.
   - Field Modals Presentation:
     - Provide adaptive bottom sheet presentation for mobile devices while keeping centered dialogs for desktop web.
2. **Success Criteria**:
   - Touch targets >= 48x48 dp verified.
   - Light theme contrast ratio >= 4.5:1 verified.
   - Mobile presents thumb-friendly modal bottom sheets for routine field actions.

---

## Milestone 4: Offline Data Resilience & State Preservation (R4)
1. **Scope & Targets**:
   - `lib/core/storage/offline_sync_queue.dart`:
     - Wire `flushQueue` to app startup and network restoration events (`connectivity_plus`).
   - `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` & `supabase_ponds_repository.dart`:
     - Wire `OfflineSyncQueue.instance.enqueue` on network failures instead of volatile in-memory storage (`_demoRecords`).
   - `lib/app/router.dart`:
     - Refactor navigation shell from simple `ShellRoute` to `StatefulShellRoute.indexedStack` to preserve tab scroll state and avoid redundant re-fetches.
   - `lib/core/errors/app_failure.dart` & Repositories:
     - Eradicate silent `catch (_)` blocks; propagate typed `NetworkFailure`, `OfflineSyncFailure`, and `DatabaseConstraintFailure`.
2. **Success Criteria**:
   - Offline operations safely persist and flush on reconnect.
   - Tab switching preserves scroll position and state.
   - Typed error reporting and feedback on failed operations.

---

## Milestone 5: Verification, Flutter Analyze & Final Forensic Audit
1. **Scope & Targets**:
   - Run `flutter analyze` across the entire codebase — 0 errors, 0 warnings.
   - Run test suite to verify no regressions.
   - Challenger adversarial tests.
   - Forensic Auditor verification across all 16 items.
2. **Success Criteria**:
   - Binary PASS from Reviewers, Challengers, and Forensic Auditor.
