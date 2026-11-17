# HANDOFF REPORT — Explorer Survey 3 (Ergonomics, WCAG 2.2 & Offline Resilience)

**Date:** 2026-10-27T17:05:00Z  
**Role:** Explorer Subagent (Ergonomics & Offline Specialist)  
**Parent Orchestrator:** `8bee9cda-5a61-477e-925b-df39d71e3b3a`  
**Working Directory:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\explorer_survey_3`  
**Detailed Report Reference:** `survey_report.md`

---

## 1. Observation

Direct code observations from the codebase investigation:
1. **Touch Target Dimensions (WCAG 2.5.5):**
   - In `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` line 411:
     `SizedBox(width: double.infinity, height: 40, child: ElevatedButton(...))` has explicit height of **40 dp**, violating WCAG 2.5.5 minimum 48x48 dp.
   - In `lib/core/design_system/glass_action_hub_sheet.dart` lines 108–115:
     Close button is `Container(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 16))`, resulting in a tiny **24x24 dp** tap target.
2. **Sunlight Contrast & Light Theme Tokens (WCAG 1.4.3):**
   - In `lib/core/design_system/app_colors.dart` lines 27–31:
     `cyanWater = Color(0xFF00B2CC)`, `greenBiomass = Color(0xFF10B981)`, `amberWarning = Color(0xFFFF9500)`.
     On `#FFFFFF` / `#F6F8FA` surfaces, their relative luminance yields contrast ratios of **2.56:1**, **2.33:1**, and **1.98:1** respectively, failing WCAG 1.4.3 minimum 4.5:1.
   - In `lib/core/design_system/app_colors.dart` line 56:
     `AppColors.accentText(context, color)` is defined with high-contrast variants (`cyanWaterTextLight = Color(0xFF007A8C)`, `greenBiomassTextLight = Color(0xFF047857)`, `amberWarningTextLight = Color(0xFFB45309)`), but `grep_search` confirmed it is **used in 0 widgets across the application**.
   - In `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` lines 217, 248, 510, 512, 566:
     Inverted logic `isDark ? Colors.white : AppColors.textPrimaryDark` renders `#FFFFFF` (white text) on white cards when light mode is enabled.
3. **One-Handed Field Usability (Dialogs vs Sheets):**
   - Field operations (`parametro_modal.dart:21`, `alimentar_modal.dart:25`, `biometria_modal.dart:20`, `mortalidad_modal.dart:21`, `traslado_modal.dart:20`, `siembra_modal.dart:26`) all invoke `showDialog()` and build centered `Dialog()` widgets, forcing farm workers to reach the upper half of large mobile screens and causing abrupt vertical jumps when the virtual keyboard opens.
4. **Offline Resilience & Queue Architecture:**
   - In `lib/core/storage/offline_sync_queue.dart` line 97:
     `flushQueue(SupabaseClient supabase)` exists, but is **never called anywhere in the codebase**.
   - In `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` lines 130–139:
     Network errors trigger `catch (_)` which inserts records into an ephemeral, in-memory array `_demoRecords.insert(0, record)`. When the application is killed or refreshed, all offline feeding data is lost. `OfflineSyncQueue.enqueue()` is NOT called.
   - In `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` lines 940–943 & 1103–1106:
     Biometrics and mortality mutations simply `debugPrint` and `rethrow`, failing without local persistence.
   - Only `supabase_water_quality_repository.dart:130` calls `OfflineSyncQueue.enqueue()`, but because `flushQueue()` is never invoked, those records remain permanently queued.
5. **GoRouter Lifecycle & Shell State:**
   - In `lib/app/router.dart` line 126:
     Uses `ShellRoute` instead of `StatefulShellRoute.indexedStack`. Switching tabs unmounts and remounts screens, wiping scroll offset, local filters, and re-triggering remote queries.
   - In `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` lines 718, 961, 1179, 1738 and `gestion_equipo_screen.dart:140`:
     Fragile hardcoded `SizedBox(height: 80)` is used instead of `DockBottomSpacer()`, occluding the bottom content under the floating dock on modern devices where clearance exceeds 104 dp.
6. **Silent Exceptions & Typed Failure:**
   - Over 50 instances of silent `catch (_)` swallow network and database errors without notifying users.
   - `lib/core/errors/app_failure.dart` lacks `NetworkFailure`, `OfflineSyncFailure`, and `PermissionFailure`.

---

## 2. Logic Chain

1. **Premise:** FishBit is designed for aquaculture field use where technicians and farm managers operate around outdoor earthen ponds and geomembranes with wet hands, glare, and spotty 3G/4G connectivity.
2. **Ergonomic Deficiency:** A 40 dp button (`pond_bento_card.dart:411`) and 24 dp button (`glass_action_hub_sheet.dart:108`) lead directly to touch misses, especially with wet fingers. Meeting WCAG 2.5.5 ($\ge 48$ dp) is necessary to ensure operational accuracy in rugged farm conditions.
3. **Contrast Deficiency:** A relative luminance ratio of 2.56:1 for `cyanWater` on white surfaces falls far short of WCAG 1.4.3 (4.5:1). Under 50,000–100,000 lux outdoor sunlight, contrast washes out completely. Because `accentText()` was created but never wired to widgets, activating `accentText()` across UI components immediately restores outdoor readability.
4. **Offline Breakdown:** If `flushQueue()` is never invoked and mutations in nutrition and ponds bypass `OfflineSyncQueue`, workers in remote fish farms lose critical feeding and biological mortality data whenever network drops. Connecting all operational mutations to `OfflineSyncQueue` and registering a connectivity listener ensures zero data loss.
5. **Navigation Jank:** `ShellRoute` forces unnecessary garbage collection and reconstruction of screens on each tab change. Migrating to `StatefulShellRoute.indexedStack` stabilizes memory, preserves scroll positions, and prevents wasted network requests.

---

## 3. Caveats

- **Scope Boundary:** This audit is strictly read-only. No application source code has been altered.
- **Hardware Variation:** Screen brightness and reflectance depend on specific device hardware (e.g., peak nit brightness of OLED vs LCD). However, WCAG 2.2 AA contrast compliance is device-agnostic and guarantees baseline legibility.
- **Backend Schema Compatibility:** Offline sync items in `OfflineSyncQueue` use JSON payloads mapped directly to table column names. Any changes to Postgres table schemas must ensure backward compatibility for pending offline payloads.

---

## 4. Conclusion

The application architecture in R3 (Ergonomics/WCAG) and R4 (Offline/State) has solid foundations (design system tokens, `OfflineSyncQueue` scaffold, `FloatingDockLayout`), but suffers from incomplete integration:
- Touch targets must be expanded to $\ge 48\times 48$ dp.
- Light theme must adopt `AppColors.accentText()` and fix inverted text tokens.
- Field modals should adapt to `showModalBottomSheet` on mobile devices.
- `OfflineSyncQueue` must be activated with automatic flushing on connectivity restoration, and repositories must route failed mutations through it instead of RAM or unhandled rethrows.
- GoRouter should be upgraded to `StatefulShellRoute.indexedStack`.

---

## 5. Verification Method

To independently verify these findings:
1. **Touch Targets:**
   - Inspect `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` line 411: verify `height: 40`.
   - Inspect `lib/core/design_system/glass_action_hub_sheet.dart` line 108: verify `padding: EdgeInsets.all(4)` and `icon: size 16`.
2. **Contrast & Tokens:**
   - Run grep for `accentText` across `lib/`: observe match only in `app_colors.dart`.
   - Inspect `pond_bento_card.dart` line 217, 248, 510: observe `AppColors.textPrimaryDark` and `Colors.white` used without light theme branch.
3. **Offline Queue:**
   - Run grep for `flushQueue` across `lib/`: observe single declaration, zero calls.
   - Run grep for `OfflineSyncQueue` across `lib/`: observe it is only referenced in `supabase_water_quality_repository.dart`.
4. **Shell Navigation:**
   - Inspect `lib/app/router.dart` line 126: verify `ShellRoute` is used instead of `StatefulShellRoute`.
   - Inspect `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` lines 718, 961, 1179: verify `SizedBox(height: 80)`.
5. **Analyze command:**
   - Run `flutter analyze --no-fatal-infos` in terminal to verify baseline static analysis.
