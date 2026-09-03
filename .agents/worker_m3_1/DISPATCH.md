## 2026-08-29T04:37:37Z
You are the Bitácora UI/UX & Presentation Worker for Milestone 3 (M3).
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_1
Workspace root: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit

Read the following reference files:
1. ORIGINAL_REQUEST.md: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
2. PROJECT.md: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_main_1\PROJECT.md
3. M2 Worker Handoff: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m2_1\handoff.md
4. UI Survey Handoff: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_ui_1\handoff.md
5. UI Survey Analysis: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_ui_1\analysis.md

Milestone 3 Scope & Objectives:
1. `lib/modules/bitacora/presentation/screens/bitacora_screen.dart`:
   - Tab 3 ("Biometrías y Curvas" / "Biometrías y GDP"):
     - Connect to `pondsState.biometries`. Filter by `_selectedPondId` if selected.
     - Implement chronological sorting and accurate period GDP calculation between consecutive sampling dates: `(W_k - W_{k-1}) / (t_k - t_{k-1})` in g/day, with fallback to stocking date if first sample.
     - Render historical sampling cards with sampling date, pond name, batch code, species, sample count (`pecesCapturados`), average weight (`pesoPromedioG` g), biomass (`biomasaParcialKg` kg), length (`longitudCm` cm), period GDP (`gdpGDia` g/día), and notes.
     - Include a summary header card with aggregated biometric KPIs (latest average weight, period GDP, total samplings).
   - Tab 4 ("Mortalidad y Sanidad" / "Bajas y Sanidad"):
     - Connect to `pondsState.mortalityRecords`. Filter by `_selectedPondId` if selected.
     - Render real mortality incident cards with date/hour, pond name, batch code, species, quantity of losses, cause of death, lost biomass, and cumulative mortality %.
     - Include a summary header card with mortality KPIs (total bajas, biomasa perdida acumulada, causa predominante, tasa de supervivencia).
   - Reactive Pond Filter & Header:
     - In `_buildPondFilter`: wrap the pond name column and text in `Expanded` with `TextOverflow.ellipsis` so selecting long pond names with the "Limpiar" button never triggers a RenderFlex overflow on 360px mobile viewports.
     - In `_showPondFilterBottomSheet`: list all available active ponds from `pondsState.ponds` (so any pond can be filtered, not just ponds that already had records).
     - Ensure selecting a pond reactively filters all 4 tabs simultaneously (Water Quality, Feeding, Biometrics, Mortality).
     - Ensure tapping "Limpiar" clears the filter for all 4 tabs simultaneously.
   - Responsive Layout (Mobile 360px & Web >768px):
     - Wrap list views or cards with `ConstrainedBox(constraints: BoxConstraints(maxWidth: 1024))` centered for wide web displays.
     - Ensure all cards, badges, and action buttons render without overflow on 360px screens.
2. Modals (`ParametroModal`, `BiometriaModal`, `MortalidadModal`, `AlimentarModal`):
   - Review and fix any 360px responsive constraint issues if present.
3. Run `flutter analyze` and ensure `No issues found!`.
4. Run `flutter test` across the project test suite.
