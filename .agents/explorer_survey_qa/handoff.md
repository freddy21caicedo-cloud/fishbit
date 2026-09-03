# QA, Build Infrastructure & Production Hardening Survey Report

## 1. Observation

### 1.1 Dependency & SDK Configuration (`pubspec.yaml`)
- **Package Name**: `fishbit_finance`
- **Description**: `"FishBit Finance - Precision Aquaculture ERP & Biological Traceability Platform"`
- **Version**: `2.0.0+1`
- **Environment Constraints**:
  ```yaml
  environment:
    sdk: ">=3.0.0 <4.0.0"
    flutter: ">=3.10.0"
  ```
- **Core Dependencies**:
  - State Management: `flutter_riverpod: ^2.5.1`
  - Navigation: `go_router: ^14.0.0`
  - Backend: `supabase_flutter: ^2.5.0`
  - Storage: `shared_preferences: ^2.2.3`, `flutter_secure_storage: ^9.2.2`
  - UI/UX: `flutter_animate: ^4.5.0`, `cached_network_image: ^3.3.1`, `flutter_svg: ^2.0.10+1`, `intl: ^0.20.3`, `fl_chart: ^0.68.0`
  - Media & Utils: `uuid: ^4.4.0`, `crypto: ^3.0.3`, `url_launcher: ^6.3.2`, `video_player: ^2.14.0`
- **Dev Dependencies**:
  - `flutter_test: sdk: flutter`
  - `flutter_lints: ^3.0.0`
- **Assets Declared**:
  ```yaml
  assets:
    - assets/icons/
    - assets/images/
    - assets/fonts/
    - assets/videos/
  fonts:
    - family: FishBitIcons
      fonts:
        - asset: assets/fonts/FishBitIcons.ttf
  ```
- **Asset Files on Disk**:
  - `assets/fonts/Aquatic-PersonalUse.otf` (Found)
  - `assets/fonts/FishBitIcons.ttf` (Found)
  - `assets/fonts/Readme LIcense.txt` (Found)
  - `assets/videos/login_bg.mp4` (Found)
  - `assets/icons/` and `assets/images/`: Directories exist but are empty on disk.

### 1.2 Static Analysis & Linter Options (`analysis_options.yaml`)
- **Current Content**:
  ```yaml
  analyzer:
    exclude:
      - build/**
      - android/**
      - ios/**
      - web/**
      - windows/**
      - macos/**
      - linux/**
  include: package:flutter_lints/flutter.yaml

  linter:
    rules:
      prefer_const_constructors: true
      prefer_const_declarations: true
      avoid_print: true
      prefer_final_fields: true
      use_key_in_widget_constructors: true
  ```
- **Identified Linter / Code Quality Observations in `lib/`**:
  1. `lib/main.dart` (lines 17–21): Hardcoded Supabase URL & Anon Key with `// ignore: deprecated_member_use`:
     ```dart
     await Supabase.initialize(
       url: 'https://oakovawlwjpnoydpwtam.supabase.co',
       // ignore: deprecated_member_use
       anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
     );
     ```
  2. `lib/core/reports/web_download_helper_web.dart` (lines 1–2):
     ```dart
     // ignore: avoid_web_libraries_in_flutter, deprecated_member_use
     import 'dart:html' as html;
     ```
     `dart:html` is deprecated in modern Dart / WebAssembly (`--wasm`) targets in favor of `package:web`.
  3. `lib/modules/auth_tenant/presentation/screens/login_screen.dart` (line 320):
     `Image.network('https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg', ...)` - `.svg` file fed to `Image.network` causes raster image decoding failure caught by fallback builder instead of rendering SVG natively via `SvgPicture.network`.
  4. Missing strict analyzer flags: `strict-casts`, `strict-inference`, `strict-raw-types`.
  5. Missing vital production linter rules: `unawaited_futures`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`.

### 1.3 Test Suite Catalog & Test Results (`test/`)
10 test files cataloged across `test/`:
1. `test/modules/bitacora/bitacora_screen_test.dart` (662 lines):
   - Tests 4 tabs rendering at 360px mobile viewport.
   - Tests Biometría sampling history and automatic GDP calculation (`+9.29 g/d`).
   - Tests Mortality incident KPI aggregation and cause breakdown.
   - Tests multi-tab synchronized pond filtering and "Limpiar" filter button reset.
   - Tests 360px viewport overflow resistance with long pond titles.
   - Tests web desktop layout centering (>768px).
2. `test/modules/feeding_nutrition/feeding_record_test.dart` (60 lines):
   - Tests JSON serialization matching canonical table `alimentacion_diaria`.
   - Tests deserialization with canonical columns.
3. `test/modules/finance_payroll/payroll_engine_test.dart` (66 lines):
   - Tests Colombian bi-weekly payroll calculation under Ley 1607 (employer health contribution exemption).
   - Tests deductions (8%), provisions (prima, cesantías, intereses, vacaciones, dotación), ARL Class III (2.436%), and employer total cost.
   - Tests non-exempt health employer rate calculation (8.5%).
4. `test/modules/finance_payroll/production_cost_engine_test.dart` (92 lines):
   - Tests Unit Economics CPK (Direct vs Indirect), Gross Margin (COP/kg and %), and Break-Even Point calculation.
   - Tests zero biomass edge cases and division by zero protection.
5. `test/modules/ponds_batches/biometria_record_test.dart` (119 lines):
   - Tests serialization of all 16 `biometrias` schema fields.
   - Tests deserialization with English legacy and Spanish canonical column synonyms.
   - Tests immutable `copyWith()`.
6. `test/modules/ponds_batches/mortality_record_test.dart` (104 lines):
   - Tests serialization with bilingual canonical columns.
   - Tests deserialization with synonym mappings and automatic fallback calculation of `biomasaPerdidaKg`.
7. `test/modules/ponds_batches/ponds_notifier_test.dart` (442 lines):
   - Tests initial state population from repository.
   - Tests optimistic in-memory state mutations on `recordBiometry()` and `recordMortality()`.
   - Stress tests 10 concurrent async operations (5 biometries + 5 mortalities) confirming race condition immunity.
   - Tests error handling setting `errorMessage` without crashing.
8. `test/modules/ponds_batches/ponds_state_test.dart` (115 lines):
   - Tests state collections, total biomass, active pond count, and `copyWith()`.
9. `test/modules/stress_tests/models_stress_test.dart` (445 lines):
   - Tests empty maps, null maps, extreme boundary values.
   - Documents empirical vulnerability: `(rawPeces as num?)` and `(rawCantidad as num?)` throw `TypeError` when values arrive as Strings from JSON.
10. `test/modules/water_quality/water_parameter_test.dart` (132 lines):
    - Tests all 10 physicochemical parameters (O2, pH, Temp, NH3, NO2, NO3, Alkalinity, CO2, Hardness, Cl).
    - Tests critical thresholds (`isOxygenCritical`, `isPhCritical`, `isAmmoniaCritical`, etc.).
    - Tests legacy format backward compatibility.

### 1.4 Production Hardening, Environment & Platform Configuration
- **Platform directories**: `web/` is configured with `index.html` and `manifest.json`. `android/`, `ios/`, `windows/`, `macos/`, `linux/` are not generated yet.
- **Web Manifest (`web/manifest.json`)**: Contains generic placeholder values (`"description": "A new Flutter project."`, theme color `#0175C2`).
- **Secrets Management**: Hardcoded API keys in `main.dart` instead of `--dart-define` / `--dart-define-from-file`.
- **Local Storage Security**: `LocalStorageService` persists session user ID and active company in plain `SharedPreferences`. `flutter_secure_storage` is imported in `pubspec.yaml` but not yet wired to encrypt sensitive auth tokens.

---

## 2. Logic Chain

1. **Premise**: Production readiness requires 0 errors, 0 warnings under strict static analysis, resilient domain models, secured secrets/tokens, and 100% test suite reliability.
2. **Analysis of Domain Model Deserialization**:
   - `models_stress_test.dart` (lines 128-143 & lines 275-288) proves that `BiometriaRecord.fromJson` and `MortalityRecord.fromJson` perform `(raw as num?)`. In Dart runtime type system, evaluating `("45" as num?)` throws a fatal `TypeError: type 'String' is not a subtype of type 'num?' in type cast`, bypassing the `int.tryParse()` fallback.
   - Conversely, `WaterParameter.fromJson` (lines 68–78 of `water_parameter.dart`) safely utilizes `double.tryParse((...).toString())`, preventing any cast exceptions regardless of incoming JSON data types.
   - *Inference*: `BiometriaRecord` and `MortalityRecord` must be updated to use the safe parsing pattern (`raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '')`).
3. **Analysis of Static Analysis Rules (`analysis_options.yaml`)**:
   - The current `analysis_options.yaml` enables only 5 basic rules.
   - Without `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`, type mismatches in generic collections (`Map<String, dynamic>`) can pass compilation and crash at runtime.
   - Without `unawaited_futures: true` and `use_build_context_synchronously: true`, async operations in UI sheets/modals can leak memory or execute against unmounted widgets.
4. **Analysis of Secrets & Storage Security**:
   - Hardcoding Supabase URL and Anon Key in `main.dart` exposes project credentials and prevents environment switching (Local/Staging/Production).
   - Storing session data in unencrypted `SharedPreferences` leaves user tokens accessible to client-side extraction on rooted Android devices or iOS backups.
   - *Inference*: Environment variables must be injected via `String.fromEnvironment()` / `--dart-define`, and sensitive token persistence must utilize `flutter_secure_storage`.
5. **Analysis of Test Coverage Gaps**:
   - Modules with robust coverage: `bitacora`, `ponds_batches`, `finance_payroll`, `water_quality`.
   - Modules with 0 test coverage: `auth_tenant`, `ica_compliance`, `sales_harvest`, `warehouse_inventory`, `equipment_capex`, `offline_sync_queue`.
   - Adding unit and widget tests for these modules will raise overall coverage across the entire 11-module ERP.

---

## 3. Caveats

1. **Native Platform Folders**: The repository root does not currently contain generated native runner directories (`android/`, `ios/`, `windows/`). Native release builds (AAB, APK, IPA) will require running `flutter create . --platforms=android,ios` and configuring ProGuard/R8, `build.gradle`, and `Info.plist`.
2. **Read-Only Scope**: This report is purely an exploratory investigation and diagnostic action plan; no modifications have been made to project source files.

---

## 4. Conclusion

The `fishbit_finance` codebase has a clean, well-architected foundation (Riverpod 2.5, GoRouter 14, Supabase Flutter 2.5, Glassmorphic Design System). However, to achieve production release hardening and enterprise QA compliance, the following high-priority remediations are required:

### High-Priority Remediation Checklist:
1. **Fix Unsafe Type Casting in Domain Models**:
   - Update `BiometriaRecord.fromJson` and `MortalityRecord.fromJson` from `(raw as num?)` to safe `is num ? raw.toInt() : int.tryParse(...)`.
2. **Harden `analysis_options.yaml`**:
   - Enable `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`.
   - Enable essential linter rules: `unawaited_futures`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`, `discarded_futures`, `avoid_web_libraries_in_flutter`.
3. **Decouple Secrets to Environment Variables**:
   - Migrate `main.dart` Supabase initialization to `const String.fromEnvironment('SUPABASE_URL')` and `const String.fromEnvironment('SUPABASE_ANON_KEY')`.
4. **Wire `flutter_secure_storage`**:
   - Update `LocalStorageService` to use `FlutterSecureStorage` for session tokens and credentials.
5. **Add Global Error Boundaries**:
   - Implement `FlutterError.onError = ...` and `PlatformDispatcher.instance.onError = ...` in `main.dart`.
6. **Expand Test Coverage to Untested Modules**:
   - Add unit tests for `auth_provider`, `ica_official_reports_engine`, `ica_compliance_provider`, `sales_provider`, `warehouse_provider`, `offline_sync_queue`.
7. **Clean Assets & Web Manifest**:
   - Remove empty asset directory declarations (`assets/icons/`, `assets/images/`) or populate them.
   - Update `web/manifest.json` with FishBit app description and theme colors.

---

## 5. Verification Method

To independently verify the status and validate future improvements:

1. **Static Analysis Verification**:
   ```bash
   flutter analyze --no-fatal-infos
   ```
   *Pass criteria*: 0 errors, 0 warnings.

2. **Test Suite Verification**:
   ```bash
   flutter test --coverage
   ```
   *Pass criteria*: All 10 existing test suites pass at 100%.

3. **Production Web Release Compilation**:
   ```bash
   flutter build web --release --tree-shake-icons --dart-define=SUPABASE_URL=https://oakovawlwjpnoydpwtam.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
   *Pass criteria*: `build/web/` generates without errors or asset missing warnings.

4. **Production Android AAB Release Compilation (when native runner is generated)**:
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
   ```
   *Pass criteria*: Generates obfuscated `.aab` bundle with symbols separated.
