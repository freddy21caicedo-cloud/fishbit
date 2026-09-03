## 2026-08-31T19:52:38Z
You are an Explorer subagent specializing in Flutter Frontend Architecture and Performance.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_fe
The authoritative request is located at: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md

Task:
1. Read ORIGINAL_REQUEST.md.
2. Thoroughly investigate the Flutter codebase in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\lib (especially screen files, widgets, viewmodels, providers, and state management):
   - Locate and examine PondsDashboardScreen, BitacoraScreen, IcaCertificationScreen and their dependent widgets/components.
   - Profile/inspect rebuild patterns, list views, heavy computations on UI thread, controller lifecycles, memory leaks (e.g. unclosed StreamSubscriptions, AnimationControllers, TextEditingControllers).
   - Analyze Riverpod state usage: provider granularity, ref.watch vs ref.read, select(), autoDispose, state immutability, caching.
   - Inspect responsive design across 360px to 1920px (LayoutBuilder, MediaQuery, flexible/expanded widgets, overflow vulnerabilities).
3. Produce a detailed diagnostic and optimization plan report in c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_fe\handoff.md with specific file paths, line numbers, identified bottlenecks, and concrete code remediation strategies.
4. Send a message to the orchestrator when finished.
