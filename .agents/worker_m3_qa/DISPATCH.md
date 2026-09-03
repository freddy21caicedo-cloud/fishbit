## 2026-09-01T01:24:23Z
You are the Production Hardening, Analysis & QA Specialist Worker for Milestone 3.

Your working directory is:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_qa

Read the authoritative documents first:
1. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
2. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_survey_qa\handoff.md
3. c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\PROJECT.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Your Tasks:
1. **Fix Unsafe Type Casting in Domain Models**:
   - In `lib/modules/ponds_batches/domain/models/biometria_record.dart` and `lib/modules/ponds_batches/domain/models/mortality_record.dart`: Replace `(raw as num?)` casting with safe dynamic type checks (`raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '')`, `raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '')`).
   - Run `test/modules/stress_tests/models_stress_test.dart` to verify that String numbers in JSON and stress tests pass without `TypeError`.

2. **Harden `analysis_options.yaml`**:
   - Configure strict analyzer options:
     ```yaml
     analyzer:
       language:
         strict-casts: true
         strict-inference: true
         strict-raw-types: true
     ```
   - Add essential production linter rules (`unawaited_futures`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `prefer_const_constructors`, `avoid_print`, `prefer_final_fields`, etc.).
   - Fix any strict cast or inference errors across `lib/` so `flutter analyze --no-fatal-infos` passes with 0 errors and 0 warnings.

3. **Secrets Injection & Global Error Boundaries**:
   - In `lib/main.dart`: Inject Supabase credentials via `const String.fromEnvironment('SUPABASE_URL', defaultValue: ...)` and `const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ...)`.
   - Setup `FlutterError.onError` and `PlatformDispatcher.instance.onError` for production error resilience.

4. **Storage Security & Asset Cleanup**:
   - Wire `FlutterSecureStorage` into `lib/core/storage/local_storage_service.dart` for sensitive tokens.
   - Clean up `pubspec.yaml` assets if empty directories cause warnings.
   - Update `web/manifest.json` with FishBit metadata.

5. **Test Suite Expansion & Verification**:
   - Add unit/widget tests for uncovered modules (`auth_tenant`, `ica_compliance`, `sales_harvest`, `warehouse_inventory`).
   - Run `flutter analyze --no-fatal-infos` via `run_command` -> must have 0 issues.
   - Run `flutter test` via `run_command` -> 100% tests passing across all suites.
   - Write a complete `handoff.md` in `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m3_qa\handoff.md` and send a message back.
