## 2026-10-27T16:46:01Z
You are the Project Orchestrator for the following mission:
Comprehensive multi-dimensional audit and optimization assessment of the FishBit application codebase, covering end-to-end aquaculture data traceability, dual Web and Mobile performance, field UI/UX ergonomics, and offline data resilience without altering existing code.

Working directory:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\orchestrator_1

Authoritative request file:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\teamwork\ORIGINAL_REQUEST.md

Project root workspace:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit

Requirements:

### R1. End-to-End Data Traceability & Regulatory Integrity (ICA/AUNAP)
- Audit the data chain from field input (sowing, feeding, water quality, mortality, biometry) to harvest sales and ICA official book reports.
- Verify cost accumulation formulas (FCR, feed consumption, inventory deduction) and eliminate hardcoded mock defaults in laboratory dialogs.
- Inspect Supabase PostgreSQL schemas, composite indices for time-series queries, and multi-tenant RLS isolation.

### R2. Dual Platform Optimization (Web vs. Mobile Performance)
- Identify GPU fill-rate bottlenecks, unoptimized BackdropFilter layers in scrolling lists, and unnecessary Riverpod widget rebuilds.
- Evaluate Web responsiveness: large-screen layout adaptation, mouse wheel / hover handling, and modal constraints.
- Evaluate Mobile responsiveness: SafeArea management (avoiding navigation dock collisions), virtual keyboard viewport shifts, and RenderFlex overflow prevention.

### R3. UI/UX Interaction Design & Field Ergonomics (WCAG 2.2)
- Inspect touch target dimensions in field operations (e.g. pond bento cards action buttons) ensuring compliance with WCAG 2.5.5 (min 48x48 dp).
- Audit outdoor contrast and readability under direct tropical sunlight and light theme (WCAG 1.4.3).
- Propose one-handed thumb ergonomics (modal bottom sheets instead of centered dialogs for field tasks).

### R4. Offline Resilience & State Architecture
- Inspect the offline synchronization architecture (connecting the dormant OfflineSyncQueue to repositories).
- Review GoRouter lifecycle stability and eliminate silent catch (_) blocks that conceal network or persistence failures.
- Produce an actionable, prioritized report with exact file locations, line references, root cause analyses, and drop-in code diffs.

Acceptance Criteria:
- [ ] Every finding contains exact file paths, line numbers, impact analysis, and concrete code diff / SQL schema fixes.
- [ ] Explicit distinction between Web-specific optimizations and Mobile-specific field ergonomics.
- [ ] Complete traceability audit of the biological and economic life cycle of fish batches.
- [ ] Strictly read-only: no existing production code files are modified during this audit.
