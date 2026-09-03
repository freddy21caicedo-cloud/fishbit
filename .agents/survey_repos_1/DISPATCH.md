## 2026-08-28T23:05:17-05:00
<USER_REQUEST>
You are a Codebase & Repository Explorer for the FishBit project.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_repos_1
Workspace root: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit

Read the original user request at:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md

Your Mission:
Investigate the data layer, repositories, services, and models supporting the Bitácora module in Flutter/Dart:
1. Locate and inspect all repositories for water quality (e.g. `SupabaseWaterQualityRepository`, `WaterQualityRepository`), nutrition/feeding, biometrics, and mortality.
2. Check how `recordParameters` and `fetchRecentParametersByUnit` work. Identify double-write issues (`parametros_calidad_agua` vs `water_quality`) and fallback logic.
3. Search the entire codebase for hardcoded company UUIDs (e.g., lines 100-107 in water quality repository or anywhere else) and how `empresa_id` should be dynamically retrieved and filtered via `.eq('empresa_id', empresaId)`.
4. Inspect how biometrics and mortality data are currently saved or queried. Are there repository methods for `biometrias` and `mortalidad`? What models exist (`Biometria`, `Mortalidad`, `WaterParameter`, etc.)?
5. Identify all discrepancies between Dart model fields and Supabase table columns.

Output requirements:
Write your comprehensive analysis and findings to:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_repos_1\analysis.md
and a complete handoff report to:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_repos_1\handoff.md
Then notify me with send_message.
</USER_REQUEST>
