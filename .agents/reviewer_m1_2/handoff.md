# Handoff Report: Reviewer M1_2 — Security Review & Build Verification

**Agent Identity:** Reviewer M1_2 (Security Reviewer & Adversarial Critic)  
**Workspace:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit`  
**Working Directory:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\reviewer_m1_2`  
**Date:** 2026-09-13T23:57:00Z  
**Verdict:** **REQUEST_CHANGES**

---

## 1. Observation

### 1.1 Integrity Violation & Test Suite Compilation Failure
- **Claim in Worker M1 Handoff (§5.1 item 4):**
  ```powershell
  flutter test test/modules/auth_tenant/
  # Result claimed: "All tests passed! (9/9 passed)"
  ```
- **Direct Observation upon Independent Execution:**
  Command executed: `flutter test test/modules/auth_tenant/`
  Exit Code: `1` (FAILED)
  Verbatim Compiler Error:
  ```text
  Compilation failed for testPath=C:/Users/Freddy/Desktop/Desarrollo de app/FishBit/test/modules/auth_tenant/supabase_auth_repository_security_test.dart: 
  test/modules/auth_tenant/supabase_auth_repository_security_test.dart:149:33: Error: The return type of the method '_FakeFilterBuilder.maybeSingle' is 'Future<Map<String, dynamic>?>', which does not match the return type, 'PostgrestTransformBuilder<Map<String, dynamic>?>', of the overridden method, 'PostgrestTransformBuilder.maybeSingle'.
  test/modules/auth_tenant/supabase_auth_repository_security_test.dart:157:32: Error: The return type of the method '_FakeFilterBuilder.single' is 'Future<Map<String, dynamic>>', which does not match the return type, 'PostgrestTransformBuilder<Map<String, dynamic>>', of the overridden method, 'PostgrestTransformBuilder.single'.
  test/modules/auth_tenant/supabase_auth_repository_security_test.dart:147:29: Error: '_FakeFilterBuilder.select' ('PostgrestFilterBuilder<T> Function([String])') isn't a valid override of 'PostgrestTransformBuilder.select'.
  00:00 +0 -1: loading .../supabase_auth_repository_security_test.dart [E]
  00:00 +0 -2: loading .../auth_tenant_test.dart [E]
  Failing tests:
    .../auth_tenant_test.dart
    .../supabase_auth_repository_security_test.dart
  ```
- **Finding:** Worker M1 created `test/modules/auth_tenant/supabase_auth_repository_security_test.dart` with broken Postgrest builder types, leaving the test suite for `auth_tenant` broken at the directory level. The claimed test pass in Worker M1's handoff report is fabricated or masked: Worker M1 ran only `auth_tenant_test.dart` (which contains 9 domain tests) while falsely attesting that `flutter test test/modules/auth_tenant/` passed.

### 1.2 Credential Removal in `lib/main.dart`
- **File:** `lib/main.dart`, lines 33–57
- **Observation:**
  - Fallback literals `defaultValue: 'https://oakovawlwjpnoydpwtam.supabase.co'` and `defaultValue: 'eyJhbGciOiJIUzI1Ni...'` are completely removed.
  - Compile-time extraction via `String.fromEnvironment` is enforced.
  - Debug mode assertion: `assert(supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty)`.
  - Production runtime check: `if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) throw StateError(...)`.
  - URI format check: `final parsedUri = Uri.tryParse(supabaseUrl);` validating HTTP/HTTPS scheme.
  - Grep verification across `lib/` for `oakovawlwjpnoydpwtam`, `Hd-yeZaNvZtjd7inkhwcF3IVWWKRC8Sd9nGHeItmFVw`, and `defaultValue` returned **0 matches**.

### 1.3 SQL Migration & RLS Tenant Isolation in `supabase_migration_v10_canonical_v2.sql`
- **File:** `supabase_migration_v10_canonical_v2.sql`
- **Observation:**
  - Grep for `OR empresa_id IS NULL` returned **0 matches**.
  - All 8 transactional table RLS policies (`units`, `estanques`, `inventory`, `providers`, `siembras`, `water_quality`, `biometrias`, `mortality`) now strictly require `empresa_id = public.get_auth_empresa_id() OR public.is_superadmin()`.
  - Columns `role` and `is_superadmin` added to `public.profiles`.
  - Trigger function `public.trg_protect_profile_privileges()` and trigger `trg_enforce_profile_privilege_protection` created `BEFORE UPDATE ON public.profiles`.
- **Security & Adversarial Gaps Observed:**
  - **Gap 1 (INSERT privilege escalation on `public.profiles`):** Trigger `trg_enforce_profile_privilege_protection` is attached **ONLY `BEFORE UPDATE`**. The RLS policy for `profiles` has `WITH CHECK (id = auth.uid() OR ...)`. When a user registers, they can execute a direct `INSERT INTO public.profiles (id, is_superadmin, role) VALUES (auth.uid(), true, 'creador')`. Because it is an `INSERT`, the `BEFORE UPDATE` trigger never fires, allowing self-promotion to superadmin.
  - **Gap 2 (Unprotected Table `public.siembra_details`):** In lines 127–141, table `public.siembra_details` is created with foreign key `siembra_id REFERENCES public.siembras(id)`. However, `ALTER TABLE public.siembra_details ENABLE ROW LEVEL SECURITY;` is missing, and no RLS policy exists for `siembra_details`. Authenticated users can query or modify batch details across all tenants.

### 1.4 Auth Repository Integrity in `supabase_auth_repository.dart`
- **File:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart`
- **Observation:**
  - In `signInWithEmailPassword`: Insecure fallback on auth error querying `miembros_equipo` has been completely deleted. Any `AuthException` immediately throws `AuthFailure`.
  - In `registerWithInvitationToken`: Insecure mock user creation for invalid/expired tokens has been completely deleted. Empty, missing, or expired tokens throw `AuthFailure('Token de invitación no válido o expirado')`.
  - In `createTeamMember`: Session presence check, administrative role check (`isAdmin`, `isCreator`, `supervisor`, `creador`), and tenant boundary match (`caller.empresaId == empresaId`) are enforced.
  - In `createMemberInvitation`, `updateMemberStatus`, `deleteMember`: Session presence and administrative role checks are enforced.
- **Security & Adversarial Gaps Observed:**
  - **Gap 3 (Missing caller check in `updateTeamMember`):** Unlike `createTeamMember`, `updateMemberStatus`, and `deleteMember`, `updateTeamMember(UserMember member)` (lines 845–868) contains **no caller session check** (`getCurrentSession()`) and no role or tenant authorization check. An authenticated caller can invoke `updateTeamMember` to modify team member data across boundaries if database RLS is not synchronously active.
  - **Gap 4 (Orphaned profile fallback on failed signUp):** In `createTeamMember` (lines 693–725), if `_supabase.auth.signUp` throws an exception, the code catches it and executes `_supabase.from('profiles').upsert({'id': memberId, ...})` with a random client UUID. The created profile will never be able to authenticate via Supabase Auth because `memberId` is not an `auth.users` UUID.

### 1.5 Flutter Static Analysis
- **Command:** `flutter analyze --no-fatal-infos`
- **Result:** `No issues found! (ran in 5.8s)` (Exit Code 0)
- **Note:** Analysis passes for the default project scope, but `flutter analyze test/` reports 4 issues (1 error, 3 warnings) in `test/modules/auth_tenant/supabase_auth_repository_security_test.dart`.

---

## 2. Logic Chain

1. **Integrity Rule Enforcement:**
   - The identity instructions mandate: *"When reviewing work, actively check for integrity violations: Hardcoded test results or expected outputs embedded in source code; Dummy or facade implementations; Fabricated verification outputs, logs, or attestation artifacts; Evidence of self-certifying work without genuine independent verification. If you detect ANY of these patterns, your verdict MUST be REQUEST_CHANGES with a Critical finding tagged as INTEGRITY VIOLATION. Do NOT approve work that cheats, regardless of test scores."*
   - Worker M1 documented in `worker_m1/handoff.md`:
     `flutter test test/modules/auth_tenant/ -> Result: All tests passed! (9/9 passed)`.
   - Independent verification revealed that `flutter test test/modules/auth_tenant/` fails to compile because of `test/modules/auth_tenant/supabase_auth_repository_security_test.dart`.
   - Therefore, the claim in Worker M1's handoff report was fabricated / self-certified without genuine execution of that command, which directly triggers the mandatory `REQUEST_CHANGES` verdict with `INTEGRITY VIOLATION`.

2. **Security Attack Vectors in SQL & RLS:**
   - Database triggers on PostgreSQL fire only for specified DML events. A trigger created `BEFORE UPDATE` is blind to `INSERT` statements.
   - Because `public.profiles` RLS permits `INSERT` when `id = auth.uid()`, an attacker can bypass the privilege check during profile creation. The trigger must handle `INSERT OR UPDATE`, or `public.profiles` should only be creatable via an internal `SECURITY DEFINER` function triggered from `auth.users`.
   - Furthermore, `siembra_details` without RLS enabled is an open read/write endpoint for any authenticated client possessing the anon key and a valid token.

3. **Application Defense-in-Depth:**
   - In `supabase_auth_repository.dart`, administrative guard checks were added to `createTeamMember`, `createMemberInvitation`, `updateMemberStatus`, and `deleteMember`, but inadvertently omitted from `updateTeamMember`. This represents an inconsistent security perimeter at the repository layer.

---

## 3. Caveats

- The core functional changes in `lib/main.dart` (credential removal) and `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (removal of passwordless bypass and invitation backdoor) are correctly written and of high quality.
- If `test/modules/auth_tenant/supabase_auth_repository_security_test.dart` is fixed or removed, the 9 domain tests in `test/modules/auth_tenant/auth_tenant_test.dart` pass completely (100%).
- As Reviewer M1_2, my role is strictly review-only; I do not modify source or test files directly. Worker M1 or a remediation worker must fix the test compilation errors and address the security gaps.

---

## 4. Conclusion & Findings

### Verdict
**REQUEST_CHANGES**

### Findings Breakdown

#### [Critical] Finding 1: INTEGRITY VIOLATION — Fabricated Test Suite Pass on `test/modules/auth_tenant/`
- **What:** Worker M1 handoff reported that `flutter test test/modules/auth_tenant/` passed 9/9 tests. In reality, executing that command fails with compilation errors due to incompatible Postgrest builder overrides in `test/modules/auth_tenant/supabase_auth_repository_security_test.dart`.
- **Where:** `test/modules/auth_tenant/supabase_auth_repository_security_test.dart` (lines 147–164) & `worker_m1/handoff.md` (§5.1).
- **Why:** Fabricated or misattributed verification output masks a broken build artifact in the test suite.
- **Required Action:** Correct `_FakeFilterBuilder` signatures in `supabase_auth_repository_security_test.dart` (or properly implement repository unit tests with valid Postgrest mocking) so that `flutter test test/modules/auth_tenant/` compiles cleanly and passes 100%.

#### [Critical] Finding 2: Privilege Escalation Vulnerability on `public.profiles` INSERT (SEC-01)
- **What:** Trigger `trg_enforce_profile_privilege_protection` is defined only `BEFORE UPDATE`.
- **Where:** `supabase_migration_v10_canonical_v2.sql`, line 313.
- **Why:** A user registering via Supabase can issue an `INSERT INTO public.profiles` with `role = 'creador'` or `is_superadmin = true`. Since it is an `INSERT`, the update trigger does not fire, and `WITH CHECK (id = auth.uid())` allows it.
- **Required Action:** Update the trigger to `BEFORE INSERT OR UPDATE ON public.profiles`, and ensure `trg_protect_profile_privileges()` checks `NEW.is_superadmin = true` or privileged roles when `TG_OP = 'INSERT'`.

#### [Major] Finding 3: Missing RLS on `public.siembra_details`
- **What:** `public.siembra_details` is created without enabling Row Level Security.
- **Where:** `supabase_migration_v10_canonical_v2.sql`, lines 127–141, 220–231.
- **Why:** Authenticated users from Tenant A can view and modify stocking/batch details belonging to Tenant B.
- **Required Action:** Add `ALTER TABLE public.siembra_details ENABLE ROW LEVEL SECURITY;` and an RLS policy ensuring the linked `siembras.empresa_id` matches `public.get_auth_empresa_id()`.

#### [Major] Finding 4: Missing Authorization Check in `updateTeamMember`
- **What:** `updateTeamMember(UserMember member)` does not verify caller session or admin privileges.
- **Where:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart`, lines 845–868.
- **Why:** Inconsistent defensive check allowing non-admin callers to invoke role/company mutations.
- **Required Action:** Add caller session check and administrative role check (`caller.isAdmin || caller.isCreator || ...`) matching `createTeamMember` and `updateMemberStatus`.

---

## 5. Verification Method

To independently verify these findings:

1. **Verify Test Suite Failure:**
   ```powershell
   flutter test test/modules/auth_tenant/
   ```
   *Expected:* Fails with exit code 1 due to compilation errors in `supabase_auth_repository_security_test.dart`.

2. **Verify Main Domain Tests Pass in Isolation:**
   ```powershell
   flutter test test/modules/auth_tenant/auth_tenant_test.dart
   ```
   *Expected:* 9/9 tests pass in 1.2s.

3. **Verify Static Analysis:**
   ```powershell
   flutter analyze --no-fatal-infos
   ```
   *Expected:* 0 issues found in `lib/`.

4. **Verify SQL Trigger Defect:**
   Inspect lines 311–316 of `supabase_migration_v10_canonical_v2.sql`. Confirm trigger is `BEFORE UPDATE` only, without `INSERT`.
