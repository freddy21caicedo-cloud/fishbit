# Project: FishBit Finance 2.0 Master Remediation

## Architecture
- **Frontend**: Flutter 3.x / Dart (Riverpod 2.5 state management, GoRouter 14 navigation, Glassmorphism design system)
- **Backend & Database**: Supabase (PostgreSQL 15+, Row Level Security, Composite Indexes, PL/pgSQL Atomic RPCs)
- **Offline & Storage**: Hive / OfflineSyncQueue, ConnectivityPlus event-driven sync
- **QA & Reliability**: Strict static analysis, Unit & Widget test suites, WCAG 2.2 AA accessibility verification

## Feature Inventory (FishBit Finance 2.0 Remediation)
| # | Feature / Finding ID | Description | Milestone | Source |
|---|----------------------|-------------|-----------|--------|
| 1 | DATA-01 (DDL traslados_lotes) | Deploy complete DDL for `public.traslados_lotes` with indexes and RLS | M1 | FINAL_AUDIT §6.1 |
| 2 | SEC-01 (RLS Hardening) | Harden RLS policies on 5 vulnerable tables enforcing `empresa_id` isolation | M1 | FINAL_AUDIT §6.1 |
| 3 | DATA-03 (RPC split_or_transfer_batch) | Deploy atomic RPC `public.split_or_transfer_batch` to prevent FCR distortion | M1 | FINAL_AUDIT §6.2 |
| 4 | DATA-02 (Polyculture Biomass) | Fix polyculture pond biomass overwriting by aggregating across active lots | M1 | FINAL_AUDIT §2.1 |
| 5 | DATA-04 (Fish Count Deduction) | Proportional fish count deduction on partial harvest sales in Ponds/Sales | M1 | FINAL_AUDIT §6.3.A |
| 6 | REG-01 (ICA Report Downloads) | Wire non-web report downloads via path_provider and share_plus | M1 | FINAL_AUDIT §2.5 |
| 7 | DATA-05 (Field Dialog Defaults) | Clear hardcoded mock defaults across 8 field dialogs; enforce validation | M1 | FINAL_AUDIT §2.3 |
| 8 | PERF-01 (GPU GlassContainer) | Add enableBlur: false and bypass BackdropFilter on high opacity light surfaces | M2 | FINAL_AUDIT §6.4.A |
| 9 | PERF-01 (Bitacora List Items) | Disable blur shaders on virtualized list items in BitacoraScreen | M2 | FINAL_AUDIT §3.1 |
| 10| PERF-01 (PondBentoCard Flip) | Lazily instantiate only the visible card face during 3D flip animation | M2 | FINAL_AUDIT §3.2 |
| 11| PERF-02 (Riverpod Selectors) | Scope broad watchers with .select(...) in IcaCertification and Bitacora | M2 | FINAL_AUDIT §3.3 |
| 12| UX-03 (Web Layout & Mouse Drag) | Add maxWidth: 1200 constraints and AppScrollBehavior desktop drag support | M2 | FINAL_AUDIT §3.4 |
| 13| UX-02 (Navigation Dock Occlusion) | Replace SizedBox(height: 80) with DockBottomSpacer respecting SafeArea | M2 | FINAL_AUDIT §6.4.B |
| 14| UX-01 (Touch Targets WCAG 2.5.5) | Enlarge primary action targets in BentoCard (48dp) and GlassActionHubSheet | M3 | FINAL_AUDIT §6.4.C |
| 15| A11Y-01 (Outdoor Contrast WCAG 1.4.3)| Fix light-mode contrast failures and inverted tokens in BentoCard and AppColors | M3 | FINAL_AUDIT §6.4.D |
| 16| UX-01 (Responsive Field Modals) | Provide responsive mobile bottom sheet presentation vs desktop dialogs | M3 | FINAL_AUDIT §4.3 |
| 17| OFF-01 (OfflineSyncQueue Wiring) | Connect OfflineSyncQueue to repositories and flush on reconnect / startup | M4 | FINAL_AUDIT §6.3.B |
| 18| STATE-01 (GoRouter StatefulShell) | Refactor router.dart to StatefulShellRoute.indexedStack to preserve tab states | M4 | FINAL_AUDIT §5.2 |
| 19| ERR-01 (Typed AppFailure Hierarchy) | Eradicate silent catch (_) blocks with typed AppFailure propagation | M4 | FINAL_AUDIT §5.3 |
| 20| QA-01 (Final Verification & Audit) | Run flutter analyze, unit/integration tests, and forensic integrity audit | M5 | FINAL_AUDIT §1 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Database Schema, Atomic RPC & Data Traceability | Features 1-7 (DDL, RLS, RPC, Polyculture, Sales, Reports, Dialogs) | none | IN_PROGRESS |
| 2 | Dual Platform Performance Optimization | Features 8-13 (GPU blur bypass, Bento flip, Riverpod select, Web maxWidth, Dock spacer) | M1 | PLANNED |
| 3 | UI/UX Interaction Design & Field Ergonomics | Features 14-16 (Touch targets 48dp, contrast ratios, mobile bottom sheets) | M2 | PLANNED |
| 4 | Offline Data Resilience & State Navigation | Features 17-19 (OfflineSyncQueue, StatefulShellRoute, typed AppFailure) | M3 | PLANNED |
| 5 | Final Verification, Analysis & Forensic Audit | Feature 20 (flutter analyze clean, E2E tests, Challenger stress, Forensic audit) | M4 | PLANNED |

## Code Layout
- `supabase/migrations/`: Canonical SQL migration files
- `lib/modules/ponds_batches/`: Ponds, batches, bento cards, transfers, biometries, mortality
- `lib/modules/bitacora/`: Aquaculture daily logbook, tabs, list views
- `lib/modules/ica_compliance/`: ICA certification, official reports engine, biosecurity modals
- `lib/modules/feeding_nutrition/`: Feeding logs, nutrition repository
- `lib/modules/finance_payroll/`: Production costs, sales provider, payroll
- `lib/core/design_system/`: GlassContainer, AppColors, AppTypography, DockBottomSpacer, Action sheets
- `lib/core/storage/`: OfflineSyncQueue, local preferences
- `lib/core/errors/`: AppFailure hierarchy
- `lib/core/reports/`: Web & native download helpers
- `lib/app/`: App widget, router configuration, navigation shell
