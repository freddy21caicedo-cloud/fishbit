# Project: FishBit Codebase Comprehensive Audit

## Architecture & Scope
FishBit is a Flutter mobile application for aquaculture / fish farm management integrating with Supabase (PostgreSQL, Auth, Storage, Edge Functions).

### Audit Scope Dimensions:
1. **Stream 1: Architecture, Backend & Security Audit**
   - Application layers: Repository/Service pattern, Supabase client configuration, Auth flows, RLS policies, input validation, secret/credential exposure, error boundaries.
2. **Stream 2: UI/UX Interaction & Ergonomics Review**
   - Screen workflows (Ponds, Bitacora, ICA Certification, Feeding, Water Quality, Biomass, Mortality, Setup).
   - Visual hierarchy, ergonomics, accessibility (WCAG), feedback states (loading, error, empty), micro-interactions, responsive sizing across mobile form factors.
3. **Stream 3: State Management, Data Flow & Performance Audit**
   - Flutter state management (Riverpod/Provider/SetState usage), widget tree rebuild profiling, memory leaks (StreamSubscription, ChangeNotifier, TextEditingController disposal).
   - Database queries, pagination, caching, offline resilience, async error handling.

## Feature Inventory / Audit Targets
| # | Feature / Area | Description | Milestone | Source |
|---|----------------|-------------|-----------|--------|
| 1 | Architecture & Clean Code | Layer separation, dependency injection, coupling, technical debt | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Security & Auth Hardening | Supabase auth, RLS, token handling, sensitive inputs, API leaks | M1 | ORIGINAL_REQUEST §R1 |
| 3 | UI/UX & Interaction Design | Workflows, visual hierarchy, ergonomics, responsive layouts | M2 | ORIGINAL_REQUEST §R2 |
| 4 | Feedback & Accessibility | Loading skeletons, error feedback, empty states, WCAG standards | M2 | ORIGINAL_REQUEST §R2 |
| 5 | State Management & Rebuilds | Riverpod/reactive state, rebuild hot spots, lifecycle handling | M3 | ORIGINAL_REQUEST §R1 |
| 6 | Performance, Leaks & DB | Async memory leaks, Supabase query efficiency, indexing, pagination | M3 | ORIGINAL_REQUEST §R1 |
| 7 | Audit Report Synthesis | Unified, categorized markdown report with exact file refs and diffs | M4 | ORIGINAL_REQUEST §R3 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Architecture & Security Audit | Inspect lib/ core, data, services, auth, Supabase schema & policies | none | IN_PROGRESS |
| M2 | UI/UX & Interaction Audit | Inspect lib/presentation, screens, widgets, design tokens, accessibility | none | IN_PROGRESS |
| M3 | Performance & State Audit | Inspect state providers, controllers, subscriptions, queries, rebuilds | none | IN_PROGRESS |
| M4 | Synthesis & Prioritization | Synthesize M1, M2, M3 findings into final AUDIT_REPORT.md | M1, M2, M3 | PLANNED |

## Interface Contracts & Guidelines
- All Explorers must produce a comprehensive analysis report in their respective `.agents/<agent_name>/` folder.
- Every finding must adhere to the R3 schema:
  - **Category/ID**: (e.g. SEC-01, PERF-01, ARCH-01, UX-01)
  - **Severity**: Critical / High / Medium / Low
  - **File Path**: Exact workspace path with line numbers
  - **Problem Description**: Root cause, anti-pattern, or friction
  - **Impact**: Security vulnerability, memory leak, UI jank, bad UX
  - **Proposed Fix / Code Diff**: Actionable code snippet or refactored pattern
- STRICT RULE: Read-only exploration. No source files under `lib/`, `test/`, `android/`, `ios/`, `web/`, `supabase/` may be edited or deleted.

## Code Layout
- `lib/`: Flutter application source
- `supabase/`: Migrations, functions, database scripts
- `.agents/`: Agent logs, briefings, metadata, reports
- `AUDIT_REPORT.md`: Target comprehensive audit deliverable at workspace root
