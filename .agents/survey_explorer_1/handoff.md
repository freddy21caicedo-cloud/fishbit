# Handoff Report: Survey Explorer 1 — Security & Multi-Tenancy (R1)

**Agent Identity:** Survey Explorer 1 - Security  
**Workspace:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit`  
**Working Directory:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_1`  
**Date:** 2026-09-13T23:45:00Z  
**Scope:** Requirement R1 (SEC-01, SEC-02, SEC-03) — Supabase credentials in `lib/main.dart`, multi-tenant isolation and `OR empresa_id IS NULL` in SQL migrations, user/team creation security, admin validation, and credential handling.

---

## 1. Observation

### 1.1 Hardcoded Supabase Credentials & Configuration in `lib/main.dart`
- **File:** `lib/main.dart`
- **Exact Lines:** 32–47
- **Direct Code Quote:**
```dart
32:  // 3. Inicializar Supabase con inyección de variables de entorno (--dart-define)
33:  const supabaseUrl = String.fromEnvironment(
34:    'SUPABASE_URL',
35:    defaultValue: 'https://oakovawlwjpnoydpwtam.supabase.co',
36:  );
37:  const supabaseAnonKey = String.fromEnvironment(
38:    'SUPABASE_ANON_KEY',
39:    defaultValue:
40:        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ha292YXdsd2pwbm95ZHB3dGFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc5MDQ3NTksImV4cCI6MjA5MzQ4MDc1OX0.Hd-yeZaNvZtjd7inkhwcF3IVWWKRC8Sd9nGHeItmFVw',
41:  );
42:
43:  await Supabase.initialize(
44:    url: supabaseUrl,
45:    // ignore: deprecated_member_use
46:    anonKey: supabaseAnonKey,
47:  );
```
- **Context & Mechanisms Observed:**
  - `String.fromEnvironment('SUPABASE_URL', defaultValue: ...)` and `String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ...)` embed active production Supabase project URL (`https://oakovawlwjpnoydpwtam.supabase.co`) and anon JWT token into binary string tables as fallback constants.
  - No assertion or non-empty validation exists before calling `await Supabase.initialize()`.
  - `pubspec.yaml` does not declare `flutter_dotenv`; compilation relies exclusively on `--dart-define` / `String.fromEnvironment`.
  - No `.env.example` or local config template exists in the repository.

---

### 1.2 Supabase RLS Policies & Vulnerable Condition `OR empresa_id IS NULL`
- **File:** `supabase_migration_v10_canonical_v2.sql`
- **Exact Lines:** 247–286
- **Direct Code Quote:**
```sql
247: CREATE POLICY "units_tenant_isolation" ON public.units
248: FOR ALL TO authenticated
249: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
250: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
251: 
252: CREATE POLICY "estanques_tenant_isolation" ON public.estanques
253: FOR ALL TO authenticated
254: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
255: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
256: 
257: CREATE POLICY "inventory_tenant_isolation" ON public.inventory
258: FOR ALL TO authenticated
259: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
260: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
261: 
262: CREATE POLICY "providers_tenant_isolation" ON public.providers
263: FOR ALL TO authenticated
264: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
265: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
266: 
267: CREATE POLICY "siembras_tenant_isolation" ON public.siembras
268: FOR ALL TO authenticated
269: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
270: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
271: 
272: CREATE POLICY "water_quality_tenant_isolation" ON public.water_quality
273: FOR ALL TO authenticated
274: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
275: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
276: 
277: CREATE POLICY "biometrias_tenant_isolation" ON public.biometrias
278: FOR ALL TO authenticated
279: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
280: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
281: 
282: CREATE POLICY "mortality_tenant_isolation" ON public.mortality
283: FOR ALL TO authenticated
284: USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)
285: WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());
```
- **Catalog of All 8 Affected Transactional Tables:**
  1. `public.units` (`units_tenant_isolation`, Line 247)
  2. `public.estanques` (`estanques_tenant_isolation`, Line 252)
  3. `public.inventory` (`inventory_tenant_isolation`, Line 257)
  4. `public.providers` (`providers_tenant_isolation`, Line 262)
  5. `public.siembras` (`siembras_tenant_isolation`, Line 267)
  6. `public.water_quality` (`water_quality_tenant_isolation`, Line 272)
  7. `public.biometrias` (`biometrias_tenant_isolation`, Line 277)
  8. `public.mortality` (`mortality_tenant_isolation`, Line 282)

- **Observations in Other Migration Files:**
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql`:
    - Does NOT have `OR empresa_id IS NULL`. Its policies enforce `(empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()))`.
    - However, lines 443–455 (`profiles_tenant_isolation_update`) allow any authenticated user to update their own row in `public.profiles` (`id = (SELECT auth.uid())`) without restricting updates on columns `role`, `is_superadmin`, or `empresa_id` (**SEC-01**).
    - Line 52 hardcodes `OR LOWER(email) = 'especialistaacuicola@gmail.com'`.
  - `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql`:
    - Lines 222 & 306 contain `WHERE b.empresa_id IS NULL` only in one-time historical data synchronization statements, not in policy definitions.
  - `supabase_data_sync_legacy_to_v2.sql`:
    - Lines 68, 72, 77 contain `WHERE empresa_id IS NULL` for one-time default tenant assignment.

---

### 1.3 User & Team Member Creation Logic, Credentials & Permissions
- **File:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart`

1. **Vulnerability SEC-02: Authentication Bypass in `signInWithEmailPassword` (Lines 117–134, 184–202):**
```dart
118:    try {
119:      AuthResponse? authRes;
120:      try {
121:        authRes = await _supabase.auth.signInWithPassword(email: cleanEmail, password: cleanPassword);
122:      } catch (authError) {
123:        // Si no pudo autenticar en Supabase Auth, verificar si existe en miembros_equipo
124:        final memberCheck = await _supabase
125:            .from('miembros_equipo')
126:            .select('id')
127:            .eq('email', cleanEmail)
128:            .maybeSingle();
129:
130:        if (memberCheck == null) {
131:          throw AuthFailure('Credenciales incorrectas: ${authError.toString()}');
132:        }
133:      }
134:
...
184:      // Consultar tabla miembros_equipo (fallback)
185:      final memberRow = await _supabase
186:          .from('miembros_equipo')
187:          .select('*')
188:          .eq('email', cleanEmail)
189:          .maybeSingle();
190:
191:      if (memberRow != null) {
192:        final member = UserMember.fromJson({
193:          ...memberRow,
194:          'empresa_id': memberRow['empresa_id'],
195:        });
196:        await _storage.setSessionUserId(member.id);
197:        if (member.unidadAcuicolaId != null) {
198:          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
199:        }
200:        return member;
201:      }
```
If an invalid password is provided, but `cleanEmail` exists in `miembros_equipo`, the error is swallowed and the user is logged in without authentication!

2. **Vulnerability SEC-03: Invitation Backdoor in `registerWithInvitationToken` (Lines 738–763):**
```dart
738:  @override
739:  Future<UserMember> registerWithInvitationToken(String token, String password) async {
740:    try {
741:      final res = await _supabase
742:          .from('miembros_equipo')
743:          .select('*')
744:          .eq('token_invitacion', token.trim())
745:          .eq('estado', 'Invitado')
746:          .maybeSingle();
747:
748:      if (res == null) {
749:        // Mock fallback para tokens de prueba
750:        final mockUser = UserMember(
751:          id: const Uuid().v4(),
752:          empresaId: 'c1000000-0000-0000-0000-000000000001',
753:          unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
754:          nombre: 'Usuario Activado',
755:          email: 'invitado@fishbit.com',
756:          role: UserRole.technician,
757:          permisoGlobalEmpresa: false,
758:          estado: MemberStatus.active,
759:          creadoEn: DateTime.now(),
760:        );
761:        await _storage.setSessionUserId(mockUser.id);
762:        return mockUser;
763:      }
```
Any arbitrary or expired token grants full session access to company `'c1000000-0000-0000-0000-000000000001'`.

3. **Flaws in `createTeamMember` (Lines 634–706):**
```dart
634:  Future<UserMember> createTeamMember({
635:    required String empresaId,
636:    required String nombre,
637:    required String email,
638:    required String cedula,
639:    required String telefono,
640:    required UserRole role,
641:    String? unidadAcuicolaId,
642:    bool permisoGlobalEmpresa = false,
643:    double salarioBase = 0.0,
644:    String periodoPago = 'Quincenal',
645:    required String password,
646:  }) async {
...
664:    try {
665:      // 1. Guardar en miembros_equipo
666:      await _supabase.from('miembros_equipo').insert(newMember.toJson());
667:
668:      // 2. Intentar registrar en Supabase Auth y Profiles
669:      try {
670:        final authRes = await _supabase.auth.signUp(
671:          email: cleanEmail, 
672:          password: password.trim(),
...
689:      } catch (_) {
690:        // Si signUp requiere confirmación de email o falla, guardar en profiles con el memberId
691:        try {
692:          await _supabase.from('profiles').upsert({
693:            'id': memberId, // random Uuid, unlinked to auth.users!
...
703:    } catch (_) {}
704:
705:    return newMember;
```
  - **No Permission Check:** Neither `supabase_auth_repository.dart`, `auth_provider.dart:302-338`, nor `crear_colaborador_modal.dart` checks whether the current user is an admin (`state.currentUser?.isAdmin`).
  - **Error Swallowing:** Line 703 suppresses all exceptions (`catch (_) {}`), returning `newMember` even if PostgreSQL RLS rejects the insert.
  - **Client-Side `signUp` Session Pollution:** An admin calling `_supabase.auth.signUp` from the client SDK can overwrite the current authentication session or fail if email confirmation is enabled, creating unlinked zombie profiles with synthetic UUIDs.

4. **Hardcoded Master Email:**
  - `lib/app/router.dart:51`: `final isSuperAdmin = user?.email.toLowerCase() == 'especialistaacuicola@gmail.com';`
  - `lib/modules/auth_tenant/presentation/providers/auth_provider.dart:121`: `final isSuperAdmin = user.email.toLowerCase() == 'especialistaacuicola@gmail.com';`
  - `lib/modules/auth_tenant/presentation/screens/saas_console_screen.dart:66`: `'especialistaacuicola@gmail.com • Control de Facturación'`
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:52`: `OR LOWER(email) = 'especialistaacuicola@gmail.com'`

---

## 2. Logic Chain

1. **From Observation 1.1 to Insecure Secret Management:**
   - `lib/main.dart` specifies `defaultValue: 'https://oakovawlwjpnoydpwtam.supabase.co'` and a production JWT token.
   - Anyone extracting the compiled Flutter APK, iOS IPA, or JavaScript bundle can read the Supabase URL and anonKey.
   - While `anonKey` is designed for public clients, embedding active tenant project endpoints in code without compile-time injection prevents credential rotation across environments (staging, production) and exposes the project to targeted scraping.
   - If a developer builds without `--dart-define`, the app runs against production instead of failing immediately.
   - *Therefore*, removing default fallbacks and asserting presence at application startup (`assert` + runtime `StateError`) is required to strictly enforce environment variable configuration.

2. **From Observation 1.2 to Multi-Tenant Data Leakage:**
   - In `supabase_migration_v10_canonical_v2.sql`, 8 transactional tables define policies with `USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin() OR empresa_id IS NULL)`.
   - Because `FOR ALL TO authenticated` applies to `SELECT`, `UPDATE`, and `DELETE`, any authenticated user from any tenant can read, modify, or delete any record with `empresa_id IS NULL`.
   - Any historical rows or rows inserted without `empresa_id` are exposed across all tenants.
   - Additionally, the disjunction `OR empresa_id IS NULL` disables efficient B-Tree index scans on `empresa_id`, causing PostgreSQL to fall back to Sequential Scans (as documented in `AUDIT_REPORT.md` DB-09).
   - *Therefore*, `OR empresa_id IS NULL` must be permanently eliminated from all RLS policies.

3. **From Observation 1.3 to Authentication & Authorization Compromise:**
   - In `supabase_auth_repository.dart`, `signInWithEmailPassword` swallows `AuthException` from Supabase and falls back to a plaintext record check in `miembros_equipo`.
   - Any user entering a valid email can authenticate without providing the correct password (SEC-02).
   - In `registerWithInvitationToken`, an invalid token triggers a fallback that logs into tenant `c1000000-0000-0000-0000-000000000001` (SEC-03).
   - In `createTeamMember`, an admin manually enters a password in `crear_colaborador_modal.dart`. The client attempts `_supabase.auth.signUp()`. When this fails (because the admin is already logged in), it catches the error and creates an orphaned profile with a non-auth UUID.
   - Because that orphan profile cannot log in via `_supabase.auth.signInWithPassword`, the developers introduced the SEC-02 bypass to allow them to log in anyway.
   - *Therefore*, user creation must be decoupled from client-side `signUp`, passwords must never be bypassed in `signInWithEmailPassword`, invalid tokens must throw an `AuthFailure`, and admin permissions must be validated both in UI/Riverpod and enforced via PostgreSQL RLS.

---

## 3. Caveats

1. **Test Environment Isolation:**
   - Flutter tests run in a headless environment without an active Supabase backend (`FakeAuthRepository` is used in `test/helpers/test_auth_helper.dart`). Changes to `lib/main.dart` do not impact `flutter test`.
2. **Existing Non-Auth Test Failures:**
   - `flutter test` currently reports 5 failures in `bitacora_screen_test.dart` and `warehouse_inventory_test.dart` due to UI filter expectations and casing in inventory tests. `test/modules/auth_tenant/auth_tenant_test.dart` passes 100% (9/9 passed).
3. **Database Migration State:**
   - Migrations in `supabase/migrations/` are applied to the remote PostgreSQL instance via Supabase CLI or management console. Applying RLS updates requires executing an idempotent migration script.

---

## 4. Conclusion & Remediation Plan

### 4.1 Remediation Architecture for R1 (SEC-01, SEC-02, SEC-03)

#### Component A: Hardened Supabase Startup Validation (`lib/main.dart`)
1. Remove `defaultValue` from `String.fromEnvironment('SUPABASE_URL')` and `String.fromEnvironment('SUPABASE_ANON_KEY')`.
2. Implement dual-layer startup validation:
   - `assert(supabaseUrl.isNotEmpty)` and `assert(supabaseAnonKey.isNotEmpty)` for debug builds.
   - Runtime `if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) throw StateError(...)` for release builds.
   - URL scheme validation (`Uri.tryParse(supabaseUrl)?.hasScheme == true`).
3. Provide `.env.example` documenting `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_ANON_KEY=...`.

```dart
// Proposed Implementation in lib/main.dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

assert(
  supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
  'FishBit Security Error: SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define',
);

if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
  throw StateError(
    'FishBit Configuration Error: Required environment variables SUPABASE_URL and SUPABASE_ANON_KEY '
    'are missing. Pass them via --dart-define or --dart-define-from-file at compile time.',
  );
}

final parsedUrl = Uri.tryParse(supabaseUrl);
if (parsedUrl == null || !parsedUrl.hasScheme || (!parsedUrl.isScheme('https') && !parsedUrl.isScheme('http'))) {
  throw StateError('FishBit Configuration Error: SUPABASE_URL is not a valid HTTP/HTTPS URL: $supabaseUrl');
}

await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
);
```

---

#### Component B: Strict RLS Policies Without `OR empresa_id IS NULL`
1. Modify `supabase_migration_v10_canonical_v2.sql` lines 247–285 to eliminate `OR empresa_id IS NULL`.
2. Generate a new idempotent migration file:
   `supabase/migrations/20260913_fix_sec01_sec02_multi_tenant_hardening.sql`
   - Drops and recreates policies for `units`, `estanques`, `inventory`, `providers`, `siembras`, `water_quality`, `biometrias`, `mortality`.
   - Enforces strict tenant isolation:
     `USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())`
     `WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())`
   - Enforces `BEFORE UPDATE` trigger on `public.profiles` (`trg_protect_profile_privileges`) to resolve **SEC-01** (prevent unauthorized escalation to `role = 'master'`, `is_superadmin = true`, or `empresa_id` alteration).

```sql
-- Proposed SQL Migration: supabase/migrations/20260913_fix_sec01_sec02_multi_tenant_hardening.sql
-- 1. Asegurar que no existan registros huérfanos con empresa_id NULL
UPDATE public.units SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.estanques SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.inventory SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.providers SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.siembras SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.water_quality SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.biometrias SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;
UPDATE public.mortality SET empresa_id = 'c1000000-0000-0000-0000-000000000001' WHERE empresa_id IS NULL;

-- 2. Eliminar políticas permisivas existentes
DROP POLICY IF EXISTS "units_tenant_isolation" ON public.units;
DROP POLICY IF EXISTS "estanques_tenant_isolation" ON public.estanques;
DROP POLICY IF EXISTS "inventory_tenant_isolation" ON public.inventory;
DROP POLICY IF EXISTS "providers_tenant_isolation" ON public.providers;
DROP POLICY IF EXISTS "siembras_tenant_isolation" ON public.siembras;
DROP POLICY IF EXISTS "water_quality_tenant_isolation" ON public.water_quality;
DROP POLICY IF EXISTS "biometrias_tenant_isolation" ON public.biometrias;
DROP POLICY IF EXISTS "mortality_tenant_isolation" ON public.mortality;

-- 3. Crear políticas estrictas sin cláusula NULL
CREATE POLICY "units_tenant_isolation" ON public.units
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "estanques_tenant_isolation" ON public.estanques
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "inventory_tenant_isolation" ON public.inventory
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "providers_tenant_isolation" ON public.providers
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "siembras_tenant_isolation" ON public.siembras
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "water_quality_tenant_isolation" ON public.water_quality
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "biometrias_tenant_isolation" ON public.biometrias
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

CREATE POLICY "mortality_tenant_isolation" ON public.mortality
FOR ALL TO authenticated
USING (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())
WITH CHECK (empresa_id = public.get_auth_empresa_id() OR public.is_superadmin());

-- 4. Protección contra escalada de privilegios en profiles (SEC-01)
CREATE OR REPLACE FUNCTION public.trg_protect_profile_privileges()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF (NEW.role IS DISTINCT FROM OLD.role 
      OR NEW.is_superadmin IS DISTINCT FROM OLD.is_superadmin 
      OR NEW.empresa_id IS DISTINCT FROM OLD.empresa_id) THEN
    IF NOT (SELECT public.is_superadmin()) THEN
      RAISE EXCEPTION 'FishBit Security Violation: No posee autorización para alterar roles, asignación de empresa o banderas de superadministrador.'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_profile_privilege_protection ON public.profiles;
CREATE TRIGGER trg_enforce_profile_privilege_protection
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_protect_profile_privileges();
```

---

#### Component C: Secure User & Team Member Creation and Authentication
1. **Eliminate SEC-02 Bypass in `signInWithEmailPassword`:**
   - Remove the fallback query on `miembros_equipo` that suppresses invalid password exceptions.
   - Ensure that `AuthException` from Supabase Auth is rethrown as `AuthFailure('Credenciales incorrectas: ${e.message}')`.
2. **Eliminate SEC-03 Backdoor in `registerWithInvitationToken`:**
   - Remove `mockUser` fallback. If `res == null`, throw `const AuthFailure('Token de invitación inválido o expirado.')`.
3. **Admin Verification & Safe Team Member Creation:**
   - In `auth_provider.dart` (`createTeamMember`), check `final currentUser = state.currentUser; if (currentUser == null || (!currentUser.isAdmin && !currentUser.isCreator)) throw const AuthFailure('Permisos insuficientes: solo administradores pueden crear colaboradores.');`
   - In `crear_colaborador_modal.dart`, hide or disable registration actions if the current user is not an admin, and display explicit validation messages.
   - Do not suppress errors with empty `catch (_) {}`. Wrap errors with typed `AppFailure` / `ServerFailure` to bubble issues to the user.
   - For credentials: use invitation token or Supabase Auth invite. When creating a member directly, if client-side `signUp` is executed, ensure errors are caught and communicated to the admin (e.g. password too weak, user already exists) instead of silently creating detached records in `profiles`.

---

## 5. Verification Method

### Independent Verification Commands:
1. **Verify Static Analysis:**
   ```powershell
   flutter analyze --no-fatal-infos
   ```
   *Expected Result:* `No issues found!`

2. **Verify Auth Tenant Test Suite:**
   ```powershell
   flutter test test/modules/auth_tenant/auth_tenant_test.dart
   ```
   *Expected Result:* `All tests passed!` (9/9 passing).

3. **Verify Absence of Hardcoded Credentials in Codebase:**
   ```powershell
   rg "oakovawlwjpnoydpwtam" lib/
   rg "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" lib/
   rg "OR empresa_id IS NULL" supabase_migration_v10_canonical_v2.sql
   rg "OR LOWER\(email\) = 'especialistaacuicola@gmail.com'" lib/ supabase/
   ```
   *Expected Result:* 0 matches across active production files.

4. **Verify Startup Assertion:**
   - Running `flutter run` without `--dart-define=SUPABASE_URL=...` should fail immediately with `StateError` describing the missing required environment variables.
