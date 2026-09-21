# BRIEFING — 2026-09-14T14:36:15Z

## Mission
Investigate `lib/app/main_navigation_shell.dart`, system gesture bar safe area insets, and cascading `bottom: 78` padding hacks across screens to design a robust layout architecture.

## 🔒 My Identity
- Archetype: explorer
- Roles: investigation, synthesis
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2
- Original parent: f76e9946-db3e-4f3a-ab27-ecce6f54c08e
- Milestone: M3 (UX-02: Navigation Dock & Gesture Bar SafeArea)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement production code
- Only write within c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2
- Keep BRIEFING under ~100 lines
- Produce 5-component handoff report (handoff.md)
- Report back to parent via send_message

## Current Parent
- Conversation ID: f76e9946-db3e-4f3a-ab27-ecce6f54c08e
- Updated: not yet

## Investigation State
- **Explored paths**:
  - `ORIGINAL_REQUEST.md`, `PROJECT.md`, `DISPATCH.md`
  - `lib/app/main_navigation_shell.dart`
  - `lib/core/design_system/glass_action_hub_sheet.dart`
  - 7 screens with FAB padding: `ponds_dashboard_screen.dart`, `warehouse_screen.dart`, `bitacora_screen.dart`, `water_quality_records_screen.dart`, `finance_screen.dart`, `sales_screen.dart`, `gestion_equipo_screen.dart`
  - Screens with hardcoded dock spacers: `home_dashboard_screen.dart`, `ica_certification_screen.dart`, etc.
- **Key findings**:
  - Root cause: `MainNavigationShell` anchors dock in an outer Stack without `SafeArea(bottom: true)` (using raw `MediaQuery.padding.bottom`), causing gesture bar collisions.
  - Inner Scaffolds have no knowledge of the outer floating dock, which prompted developers to cascade `Padding(padding: const EdgeInsets.only(bottom: 78))` onto 7 FABs and `SizedBox(height: 100)` onto scrollable bodies.
  - On iOS (34dp inset), FABs are pushed to 128dp from bottom, leaving an awkward 26dp gap; on devices with 0dp inset, dock is 76dp and FAB is 94dp. Fixed `SizedBox(height: 80/100)` causes content occlusion on iOS devices.
- **Unexplored areas**: None. Entire scope investigated.

## Key Decisions Made
- Architecture:
  1. Wrap dock in `SafeArea(bottom: true)` with `Padding(fromLTRB(16, 0, 16, 12))` and keyboard suppression (`viewInsetsOf(context).bottom > 0`) in `main_navigation_shell.dart`.
  2. Implement `FloatingDockLayout` and `FloatingDockFabLocation.endFloat` in `lib/core/design_system/floating_dock_layout.dart` to calculate dynamic `scaffoldGeometry.minViewPadding.bottom + dockClearance`.
  3. Provide `DockBottomSpacer` and `SliverDockBottomSpacer` to replace `SizedBox(height: 100/80)`.
  4. Strip all 7 occurrences of `Padding(padding: const EdgeInsets.only(bottom: 78))` from FABs and replace with `floatingActionButtonLocation: FloatingDockFabLocation.endFloat`.


## Artifact Index
- `DISPATCH.md` — Task instructions
- `BRIEFING.md` — Persistent state and working memory
- `progress.md` — Heartbeat and step tracking
- `handoff.md` — Final 5-component handoff report
