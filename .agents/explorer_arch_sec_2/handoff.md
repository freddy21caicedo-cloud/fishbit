# Handoff Report — Architecture, Backend & Security Audit
**Author:** `explorer_arch_sec_2`  
**Working Directory:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_arch_sec_2`  
**Target Recipient:** `orchestrator_audit_2` (Conversation ID: `8e16dd4a-70fc-4f0d-b4c7-04c36298c6bd`)  
**Date:** 2026-09-13T23:35:00Z  
**Handoff Type:** Hard (Task Complete)

---

## 1. Observation

Direct observations and evidence collected during static analysis and code exploration:

1. **Insecure RLS Mutation in `public.profiles`:**
   - **Path:** `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:443-455`
   - **Verbatim Code:**
     ```sql
     CREATE POLICY profiles_tenant_isolation_update ON public.profiles
       FOR UPDATE TO authenticated
       USING (
         id = (SELECT auth.uid()) 
         OR (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
         OR (SELECT public.is_superadmin())
       )
     ```
   - No `BEFORE UPDATE` trigger exists on `public.profiles` to protect `role`, `is_superadmin`, or `empresa_id`.
   - `public.is_superadmin()` in line 52 reads `is_superadmin` and `role` directly from `public.profiles WHERE id = (SELECT auth.uid())`.

2. **Authentication Bypass on Failed Credentials:**
   - **Path:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart:121-133, 184-202`
   - **Verbatim Code:**
     ```dart
     try {
       authRes = await _supabase.auth.signInWithPassword(email: cleanEmail, password: cleanPassword);
     } catch (authError) {
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
   - When `memberCheck != null`, the catch block exits without rethrowing, and execution falls through to line 185, returning `member` and calling `_storage.setSessionUserId(member.id)`.

3. **Invitation Token Fallback Backdoor:**
   - **Path:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart:747-762`
   - **Verbatim Code:**
     ```dart
     if (res == null) {
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

4. **Hardcoded Customer PII & Contract Billing:**
   - **Path:** `lib/modules/auth_tenant/presentation/screens/saas_console_screen.dart:270-288`
   - **Verbatim Code:**
     ```dart
     _buildCompanyControlCard(
       companyId: '3500cc63-5477-4f83-b4a3-7758b7cd6509',
       name: 'Piscícola Los Compadres',
       nit: '901.530.907-1',
       adminEmail: 'piscicolaloscompadres@gmail.com',
       planPrice: '400.000 COP / año',
       renewalDate: '15 Dic 2026',
     ),
     ```

5. **`SECURITY DEFINER` Missing `search_path`:**
   - **Path:** `supabase/migrations/20260831_cost_security_and_immutability.sql:53-57, 94-98, 125-129`
   - Functions `fn_prevent_harvested_lot_mutation()`, `fn_enforce_payroll_immutability()`, and `fn_record_cost_audit_log()` omit `SET search_path = public, pg_temp`.

6. **Omission of `empresa_id` in Unit Insert:**
   - **Path:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart:600-608`
   - The map inserted into `unidades_acuicolas` contains `'nombre'`, `'sigla'`, `'ubicacion'`, but omits `'empresa_id'`.

7. **Multi-Tenancy Query Filter Omission in Repositories:**
   - **Path:** `lib/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart:25-29, 115-119`
   - Queries `_supabase.from('registros_nomina').select('*')` and `_supabase.from('mantenimientos').select('*')` receive `String empresaId` but do not filter by `empresa_id`.
   - Also in `lib/modules/equipment_capex/infrastructure/repositories/supabase_equipment_repository.dart:48-52`.

8. **Test Suite Verification Commands:**
   - Command: `flutter analyze --no-fatal-infos` -> Exited with code 0 ("No issues found!").
   - Command: `flutter test` -> Exited with code 1. 5 test failures:
     - `warehouse_inventory_test.dart`: `NoSuchMethodError` on `fetchCustomSuppliers` causing `Bad state: No element`.
     - `warehouse_inventory_test.dart`: Serialization test casing mismatch (`'Concentrado'` vs `'concentrado'`).
     - `bitacora_screen_test.dart`: 2 viewport / widget matching assertion failures.

---

## 2. Logic Chain

1. From **Observation 1**, `profiles_tenant_isolation_update` allows any authenticated user to update their own profile row. Because PostgreSQL applies RLS at row-level rather than column-level, and no column-check trigger exists, any authenticated operator or technician can update their `role` to `'master'`, their `is_superadmin` flag to `true`, and their `empresa_id` to any target UUID. Because SQL functions `is_superadmin()`, `get_auth_user_role()`, and `get_auth_empresa_id()` evaluate these exact columns on `profiles`, this grants immediate global superadmin privilege and full cross-tenant read/write access.
2. From **Observation 2**, `signInWithEmailPassword` intercepts `AuthException` from Supabase Auth and checks if the email exists in `miembros_equipo`. If true, the exception is suppressed and the user is returned as authenticated. Therefore, anyone who knows an employee's email address can enter any incorrect password and gain entry to the application.
3. From **Observation 3**, `registerWithInvitationToken` returns an active technician session for mock company `c1000000-0000-0000-0000-000000000001` whenever an invalid token is provided. Therefore, any unauthorized user can enter any arbitrary token and access the app without a valid invitation.
4. From **Observation 4**, sensitive commercial data including customer names, Colombian tax IDs (NIT), direct administrator emails, and contract prices are hardcoded in `saas_console_screen.dart`. Because Flutter bundles Dart assets into the client distribution, this violates Colombian Habeas Data (Ley 1581 de 2012) and exposes client data.
5. From **Observation 5**, functions marked `SECURITY DEFINER` without explicit `SET search_path` run with superuser privileges under the caller's search path. This enables schema-hijacking attacks where an attacker creates malicious functions in a preceding schema.
6. From **Observation 6**, `createUnit` does not include `empresa_id` in its payload. Consequently, units are created orphaned or the insert fails silently due to foreign key or NOT NULL constraints.
7. From **Observation 7**, multiple repositories query `registros_nomina`, `mantenimientos`, and `equipos` without filtering by `empresa_id`. While RLS provides a server-side boundary, omitting client-side tenant scoping violates defense-in-depth and leaks data if RLS is bypassed or misconfigured.
8. From **Observation 8**, `flutter analyze` confirmed clean syntax, while `flutter test` confirmed existing interface divergence (`fetchCustomSuppliers` missing in mocks) and widget test assertions.

---

## 3. Caveats

1. **Remote Cloud Supabase Dashboard State:** The audit inspected local SQL migration scripts (`supabase/migrations/` and workspace SQL files). Remote extensions or dashboard-created RPCs not checked into git (such as `setup_company_for_user`) were identified as missing from version control, but could theoretically exist in the remote managed Supabase instance.
2. **Third-Party Integrations:** Payment gateway webhooks (e.g. Wompi, ePayco, Stripe) were not observed in the codebase; billing toggles in `saas_console_screen.dart` are currently simulated client-side.
3. **No Source Code Modification:** In strict compliance with the assigned constraint, no source files under `lib/`, `test/`, or `supabase/` were altered during this audit.

---

## 4. Conclusion

The FishBit application exhibits clean domain modeling and robust financial algorithms for aquaculture (e.g., Weighted Average Cost, Feed Conversion Ratio, biological capitalization). However, the codebase currently suffers from **critical security vulnerabilities (P0)** in authorization and authentication:
- **SEC-01** (Privilege escalation to master/superadmin via self-profile update) and **SEC-02** (Authentication bypass allowing login with any wrong password) must be resolved immediately before deploying or admitting external users.
- **SEC-03**, **SEC-04**, **SEC-05**, **SEC-06**, **SEC-07**, **ARCH-01**, **ARCH-02**, and **ARCH-03** represent High-severity defects requiring remediation in Milestone 1/Milestone 4.

The comprehensive audit report with all 22 findings, line numbers, impacts, and code fixes is available at:
`c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_arch_sec_2\arch_security_report.md`

---

## 5. Verification Method

To independently verify the observations and findings:

1. **Verify RLS Vulnerability (SEC-01):**
   - Inspect `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` lines 443–455.
   - Run SQL command as authenticated user:
     ```sql
     UPDATE public.profiles SET role = 'master', is_superadmin = true WHERE id = auth.uid();
     ```
   - Check `SELECT public.is_superadmin();` -> returns `true`.

2. **Verify Auth Bypass (SEC-02):**
   - Inspect `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` lines 122–134 and 184–202.
   - Notice the catch block does not rethrow when `memberCheck != null`.

3. **Verify Static Analysis & Tests:**
   - Execute: `flutter analyze --no-fatal-infos` (passes with 0 errors).
   - Execute: `flutter test test/modules/auth_tenant/auth_tenant_test.dart` (passes 100%).
   - Execute: `flutter test test/modules/warehouse_inventory/warehouse_inventory_test.dart` (reproduces `NoSuchMethodError` on `fetchCustomSuppliers`).
