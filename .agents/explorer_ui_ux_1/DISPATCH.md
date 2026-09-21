# Dispatch: Explorer 2 - UI/UX Interaction & Visual Design Audit

## Identity & Working Directory
- Type: teamwork_preview_explorer
- Working Directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_ui_ux_1
- Parent Orchestrator: orchestrator_audit_1 (Conversation ID: 47bea1e0-3fba-4559-9d85-085710c2622f)
- Authoritative Request: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md
- Project Scope: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_audit_1\PROJECT.md

## Scope & Objective
Conduct a thorough UI/UX, interaction design, and visual ergonomics audit across all user journeys and screens in FishBit (`lib/presentation/`, `lib/features/`, screens, widgets).
Investigate:
1. Screen workflows & user journeys:
   - Auth & onboarding, Ponds/Dashboard, Bitácora/Daily Logs, Water Quality (parámetros), Feeding (alimentación), Biometrics, Mortality, Transfers, ICA certification, Setup/Settings.
   - Information architecture, navigation flows, back button behavior, modal vs screen confusion.
2. Visual Hierarchy, Ergonomics & Form Factors:
   - Layout responsiveness across device sizes (360px to tablet/desktop).
   - Touch targets (minimum 48x48 dp), thumb reachability for aquaculture field operations (frequently single-handed outdoor use).
   - Typography scaling, contrast ratios, and theme consistency.
3. Feedback States & Micro-interactions:
   - Loading states (skeletons vs blocking spinners), empty states (actionable guidance vs blank screens), error states with recovery actions.
   - Form feedback, validation timing, snackbars vs banners, confirmation dialogs for destructive actions.
4. Accessibility (WCAG 2.2):
   - Contrast, screen reader semantics (`Semantics` widgets, labels), font scaling (`MediaQuery.textScaleFactorOf`), color-only status indicators (e.g. water quality status red/yellow/green without icons/text).

## Deliverable
Write your comprehensive report to `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\explorer_ui_ux_1\ui_ux_report.md` with:
- Exact file paths and line numbers
- Screen & user journey context
- UX friction or design flaw description & severity (Critical, High, Medium, Low)
- Concrete proposed widget/code diff or UI solution pattern
When finished, write `handoff.md` and send a message back to parent orchestrator.
