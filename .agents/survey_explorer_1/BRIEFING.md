# BRIEFING — 2026-09-13T23:45:00Z

## Mission
Investigate Requirement R1 (SEC-01, SEC-02, SEC-03): hardcoded Supabase credentials, vulnerable RLS policies with `OR empresa_id IS NULL`, and user/team member creation security.

## 🔒 My Identity
- Archetype: explorer
- Roles: Security, Read-only investigation, code auditor
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_1
- Original parent: 18547dc8-fb6c-49bd-b058-468f6abda585
- Milestone: Survey R1 - Security & Multi-Tenancy

## 🔒 Key Constraints
- Read-only investigation — do NOT implement or modify application source code
- Files for delivery (handoff.md), send_message for coordination
- Handoff report must follow 5-component protocol: Observation, Logic Chain, Caveats, Conclusion, Verification Method

## Current Parent
- Conversation ID: 18547dc8-fb6c-49bd-b058-468f6abda585
- Updated: not yet

## Investigation State
- **Explored paths**:
  - `lib/main.dart`: Supabase initialization, environment fallback strings, startup assertions.
  - `supabase_migration_v10_canonical_v2.sql` (and all SQL files): RLS policies containing `OR empresa_id IS NULL`.
  - `lib/modules/auth_tenant/`: domain repositories, `SupabaseAuthRepository`, `auth_provider.dart`, `crear_colaborador_modal.dart`, `gestion_equipo_screen.dart`, `register_company_screen.dart`, `router.dart`.
  - `test/modules/auth_tenant/`: test suite verification.
- **Key findings**:
  - Hardcoded URL and JWT anonKey in `lib/main.dart` lines 33-41 via `defaultValue`.
  - 8 transactional tables in `supabase_migration_v10_canonical_v2.sql` lines 247-285 have `OR empresa_id IS NULL` in `USING`.
  - Critical auth bypass in `signInWithEmailPassword` (lines 122-133, 184-202) allowing passwordless login if email exists.
  - Backdoor in `registerWithInvitationToken` (lines 747-762) logging into a mock user on token failure.
  - Lack of admin permission check in `createTeamMember` and UI modals, silent `catch (_) {}` error suppression.
  - Plaintext password parameter in `createTeamMember` trying client-side `signUp` on authenticated sessions.
  - Hardcoded master email `especialistaacuicola@gmail.com` across multiple layers.
- **Unexplored areas**:
  - None within R1 scope; full survey complete.

## Key Decisions Made
- Fully documented exact file paths, line numbers, code snippets, architectural dependencies, and recommended remediation strategies.
- Formulating comprehensive 5-component handoff report in `handoff.md`.

## Artifact Index
- handoff.md — Comprehensive survey report on R1 Security & Multi-Tenancy
- progress.md — Liveness heartbeat and activity tracking
