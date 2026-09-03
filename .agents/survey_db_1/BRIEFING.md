# BRIEFING — 2026-08-29T04:12:00Z

## Mission
Investigate the actual Supabase database schema and migrations for the Bitácora module, documenting tables, columns, constraints, foreign keys, indexes, RLS policies, and deprecation analysis for `calidad_agua` and `water_quality`.

## 🔒 My Identity
- Archetype: Specification Miner & Database Explorer
- Roles: DB Schema Analyzer, SQL Auditor, Specification Miner
- Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_db_1
- Original parent: 8d9d3925-2638-4c57-8043-da837c0e440b
- Milestone: Bitacora Database & Schema Audit

## 🔒 Key Constraints
- Read-only on live data/schema unless executing safe read-only SQL queries
- Detailed column definitions, types, nullable constraints, and defaults
- Examine: `parametros_calidad_agua`, `water_quality`, `calidad_agua`, `alimentacion_diaria`, `biometrias`, `mortalidad`, `estanques`, `lotes`, `empresas`
- Verify 10 water quality parameters + hora in `parametros_calidad_agua`
- Check foreign keys, 0-row references, existing indexes on `(empresa_id, fecha)`
- Check RLS policies and `get_auth_empresa_id()` definition and usage
- Evaluate deprecation/migration safety for `calidad_agua` and `water_quality`
- Output analysis.md and handoff.md

## Current Parent
- Conversation ID: 8d9d3925-2638-4c57-8043-da837c0e440b
- Updated: 2026-08-29T04:12:00Z

## Task Summary
- **Status**: Completed database audit and schema exploration for Supabase project `oakovawlwjpnoydpwtam`.
- **Key Findings**:
  - `parametros_calidad_agua` has 0 rows because `empresa_id` column is missing AND RLS is enabled with 0 policies (`DENY ALL`).
  - `water_quality` has 11 historical telemetry rows to migrate into `parametros_calidad_agua`.
  - `calidad_agua` has 0 rows and is obsolete.
  - `alimentacion_diaria` (84 rows) and `lotes` (15 rows) have valid FK relationships, but lack `(empresa_id, fecha)` indexes.
  - `biometrias` (38 rows) and `mortalidad` (7 rows) exist but are disconnected from Bitácora UI tabs ("Biometrías y GDP", "Bajas y Sanidad").
  - `mortalidad` rows have `empresa_id = NULL`.
- **Interface contracts**: Supabase schema and Flutter repositories.

## Key Decisions Made
- All detailed findings recorded in `analysis.md` and `handoff.md`.

## Artifact Index
- `analysis.md` — Detailed DB audit findings and tables
- `handoff.md` — 5-component handoff report
- `progress.md` — Liveness & step progress tracking
- `DISPATCH.md` — Dispatch record
