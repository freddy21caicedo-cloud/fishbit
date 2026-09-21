# Worker M1 Dispatch: Security & Multi-Tenancy (SEC-01, SEC-02, SEC-03)
Date: 2026-09-13T23:46:00Z
Milestone: M1
Assigned Agent: teamwork_preview_worker
Working Directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\worker_m1
Project Root: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Authoritative Request: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
Survey Handoff: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_1\handoff.md
Project Index: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_impl_1\PROJECT.md

Scope & Write Ownership:
1. `lib/main.dart`:
   - Remove hardcoded Supabase URL ('https://oakovawlwjpnoydpwtam.supabase.co') and anonKey JWT fallback constants in `String.fromEnvironment`.
   - Enforce strict environment variables: `const supabaseUrl = String.fromEnvironment('SUPABASE_URL');` and `const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');`.
   - Implement pre-validation: `assert` in debug and `StateError` pre-validation check prior to `Supabase.initialize()` if URL or key are missing/empty or URL has invalid scheme.
2. `supabase_migration_v10_canonical_v2.sql`:
   - Remove vulnerable `OR empresa_id IS NULL` across all 8 transactional table RLS policies: `units`, `estanques`, `inventory`, `providers`, `siembras`, `water_quality`, `biometrias`, and `mortality`.
   - Ensure policies strictly enforce `(empresa_id = public.get_auth_empresa_id() OR public.is_superadmin())` without escape clauses.
   - Address SEC-01 in `public.profiles` RLS / triggers to prevent non-admin users from escalating their own `role` or setting `is_superadmin = true`.
3. `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart`:
   - SEC-02: In `signInWithEmailPassword`, completely eliminate the authentication bypass that allowed passwordless login if email existed in `miembros_equipo`. Failed Supabase auth must strictly fail.
   - SEC-03: In `registerWithInvitationToken`, eliminate the mock user backdoor that granted session access on company `c1000000-0000-0000-0000-000000000001` when tokens were invalid or expired. Throw `AuthFailure('Token de invitación no válido o expirado')`.
   - In `createTeamMember`: validate that caller has administrative permissions (`admin` / `supervisor`) before proceeding, and ensure errors are properly typed rather than silently caught.
4. Verification:
   - Run `flutter analyze --no-fatal-infos` and ensure no analyzer errors or warnings.
   - Run relevant auth tests.
   - Document all changes and verification command results in `handoff.md`.
