# DISPATCH LOG

## 2026-10-27T18:07:30Z
Sender: 230be252-0155-4386-a5bb-643ae4e097ee
Role: Project Orchestrator (orchestrator_2)

Message:
You are the Project Orchestrator (orchestrator_2) for FishBit Finance 2.0 remediation.
Your working directory is:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\orchestrator_2

Workspace Root:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit

Authoritative Request:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\ORIGINAL_REQUEST.md

Master Audit Findings:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\orchestrator_1\FINAL_AUDIT_REPORT.md

Mission:
Execute the end-to-end implementation and remediation of all 16 architectural, performance, data traceability, and UX/ergonomics findings identified in FishBit Finance 2.0 based on `.agents/teamwork/orchestrator_1/FINAL_AUDIT_REPORT.md`.

Requirements:
### R1. Database Schema, Atomic RPC & Data Traceability Remediation
- Deploy the complete DDL for `public.traslados_lotes` with indexes, foreign keys, and hardened RLS tenant isolation (`FINAL_AUDIT_REPORT.md §6.1`).
- Harden RLS policies across the 5 vulnerable tables (`compras_mat_biologico`, `equipos`, `mantenimientos`, `facturas`, `inventario_insumos`) enforcing `empresa_id` tenant isolation.
- Implement the PostgreSQL atomic RPC `public.split_or_transfer_batch` to prevent FCR distortion on lot batch splits (`§6.2`).
- Fix polyculture biomass overwriting in `SupabasePondsRepository` by aggregating total pond biomass with SQL `SUM()` across all active lots.
- Implement proportional fish count deduction on partial harvest sales in `PondsNotifier` and `SalesNotifier`.
- Wire non-web ICA official report downloads via `path_provider` and `share_plus` in `web_download_helper_stub.dart`.
- Clear hardcoded default values across the 8 field dialogs (`parametro_modal.dart`, `siembra_modal.dart`, `mortalidad_modal.dart`, etc.) and require user input.

### R2. Dual Platform (Web & Mobile) Performance Optimization
- Add `enableBlur: false` to `GlassContainer` and bypass `BackdropFilter` shaders on high-opacity light theme surfaces and virtualized list items in `BitacoraScreen` (`§6.4.A`).
- Optimize `PondBentoCard` flip animation by lazily instantiating only the visible card face based on the rotation angle.
- Scope broad Riverpod watchers with `select(...)` in `IcaCertificationScreen` and `BitacoraScreen`.
- Implement responsive Web constraints (`maxWidth: 1200`) and desktop drag support via `AppScrollBehavior`.
- Fix mobile navigation dock occlusion by replacing hardcoded spacers with `DockBottomSpacer` adaptively respecting SafeArea.

### R3. UI/UX Interaction Design & Field Ergonomics (WCAG 2.2)
- Enlarge all primary action targets in `PondBentoCard` and modal dialogs to meet WCAG 2.5.5 minimums (48x48 dp).
- Fix light-mode color token contrast failures in `AppColors` and `AppTypography` to achieve >= 4.5:1 contrast against light backgrounds.
- Provide responsive mobile bottom sheet presentation for field actions while keeping centered dialogs for desktop web.

### R4. Offline Data Resilience & State Preservation
- Wire `OfflineSyncQueue` directly into repository mutation methods and hook `flushQueue` to network reconnection (`connectivity_plus`) and app startup.
- Refactor `router.dart` navigation shell to use `StatefulShellRoute.indexedStack` to preserve tab scroll states across navigation.
- Replace silent `catch (_)` blocks across repositories with typed `AppFailure` propagation and UI snackbar/toast feedback.

Acceptance Criteria:
- `flutter analyze` runs clean with 0 new errors or warnings on all modified files.
- Supabase schema migration script and RPC functions are syntactically valid and tested.
- All 8 field dialogs load with clean, empty inputs and active form validators.
- `OfflineSyncQueue` properly queues operations when simulated offline and flushes upon network restoration.
- Web layout does not stretch uncontrollably past 1200px on widescreen monitors.
- Touch targets on Bento cards measure at least 48x48 dp.
- Tab switching retains scroll position without re-triggering full screen re-fetch.
