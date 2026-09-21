# Comprehensive Architecture, Backend & Security Audit Report
**Project:** FishBit Finance 2.0 (Precision Aquaculture ERP & Biological Traceability)  
**Target:** Flutter Web/Mobile Frontend & Supabase (PostgreSQL 15+ / Auth / Storage / Edge Functions)  
**Auditor:** Teamwork Architecture, Backend & Security Explorer (`explorer_arch_sec_2`)  
**Audit Date:** September 13, 2026  
**Status:** Complete  
**Integrity Mode:** Strictly Analytical & Advisory (Read-Only)

---

## Executive Summary

A deep-dive investigation was conducted across the FishBit application codebase, covering the architectural layers (`lib/core/`, `lib/modules/`, `lib/app/`), state management integration (Riverpod), persistence, authentication flows, and backend database definitions (`supabase/migrations/` and SQL schema definitions).

### Key Metrics & Posture Overview
- **Total Findings:** 22 (2 Critical, 8 High, 9 Medium, 3 Low)
- **Primary Attack Vectors Identified:**
  1. **Privilege Escalation (SEC-01):** PostgreSQL RLS update policy on `public.profiles` allows any authenticated user to update their own role to `'master'`/`'admin'` and set `is_superadmin = true`.
  2. **Full Authentication Bypass (SEC-02):** Unchecked exception handling in `signInWithEmailPassword` logs in any user without a valid password if their email exists in `miembros_equipo`.
  3. **Invitation Token Backdoor (SEC-03):** Random or invalid invitation tokens trigger a hardcoded active technician session for mock tenant `c1000000-0000-0000-0000-000000000001`.
  4. **PII and Sensitive Data Leakage (SEC-05):** Real Colombian aquaculture commercial clients, personal emails, NITs, and annual subscription prices hardcoded in Dart client files.
  5. **Cross-Tenant Application Leaks (ARCH-01):** Multiple core repositories (`registros_nomina`, `mantenimientos`, `equipos`, `facturas`) omit `empresa_id` filters in Supabase client queries.
  6. **Pervasive Error Swallowing & Silent Failures (ARCH-02):** Over 25 empty `catch (_) {}` blocks across repositories that hide database constraint failures, network disconnects, and RLS rejections, leading to in-memory/database desynchronization.

---

## Audit Findings Matrix

| Finding ID | Category | Severity | Component / Layer | Summary |
|---|---|---|---|---|
| **SEC-01** | Security | **Critical** | Supabase RLS Policy (`profiles`) | Privilege Escalation to Superadmin/Master via Row Mutation |
| **SEC-02** | Security | **Critical** | Auth Repository (`auth_tenant`) | Authentication Bypass in `signInWithEmailPassword` |
| **SEC-03** | Security | **High** | Auth Repository (`auth_tenant`) | Hardcoded Backdoor Fallback in `registerWithInvitationToken` |
| **SEC-04** | Security | **High** | Auth / Router / SQL Functions | Hardcoded Superadmin Email (`especialistaacuicola@gmail.com`) |
| **SEC-05** | Security | **High** | Presentation (`saas_console_screen`) | Real Commercial Customer PII & Contract Data Hardcoded in Source |
| **SEC-06** | Security | **High** | Supabase Migrations (`plpgsql`) | `SECURITY DEFINER` Functions Missing Explicit `search_path` |
| **SEC-07** | Security | **High** | Auth Repository (`auth_tenant`) | Omission of `empresa_id` in Unit Creation SQL Payload |
| **SEC-08** | Security | **Medium** | Routing & Presentation Layer | Client-Side Security Through Obscurity in RBAC & Admin Routes |
| **SEC-09** | Security | **Medium** | Core Storage / Auth Bootstrap | Unencrypted Supabase Session Tokens (Unwired `FlutterSecureStorage`) |
| **SEC-10** | Security | **Medium** | Bootstrap (`main.dart`) | Hardcoded Fallback Supabase Production URL & Anon Key |
| **SEC-11** | Security | **Low** | Core Error Boundaries | Verbose Stack Trace and Platform Error Logging to Console |
| **ARCH-01** | Architecture | **High** | Repositories (`finance`, `equipment`, `warehouse`) | Omission of `empresa_id` Filter in Supabase Database Queries |
| **ARCH-02** | Architecture | **High** | Repositories & State Notifiers | Pervasive Empty Catch Blocks Masking Write Failures |
| **ARCH-03** | Architecture | **High** | Repository (`feeding_nutrition`) | Race Condition & Lost Updates in Client-Side Stock Decrement |
| **ARCH-04** | Architecture | **High** | Infrastructure / Migrations | Missing Database RPC `setup_company_for_user` in Migrations |
| **ARCH-05** | Architecture | **Medium** | Database / Domain Schema | Dual Schema / Split-Brain Anti-Pattern (Legacy vs Canonical v10) |
| **ARCH-06** | Architecture | **Medium** | Presentation Layer | Monolithic Presentation God-Classes (`BitacoraScreen`, `IcaReportsEngine`) |
| **ARCH-07** | Architecture | **Medium** | Core Storage / Offline Engine | Dead Code in `OfflineSyncQueue` & Ad-Hoc Local Cache Leak |
| **ARCH-08** | Architecture | **Medium** | Navigation (`register_company_screen`) | Broken Navigation Target Route (`/home` instead of `/`) |
| **ARCH-09** | Architecture | **Medium** | Core Reports Engine | Non-Functional Mobile File Export in ICA Compliance Engine |
| **ARCH-10** | Architecture | **Low** | Design System & Core Storage | Dual Conflicting Theme Persistence Implementations |
| **ARCH-11** | Architecture | **Low** | Presentation (`login_screen`) | Decorative Unwired "Recordarme" Toggle in Login Form |

---

## Detailed Findings & Actionable Remediations

### SEC-01: Critical Privilege Escalation via Insecure `profiles` RLS Update Policy
- **Severity:** Critical
- **Affected File:** `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Lines 443–455)
- **Vulnerability Explanation:**
  The RLS policy `profiles_tenant_isolation_update` allows any authenticated user to update their own profile row based on `id = (SELECT auth.uid())`:
  ```sql
  CREATE POLICY profiles_tenant_isolation_update ON public.profiles
    FOR UPDATE TO authenticated
    USING (
      id = (SELECT auth.uid()) 
      OR (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
      OR (SELECT public.is_superadmin())
    )
    WITH CHECK (
      id = (SELECT auth.uid()) 
      OR ...
  ```
  PostgreSQL Row-Level Security checks row visibility, not individual columns. Because there is no column-level grant restriction or `BEFORE UPDATE` trigger on `public.profiles`, any authenticated user (such as a farm operator or field technician) can issue an update command via the Supabase client:
  ```dart
  await supabase.from('profiles').update({
    'role': 'master',
    'is_superadmin': true,
    'empresa_id': '<target-tenant-uuid>',
  }).eq('id', supabase.auth.currentUser!.id);
  ```
  Since `public.is_superadmin()`, `public.get_auth_user_role()`, and `public.get_auth_empresa_id()` read `role`, `is_superadmin`, and `empresa_id` directly from `public.profiles WHERE id = auth.uid()`, this allows an attacker to gain full global administrative privileges and access/alter all tenant records across the database.
- **Impact:** Total compromise of authorization model, cross-tenant data leakage, and database takeover by any authenticated user.
- **Proposed Fix:**
  Implement a strict `BEFORE UPDATE` trigger on `public.profiles` that prohibits standard users from altering `role`, `is_superadmin`, or `empresa_id`:
  ```sql
  CREATE OR REPLACE FUNCTION public.trg_protect_profile_privileges()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
  BEGIN
    -- Only existing superadmins are allowed to promote roles or reassign empresas
    IF (NEW.role <> OLD.role OR NEW.is_superadmin <> OLD.is_superadmin OR NEW.empresa_id <> OLD.empresa_id) THEN
      IF NOT (SELECT public.is_superadmin()) THEN
        RAISE EXCEPTION 'FishBit Security: No está autorizado para modificar privilegios, roles o asignación de empresa.';
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

### SEC-02: Critical Authentication Bypass in `signInWithEmailPassword`
- **Severity:** Critical
- **Affected File:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Lines 117–134, 184–202)
- **Vulnerability Explanation:**
  In `signInWithEmailPassword`, the method attempts `_supabase.auth.signInWithPassword`. If the credentials are invalid, Supabase Auth throws an `AuthException`. However, the catch block intercepts this exception:
  ```dart
  try {
    authRes = await _supabase.auth.signInWithPassword(email: cleanEmail, password: cleanPassword);
  } catch (authError) {
    // Si no pudo autenticar en Supabase Auth, verificar si existe en miembros_equipo
    final memberCheck = await _supabase
        .from('miembros_equipo')
        .select('id')
        .eq('email', cleanEmail)
        .maybeSingle();

    if (memberCheck == null) {
      throw AuthFailure('Credenciales incorrectas: ${authError.toString()}');
    }
  }
  ```
  If `memberCheck != null` (meaning the email exists in `miembros_equipo`), the catch block **exits without rethrowing**. Execution continues to lines 184–202, which query `miembros_equipo` for that email, set `_storage.setSessionUserId(member.id)`, and return the user object as authenticated.
- **Impact:** Any individual can log in as any employee by entering their email address and typing any random, incorrect password. Furthermore, because Supabase Auth failed, `supabase.auth.currentSession` remains unauthenticated, leaving the client in a broken state that triggers RLS permission errors or forces fallback to unauthenticated mock data.
- **Proposed Fix:**
  Remove the unsafe fallback in `signInWithEmailPassword`. Any failure in `signInWithPassword` must terminate the sign-in flow and rethrow `AuthFailure`:
  ```dart
  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final authRes = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = authRes.user;
      if (user == null) {
        throw const AuthFailure('No se pudo establecer sesión con el servidor.');
      }

      final profileRow = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow != null) {
        final member = UserMember.fromJson(profileRow);
        await _storage.setSessionUserId(member.id);
        if (member.unidadAcuicolaId != null) {
          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
        }
        return member;
      }

      throw const AuthFailure('Perfil de usuario no configurado.');
    } on AuthException catch (e) {
      throw AuthFailure('Credenciales incorrectas: ${e.message}');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Error durante autenticación: $e');
    }
  }
  ```

---

### SEC-03: Hardcoded Backdoor Invitation Token & Cross-Tenant Mock Fallback
- **Severity:** High
- **Affected File:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Lines 740–763)
- **Vulnerability Explanation:**
  In `registerWithInvitationToken(String token, String password)`:
  ```dart
  if (res == null) {
    // Mock fallback para tokens de prueba
    final mockUser = UserMember(
      id: const Uuid().v4(),
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      nombre: 'Usuario Activado',
      email: 'invitado@fishbit.com',
      role: UserRole.technician,
      permisoGlobalEmpresa: false,
      estado: MemberStatus.active,
      creadoEn: DateTime.now(),
    );
    await _storage.setSessionUserId(mockUser.id);
    return mockUser;
  }
  ```
  If a token is invalid, expired, or non-existent in the database, instead of rejecting the attempt, the application grants an active session assigned to `c1000000-0000-0000-0000-000000000001` with `UserRole.technician`.
- **Impact:** An unauthorized user can bypass invitation verification by entering any arbitrary string and gain functional access to the app and its mock/demo data.
- **Proposed Fix:**
  Throw an `AuthFailure` when the token is not found or is expired:
  ```dart
  if (res == null) {
    throw const AuthFailure('El token de invitación es inválido o no existe.');
  }
  final expiraStr = res['token_invitacion_expira'] as String?;
  if (expiraStr != null && DateTime.parse(expiraStr).isBefore(DateTime.now())) {
    throw const AuthFailure('El enlace de invitación ha expirado.');
  }
  ```

---

### SEC-04: Hardcoded Superadmin Email in Client & Database Functions
- **Severity:** High
- **Affected Files:**
  - `lib/modules/auth_tenant/presentation/providers/auth_provider.dart` (Line 121)
  - `lib/app/router.dart` (Line 51)
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Line 52)
- **Vulnerability Explanation:**
  The address `especialistaacuicola@gmail.com` is hardcoded in client routing guards, state providers, and the PostgreSQL `is_superadmin()` definition:
  ```sql
  (SELECT is_superadmin OR LOWER(role) IN ('creador', 'master', 'billingadmin') OR LOWER(email) = 'especialistaacuicola@gmail.com' 
   FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1)
  ```
- **Impact:**
  - Rigid coupling to an individual's personal email.
  - If the account email is modified or transferred, platform-wide administrative functions break.
  - Relying on email string matching in SQL functions bypasses cryptographic role verification in JWTs.
- **Proposed Fix:**
  Enforce superadmin permissions via Supabase Auth custom claims (`raw_app_meta_data->>'is_superadmin' = 'true'`) or a dedicated `system_administrators` table:
  ```sql
  CREATE OR REPLACE FUNCTION public.is_superadmin()
  RETURNS BOOLEAN
  LANGUAGE sql
  STABLE SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
    SELECT COALESCE(
      ((SELECT auth.jwt() -> 'app_metadata' ->> 'is_superadmin')::boolean),
      (SELECT is_superadmin FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1),
      false
    );
  $$;
  ```

---

### SEC-05: Real Customer PII and Commercial Data Hardcoded in Source Code
- **Severity:** High
- **Affected File:** `lib/modules/auth_tenant/presentation/screens/saas_console_screen.dart` (Lines 21–24, 270–288)
- **Vulnerability Explanation:**
  The source code contains real commercial entity records:
  ```dart
  // Cliente 1: Los Compadres
  _buildCompanyControlCard(
    companyId: '3500cc63-5477-4f83-b4a3-7758b7cd6509',
    name: 'Piscícola Los Compadres',
    nit: '901.530.907-1',
    adminEmail: 'piscicolaloscompadres@gmail.com',
    planPrice: '400.000 COP / año',
    renewalDate: '15 Dic 2026',
  ),
  // Cliente 2: Aquarium II
  _buildCompanyControlCard(
    companyId: '54dedaac-9099-475a-8bfc-635ef8494c2a',
    name: 'Aquarium II',
    nit: '109.215.401-2',
    adminEmail: 'joyolgutierrojas83@gmail.com',
    planPrice: '400.000 COP / año',
    renewalDate: '20 Ene 2027',
  ),
  ```
- **Impact:** Serious compliance and privacy violation under Colombian Data Protection Law (Ley 1581 de 2012) and international standards. Anyone decompiling or inspecting the app assets can view customer identities, corporate tax IDs, direct contact emails, and commercial subscription terms.
- **Proposed Fix:**
  Purge all hardcoded client records from Dart files. Fetch subscriber metrics and company records dynamically from an admin-only database view via an authenticated provider.

---

### SEC-06: PostgreSQL `SECURITY DEFINER` Functions Missing Explicit `search_path`
- **Severity:** High
- **Affected File:** `supabase/migrations/20260831_cost_security_and_immutability.sql` (Lines 53–57, 94–98, 125–129)
- **Vulnerability Explanation:**
  The trigger functions `fn_prevent_harvested_lot_mutation()`, `fn_enforce_payroll_immutability()`, and `fn_record_cost_audit_log()` are declared as `SECURITY DEFINER` without setting `search_path`:
  ```sql
  CREATE OR REPLACE FUNCTION public.fn_prevent_harvested_lot_mutation()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $$ ...
  ```
  PostgreSQL documentation and Supabase Security Advisories state that `SECURITY DEFINER` functions run with the privileges of the function owner (typically `postgres` or `supabase_admin`). Without a fixed `search_path`, an attacker can manipulate the search path to invoke malicious functions or operators.
- **Impact:** Potential schema hijacking and privilege escalation within PostgreSQL.
- **Proposed Fix:**
  Add `SET search_path = public, pg_temp` to all security definer functions:
  ```sql
  ALTER FUNCTION public.fn_prevent_harvested_lot_mutation() SET search_path = public, pg_temp;
  ALTER FUNCTION public.fn_enforce_payroll_immutability() SET search_path = public, pg_temp;
  ALTER FUNCTION public.fn_record_cost_audit_log() SET search_path = public, pg_temp;
  ```

---

### SEC-07: Missing `empresa_id` in Unit Creation SQL Payload
- **Severity:** High
- **Affected File:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Lines 600–608)
- **Vulnerability Explanation:**
  In `createUnit(String empresaId, String nombre, String sigla, String? ubicacion)`:
  ```dart
  final res = await _supabase
      .from('unidades_acuicolas')
      .insert({
        'nombre': nombre,
        'sigla': sigla.toUpperCase(),
        'ubicacion': ubicacion,
      })
      .select()
      .single();
  ```
  The parameter `empresaId` is accepted but omitted from the JSON payload inserted into `unidades_acuicolas`.
- **Impact:**
  - If the database allows `empresa_id` to be null, the new unit becomes an orphaned unit unlinked to the company.
  - If RLS or NOT NULL constraints enforce `empresa_id`, the insert fails, triggering the empty catch block at line 612 and returning a phantom in-memory unit that is never stored in Supabase.
- **Proposed Fix:**
  Include `'empresa_id': empresaId` in the map:
  ```dart
  .insert({
    'empresa_id': empresaId,
    'nombre': nombre,
    'sigla': sigla.toUpperCase(),
    'ubicacion': ubicacion,
  })
  ```

---

### SEC-08: Client-Side Security Through Obscurity in RBAC & Admin Routes
- **Severity:** Medium
- **Affected Files:**
  - `lib/app/router.dart` (Lines 102–138)
  - `lib/core/design_system/glass_action_hub_sheet.dart` (Lines 142–165)
  - `lib/modules/finance_payroll/presentation/screens/finance_screen.dart` (Lines 1–100)
  - `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart` (Lines 1–35)
- **Vulnerability Explanation:**
  Role restrictions are enforced solely by hiding navigation tiles in `GlassActionHubSheet` (`if (isAdmin)`). The router (`router.dart`) contains zero role validation for routes `/finance`, `/team`, and `/sales`. Any authenticated user with role `operator` or `technician` can navigate directly to `/finance` or `/team` (e.g. via browser URL in Flutter Web, deep link, or modified client state), viewing all payroll data, team members, and invoking payroll or collaborator creation modals.
- **Impact:** Unauthorized access to corporate financial statements, salaries, and personnel directories by field staff.
- **Proposed Fix:**
  Add a role-checking guard in `router.dart` redirect logic:
  ```dart
  final role = user?.role;
  final isAdmin = role == UserRole.admin || role == UserRole.creator;

  if (!isAdmin && (state.matchedLocation == '/finance' || state.matchedLocation == '/team')) {
    return '/'; // Deny access and redirect to home
  }
  ```

---

### SEC-09: Unencrypted Supabase Session Tokens in Plaintext SharedPreferences
- **Severity:** Medium
- **Affected Files:**
  - `lib/core/storage/local_storage_service.dart` (Lines 45–59)
  - `lib/main.dart` (Lines 43–47)
- **Vulnerability Explanation:**
  `LocalStorageService` instantiates `FlutterSecureStorage`, but its secure methods are never called. `Supabase.initialize` in `main.dart` is called without providing custom `authOptions`:
  ```dart
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  ```
  By default, `supabase_flutter` persists session JWTs and refresh tokens using standard unencrypted `SharedPreferences` (or `localStorage` on Web).
- **Impact:** Refresh tokens and access JWTs can be extracted from device file backups or rooted/jailbroken devices.
- **Proposed Fix:**
  Pass a secure storage implementation to `Supabase.initialize`:
  ```dart
  class SecureSupabaseLocalStorage extends LocalStorage {
    final FlutterSecureStorage _storage = const FlutterSecureStorage();
    @override
    Future<void> initialize() async {}
    @override
    Future<String?> accessToken() => _storage.read(key: supabasePersistSessionKey);
    @override
    Future<void> persistSession(String persistSessionString) =>
        _storage.write(key: supabasePersistSessionKey, value: persistSessionString);
    @override
    Future<void> removePersistedSession() =>
        _storage.delete(key: supabasePersistSessionKey);
    @override
    Future<bool> hasAccessToken() => _storage.containsKey(key: supabasePersistSessionKey);
  }
  ```
  And initialize with:
  ```dart
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthOptions(
      localStorage: SecureSupabaseLocalStorage(),
      authFlowType: AuthFlowType.pkce,
    ),
  );
  ```

---

### SEC-10: Hardcoded Fallback Supabase Production URL & Anon Key
- **Severity:** Medium
- **Affected File:** `lib/main.dart` (Lines 33–41)
- **Vulnerability Explanation:**
  The production Supabase URL `https://oakovawlwjpnoydpwtam.supabase.co` and valid project anon key are hardcoded as default fallbacks in `String.fromEnvironment`:
  ```dart
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oakovawlwjpnoydpwtam.supabase.co',
  );
  ```
- **Impact:** Any build without explicit `--dart-define` flags automatically connects to the production database environment, preventing proper environment segregation (Development vs Staging vs Production).
- **Proposed Fix:**
  Require environment definitions during compilation; assert that keys are supplied when building for specific targets.

---

### SEC-11: Unhandled Platform Error Stack Traces and Verbose Debug Logs
- **Severity:** Low
- **Affected File:** `lib/main.dart` (Lines 14–26)
- **Vulnerability Explanation:**
  `FlutterError.onError` and `PlatformDispatcher.instance.onError` print raw exceptions and stack traces to standard output using `debugPrint`:
  ```dart
  debugPrint('Uncaught Asynchronous Platform Error: $error');
  debugPrint('Stack: $stack');
  ```
- **Impact:** In web or desktop production builds, verbose system logs can expose internal paths, table schemas, and query parameters to the browser console.
- **Proposed Fix:**
  Wrap debug logs in `if (kDebugMode)` and integrate a centralized crash reporting service (e.g. Sentry) for release builds.

---

### ARCH-01: Multi-Tenancy Filter Omission in Repositories (Defense-in-Depth Breakdown)
- **Severity:** High
- **Affected Files:**
  - `lib/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart` (Lines 23–35, 110–120)
  - `lib/modules/equipment_capex/infrastructure/repositories/supabase_equipment_repository.dart` (Lines 48–52)
  - `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart` (Lines 124–127)
  - `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` (Lines 77–85)
- **Problem & Root Cause:**
  In multiple repositories, methods take `empresaId` as a parameter but fail to include `.eq('empresa_id', empresaId)` in the query:
  ```dart
  // supabase_finance_repository.dart:
  var query = _supabase.from('registros_nomina').select('*');
  if (unidadAcuicolaId.isNotEmpty) {
    query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
  }
  final res = await query.order('fecha_pago', ascending: false).limit(100);
  ```
  And in `supabase_equipment_repository.dart`:
  ```dart
  var query = _supabase.from('equipos').select('*');
  if (unidadAcuicolaId.isNotEmpty) {
    query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
  }
  ```
- **Impact:**
  - Violates the defense-in-depth principle.
  - If a unit sigla is shared across companies (e.g. `'PRIN'` or `'CAR'`), or if RLS policies are modified during maintenance, records from other companies are returned to the client.
- **Proposed Fix:**
  Always apply the tenant filter first:
  ```dart
  var query = _supabase.from('registros_nomina').select('*').eq('empresa_id', empresaId);
  ```

---

### ARCH-02: Pervasive Empty Catch Blocks Masking Write Failures
- **Severity:** High
- **Affected Files:**
  - `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart`
  - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` (Lines 90–97)
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (Lines 238, 250)
  - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` (Lines 122, 153)
- **Problem & Root Cause:**
  Operations catch all exceptions and ignore them:
  ```dart
  try {
    await _supabase.from('ventas').insert(ventaPayload);
  } catch (_) {}

  try {
    await _supabase.from('ventas_lotes').insert(sale.toJson());
  } catch (_) {}
  ```
  The caller receives a success response and fires domain events even when both database inserts failed.
- **Impact:**
  - Data corruption between client memory and database.
  - Users assume sales and harvests were recorded when they were not.
- **Proposed Fix:**
  Propagate errors using `AppFailure` and handle them with user feedback in the UI layer.

---

### ARCH-03: Race Condition in Non-Atomic Client-Side Stock Decrement
- **Severity:** High
- **Affected File:** `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` (Lines 118–127)
- **Problem & Root Cause:**
  When recording daily feeding, inventory stock is decremented via client-side read-modify-write:
  ```dart
  final item = await _supabase.from('inventory').select('current_stock').eq('id', insumoId).maybeSingle();
  if (item != null) {
    final curr = (item['current_stock'] as num?)?.toDouble() ?? 0.0;
    final updatedStock = (curr - kgConsumidos).clamp(0.0, double.infinity);
    await _supabase.from('inventory').update({'current_stock': updatedStock}).eq('id', insumoId);
  }
  ```
  This is executed outside of a database transaction. If multiple feeding entries occur concurrently, updates will overwrite each other. Additionally, if the inventory update fails, the feeding record remains stored without stock deduction.
- **Impact:** Inventory stock drift, unrecorded consumption, and ledger inconsistency.
- **Proposed Fix:**
  Use an atomic database function or PostgreSQL trigger on `alimentacion_diaria`:
  ```sql
  CREATE OR REPLACE FUNCTION public.trg_auto_decrement_feed_stock()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
  BEGIN
    IF NEW.insumo_id IS NOT NULL THEN
      UPDATE public.inventario_insumos
      SET cantidad_actual_kg = GREATEST(0, cantidad_actual_kg - NEW.cantidad_consumida_kg)
      WHERE id = NEW.insumo_id;
    END IF;
    RETURN NEW;
  END;
  $$;

  DROP TRIGGER IF EXISTS trg_feed_stock_decrement ON public.alimentacion_diaria;
  CREATE TRIGGER trg_feed_stock_decrement
    AFTER INSERT ON public.alimentacion_diaria
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_auto_decrement_feed_stock();
  ```

---

### ARCH-04: Missing Database RPC `setup_company_for_user` in Migrations
- **Severity:** High
- **Affected File:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Line 297)
- **Problem & Root Cause:**
  `setupCompanyForUser` calls:
  ```dart
  final res = await _supabase.rpc<dynamic>('setup_company_for_user', params: { ... });
  ```
  However, search across all `.sql` files in `supabase/` confirms `setup_company_for_user` is not defined in version-controlled migration scripts.
- **Impact:** If the remote Supabase project is rebuilt or spun up in a new environment, Google OAuth onboarding fails completely with "Function setup_company_for_user does not exist".
- **Proposed Fix:**
  Create and version the SQL migration implementing `setup_company_for_user` with security checks.

---

### ARCH-05: Dual-Schema / Split-Brain Anti-Pattern
- **Severity:** Medium
- **Affected Files:**
  - `supabase_schema_canonical_v10.sql`
  - `20260831_database_performance_and_rls_optimization.sql`
  - Repositories in `lib/modules/`
- **Problem & Root Cause:**
  The repository maintains two divergent schemas:
  - English tables: `units`, `inventory`, `ventas`, `siembras`
  - Canonical Spanish tables: `unidades_acuicolas`, `inventario_insumos`, `ventas_lotes`, `lotes`
  Repositories perform sequential fallback queries against both tables, doubling network round trips.
- **Impact:** Latency, schema ambiguity, and potential data fragmentation across tables.
- **Proposed Fix:**
  Complete migration from legacy English tables to the canonical Spanish v10 schema and deprecate fallback queries.

---

### ARCH-06: Monolithic Presentation God-Classes
- **Severity:** Medium
- **Affected Files:**
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (1,860 lines)
  - `lib/core/reports/ica_official_reports_engine.dart` (1,513 lines)
- **Problem & Root Cause:**
  `BitacoraScreen` contains 1,860 lines in a single file combining 4 tabs, chart rendering, modal invocation, table formatting, and form handlers. `IcaOfficialReportsEngine` contains 1,513 lines generating 12 distinct Excel reports with procedural formatting in one file.
- **Impact:** High cognitive complexity, difficult testing, high likelihood of merge conflicts, high re-render cost.
- **Proposed Fix:**
  Decompose `BitacoraScreen` into 4 dedicated tab widgets (`BitacoraAguaTab`, `BitacoraAlimentacionTab`, `BitacoraBiometriasTab`, `BitacoraBajasTab`) and extract `IcaOfficialReportsEngine` into individual report strategy classes.

---

### ARCH-07: Dead Code in Offline Sync Architecture
- **Severity:** Medium
- **Affected File:** `lib/core/storage/offline_sync_queue.dart` (Lines 51–132)
- **Problem & Root Cause:**
  `OfflineSyncQueue` was implemented as a structured offline buffer with retry counters, but is not imported or referenced anywhere in `lib/`. Instead, modules either implement ad-hoc SharedPreferences caching (ICA) or use volatile in-memory static arrays.
- **Impact:** Data entered while offline in non-ICA modules is lost on app restart.
- **Proposed Fix:**
  Integrate `OfflineSyncQueue` directly into repository mutations or implement an established local-first library (such as PowerSync or drift/sqlite).

---

### ARCH-08: Broken Navigation Route in `RegisterCompanyScreen`
- **Severity:** Medium
- **Affected File:** `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart` (Line 104)
- **Problem & Root Cause:**
  Upon successful registration, line 104 executes `context.go('/home')`. However, `router.dart` registers `/` as `HomeDashboardScreen`, not `/home`.
- **Impact:** Causes an unhandled routing exception or a 404 screen immediately after registration.
- **Proposed Fix:**
  Update line 104 to `context.go('/')`.

---

### ARCH-09: Non-Functional Mobile File Export in ICA Compliance Engine
- **Severity:** Medium
- **Affected Files:**
  - `lib/core/reports/ica_official_reports_engine.dart` (Lines 53–58)
  - `lib/core/reports/web_download_helper_stub.dart` (Lines 1–5)
- **Problem & Root Cause:**
  `_downloadExcel` only triggers when `kIsWeb` is true. On Android and iOS, `web_download_helper_stub.dart` is an empty function:
  ```dart
  void downloadFileWeb(List<int> bytes, String fileName) {
    // En plataformas móviles/escritorio se maneja a través de file_picker o share_plus
  }
  ```
- **Impact:** Mobile users tapping "Exportar Reportes ICA" receive no file download, share dialog, or error feedback.
- **Proposed Fix:**
  Implement mobile saving using `path_provider` and `share_plus`:
  ```dart
  import 'dart:io';
  import 'package:path_provider/path_provider.dart';
  import 'package:share_plus/share_plus.dart';

  Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Oficial ICA - $fileName');
  }
  ```

---

### ARCH-10: Dual Conflicting Theme Persistence Implementations
- **Severity:** Low
- **Affected Files:**
  - `lib/core/design_system/theme_provider.dart` (Lines 7, 15)
  - `lib/core/storage/local_storage_service.dart` (Lines 16, 38)
- **Problem & Root Cause:**
  `ThemeModeNotifier` reads/writes `'fishbit_app_theme_mode'` as a boolean using raw `SharedPreferences.getInstance()`, while `LocalStorageService` reads/writes `'fishbit_theme_mode'` as a string (`'dark'`/`'light'`).
- **Impact:** Violates Single Source of Truth; UI theme state and stored preference can diverge.
- **Proposed Fix:**
  Refactor `ThemeModeNotifier` to inject and use `LocalStorageService`.

---

### ARCH-11: Decorative Unwired "Recordarme" Toggle in Login Form
- **Severity:** Low
- **Affected File:** `lib/modules/auth_tenant/presentation/screens/login_screen.dart` (Lines 27, 316–339)
- **Problem & Root Cause:**
  `_rememberMe` is toggled in the UI but is not passed to `signIn()` or `LocalStorageService`.
- **Impact:** Misleading user interface; session persistence behavior does not reflect user selection.
- **Proposed Fix:**
  Pass `rememberMe` to `signIn()` and configure session persistence accordingly.

---

## Conclusion & Prioritized Roadmap

The FishBit application exhibits thoughtful design in its domain modeling, Colombian aquaculture business rules, and glassmorphic UI components. However, critical vulnerabilities in row-level security and authentication bypass mechanisms must be addressed before production deployment:

1. **Immediate P0 Action:** Apply the `trg_protect_profile_privileges` trigger in PostgreSQL to eliminate the critical privilege escalation vulnerability (**SEC-01**).
2. **Immediate P0 Action:** Remove the authentication bypass in `signInWithEmailPassword` to ensure invalid passwords strictly reject authentication (**SEC-02**).
3. **P1 Security Hardening:** Eliminate the backdoor token fallback (**SEC-03**), purge customer PII from source code (**SEC-05**), and add explicit `SET search_path = public, pg_temp` to all security definer functions (**SEC-06**).
4. **P1 Architectural Consolidation:** Enforce `empresa_id` in all repository queries (**ARCH-01**), implement transactional inventory stock reduction (**ARCH-03**), and version the `setup_company_for_user` migration (**ARCH-04**).
5. **P2 Refactoring:** Decompose monolithic screens (**ARCH-06**), implement mobile file export for ICA reports (**ARCH-09**), and connect the offline sync queue (**ARCH-07**).
