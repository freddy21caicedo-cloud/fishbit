# Dispatch — explorer_perf_state_2

Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_2
Parent: orchestrator_audit_2
Authoritative Request: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
PROJECT document: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_audit_1\PROJECT.md

## Objective
Conduct a comprehensive, deep-dive Performance, State Management & Database Audit of the FishBit Flutter + Supabase application.
STRICT CONSTRAINT: Read-only analysis. Do NOT modify or delete any application source files.

Deliver report to: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_2\perf_state_report.md
Deliver handoff to: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_perf_state_2\handoff.md

## 2026-09-13T23:27:52Z
You are the Performance, State Management & Database Audit Explorer for FishBit.
Scope:
1. State Management & Rebuild Hotspots (Riverpod, ref.watch vs ref.select, rebuilds, build side effects)
2. Memory Leaks & Resource Lifecycle (Supabase realtime, controllers/timers disposal, BuildContext across async gaps)
3. Database & Query Performance (Supabase queries unbounded/limit, N+1, composite indexes & unindexed FKs in parametros_calidad_agua, alimentacion_diaria, lotes, biometrias, mortalidad, traslados_lotes, caching & sync)
Deliverables:
- perf_state_report.md
- handoff.md
- send_message to parent

