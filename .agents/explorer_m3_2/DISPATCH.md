# Task Dispatch: Explorer M3_2 (Navigation Dock & Gesture Bar SafeArea — UX-02)

## Mission
Investigate `lib/app/main_navigation_shell.dart` and screen FAB positions across the app to resolve system gesture bar collisions and eliminate cascading `bottom: 78` padding hacks.

## Mandatory Paths to Read First
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md` (MANDATORY)
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_gen2\PROJECT.md`
- `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib/app/main_navigation_shell.dart`
- Search codebase for occurrences of `bottom: 78` or `bottom: 80` padding hacks on floating action buttons / screens.

## Investigation Scope
1. Inspect how the floating bottom navigation dock is currently anchored in `main_navigation_shell.dart`.
2. Check if `SafeArea(bottom: true)` or `MediaQuery.viewPaddingOf(context).bottom` is respected, or if gesture pills on iOS / Android overlap the dock items.
3. Identify all FABs and screens using arbitrary hardcoded offsets (such as `bottom: 78`, `bottom: 80`) to clear the dock.
4. Design the clean architectural solution:
   - Floating dock wrapped with proper insets / SafeArea accounting for dynamic system bottom insets.
   - Standard bottom padding provider or Scaffold floatingActionButtonLocation / persistent footer configuration.
5. Provide exact code diffs and implementation recommendations for Worker M3.

Write report to:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2\handoff.md`
Notify orchestrator via `send_message`.

## 2026-09-14T14:35:47Z
You are Explorer M3_2.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2
Read your instructions in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2\DISPATCH.md.
MANDATORY: Read c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md first.
Investigate lib/app/main_navigation_shell.dart, system gesture insets, SafeArea(bottom: true), and cascading bottom: 78 padding hacks.
Write your report to c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_m3_2\handoff.md and notify orchestrator via send_message.
