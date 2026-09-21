# Dispatch: Explorer 3 - Data Layer, State Management & Performance Audit

## Identity & Working Directory
- Type: teamwork_preview_explorer
- Working Directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_1
- Parent Orchestrator: orchestrator_audit_1 (Conversation ID: 47bea1e0-3fba-4559-9d85-085710c2622f)
- Authoritative Request: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
- Project Scope: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_audit_1\PROJECT.md

## Scope & Objective
Conduct a deep performance, state management, and data handling audit across the FishBit Flutter codebase.
Investigate:
1. State Management & Widget Tree Rebuilding:
   - Riverpod / Provider / setState usage patterns.
   - Indiscriminate `ref.watch` causing unnecessary full-screen re-renders vs fine-grained `ref.watch(provider.select(...))`.
   - Missing `const` constructors in widget trees.
   - Build method side-effects (e.g., triggering async calls or state mutations directly in `build()`).
2. Memory Leaks & Resource Lifecycle:
   - Uncancelled `StreamSubscription`s (especially Supabase realtime channels or sensors).
   - Undisposed `TextEditingController`, `AnimationController`, `ScrollController`, `FocusNode`, `Timer`.
   - Context capturing in unmounted state (`BuildContext across async gaps` without `if (!mounted) return;`).
3. Database & Query Performance:
   - Unbounded queries without pagination or `limit()`.
   - Missing composite indexes or unindexed foreign keys in Supabase/PostgreSQL queries (e.g. `parametros_calidad_agua`, `alimentacion_diaria`, `lotes`, `biometrias`, `mortalidad`, `traslados_lotes` filtered by `empresa_id` and `fecha DESC`).
   - N+1 query patterns or redundant network calls.
   - Caching, offline support, or optimistic updates handling.

## Deliverable
Write your comprehensive report to `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_1\perf_state_report.md` with:
- Exact file paths and line numbers
- Root cause and performance/memory impact
- Concrete proposed code diff or refactoring pattern
- Classification by severity: Critical, High, Medium, Low

## 2026-09-12T23:16:28Z
You are the Performance & State Management Explorer for the FishBit codebase audit.
Your working directory is: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_1
Read your instructions in: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_1\DISPATCH.md
Read the authoritative request in: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
Read project context in: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_audit_1\PROJECT.md

STRICT CONSTRAINT: Do NOT modify or delete any existing application files (in lib/, supabase/, etc.). This task is strictly analytical and advisory.

Investigate:
1. State Management & Widget Tree Rebuilding:
   - Riverpod / Provider / setState usage across screens (especially PondsDashboardScreen, BitacoraScreen, IcaCertificationScreen).
   - Indiscriminate `ref.watch` causing unnecessary full-screen re-renders vs fine-grained `select()`.
   - Missing `const` constructors causing unnecessary element rebuilds.
   - Build method side-effects (triggering async calls or mutations in build()).
2. Memory Leaks & Resource Lifecycle:
   - Uncancelled StreamSubscriptions (realtime channels, sensors, connectivity).
   - Undisposed controllers: TextEditingController, AnimationController, ScrollController, FocusNode, Timer.
   - Context capturing in unmounted state (BuildContext across async gaps without `if (!mounted) return;`).
3. Database & Query Performance:
   - Unbounded queries without limit/pagination in Supabase calls.
   - Missing composite indexes or unindexed foreign keys in PostgreSQL queries (e.g. parametros_calidad_agua, alimentacion_diaria, lotes, biometrias, mortalidad, traslados_lotes filtered by empresa_id and fecha DESC).
   - N+1 queries, redundant fetches, lack of caching / offline resilience.

Deliverable:
Produce a detailed, structured audit report at:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_1\perf_state_report.md
and write your soft/hard handoff to:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_1\handoff.md
