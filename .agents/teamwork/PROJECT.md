# Project: FishBit Architecture, Performance & Field Ergonomics Audit

## Architecture Overview
FishBit is a multi-tenant aquaculture farm management and regulatory compliance application built with Flutter (Web, iOS, Android, Desktop) and Supabase PostgreSQL.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Presentation Layer (Flutter UI)                       │
│  - Navigation: GoRouter with FloatingDockLayout & GlassActionHubSheet       │
│  - Dashboards: HomeDashboard, PondsDashboard, Bitacora, Finance, Warehouse  │
│  - Field Modals: Siembra, Alimentar, Parametro, Biometria, Mortalidad, etc. │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    State Management Layer (Riverpod 2.x)                     │
│  - Domain Providers: pondsProvider, nutritionProvider, waterQualityProvider │
│  - Financial & Compliance: financeProvider, icaComplianceProvider           │
│  - Aggregated Selectors: activeBatchesByPond, latestWaterQualityByPond      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    Repository & Offline Sync Layer                          │
│  - Repositories: SupabasePondsRepository, SupabaseNutritionRepository, etc. │
│  - Offline Persistence: OfflineSyncQueue (Hive local storage)               │
│  - Network Failure Fallbacks: AppFailure typed hierarchy                    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                    Backend Infrastructure (Supabase PostgreSQL)             │
│  - Multi-Tenant RLS: public.get_auth_empresa_id() InitPlan cached filters   │
│  - Time-Series Tables: parametros_calidad_agua, alimentacion_diaria, etc.   │
│  - Relational Integrity: estanques, lotes, traslados_lotes, ventas_cosecha  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Feature Inventory & Audit Dimension Mapping

| # | Feature / Audit Area | Description | Milestone | Source |
|---|----------------------|-------------|-----------|--------|
| 1 | Biological Lifecycle & DDL Integrity | Missing `public.traslados_lotes` DDL table, polyculture biomass overwrite, ghost fish after partial sales | M1 | Survey (Explorer 1) |
| 2 | Aquaculture Formulas & Costing | FCR distortion on batch split/desdoble, non-atomic multi-hop mutations, feed inventory deduction synchronization | M1 | Survey (Explorer 1) |
| 3 | Regulatory Compliance (ICA/AUNAP) | ICA official Excel export stub on mobile/desktop platforms, hardcoded sample data and dummy farm names | M1 | Survey (Explorer 1) |
| 4 | Field Input Form Sanitation | Hardcoded mock/default values in 8 production modal dialogs (siembra, mortalidad, biometria, etc.) | M1 | Survey (Explorer 1) |
| 5 | Supabase PostgreSQL RLS Isolation | Cross-tenant data leaks in 5 tables via `unidad_acuicola_sigla` or `cliente_id` without `empresa_id` filter | M1 | Survey (Explorer 1) |
| 6 | GPU Fill-Rate & Blur Optimization | Unconditional `BackdropFilter` (sigma 16) in `GlassContainer`, double card instantiation in `PondBentoCard`, ListView blurs | M2 | Survey (Explorer 2) |
| 7 | Riverpod Rebuild Scopes | Unscoped `ref.watch` in `BitacoraScreen`, `IcaCertificationScreen`, and root dashboard grid | M2 | Survey (Explorer 2) |
| 8 | Large-Screen Web Responsiveness | Missing `maxWidth: 1200` constraints on 1920px viewports, missing desktop mouse drag `ScrollBehavior`, hover states | M2 | Survey (Explorer 2) |
| 9 | Mobile Dock Clearance & SafeArea | Bottom 80dp content occlusion behind 104dp dock in `BitacoraScreen`, keyboard viewport shifts | M2 | Survey (Explorer 2) |
| 10 | WCAG 2.5.5 Touch Target Compliance | 40dp action button in `PondBentoCard` and 24x24dp close button in `GlassActionHubSheet` | M3 | Survey (Explorer 3) |
| 11 | WCAG 1.4.3 Tropical Sunlight Contrast | Light theme contrast ratios <2.6:1 for cyan, green, and amber accents; inactive `AppColors.accentText`; inverted text tokens | M3 | Survey (Explorer 3) |
| 12 | One-Handed Field Thumb Ergonomics | Centered dialogs vs bottom sheets for rugged farm field tasks | M3 | Survey (Explorer 3) |
| 13 | Offline Sync Queue Activation | Connecting dormant `OfflineSyncQueue.flushQueue()` to connectivity listeners and startup; eliminating ephemeral RAM storage | M4 | Survey (Explorer 3) |
| 14 | GoRouter Lifecycle & Navigation Shell | Replacing `ShellRoute` with `StatefulShellRoute.indexedStack` to preserve tab scroll state | M4 | Survey (Explorer 3) |
| 15 | Silent Exception Elimination | Replacing >50 silent `catch (_)` blocks with typed `AppFailure` handling and user notifications | M4 | Survey (Explorer 3) |

---

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Data Traceability, Lifecycle & Database Integrity | R1: End-to-end data chain, aquaculture calculations, DDL/RLS security fixes, and ICA regulatory compliance | None | AUDITED |
| M2 | Dual Platform Optimization (Web vs Mobile) | R2: GPU fill-rate optimization, Riverpod rebuild pruning, 1920px Web adaptation, and Mobile SafeArea dock clearance | None | AUDITED |
| M3 | Field Ergonomics & WCAG 2.2 Accessibility | R3: Touch targets (min 48x48 dp), tropical sunlight contrast in light mode, and one-handed thumb sheets | None | AUDITED |
| M4 | Offline Resilience & State Architecture | R4: OfflineSyncQueue activation, StatefulShellRoute migration, and typed AppFailure error handling | M1, M3 | AUDITED |
| M5 | Comprehensive Synthesis & Final Audit Report Delivery | Complete prioritized audit assessment report with exact file locations, line references, root cause, and concrete diffs | M1, M2, M3, M4 | IN_PROGRESS |

---

## Interface Contracts & Data Flow

### 1. Offline Synchronization Contract
- Repositories (`SupabasePondsRepository`, `SupabaseNutritionRepository`, `SupabaseWaterQualityRepository`) must never store failed mutations in volatile RAM.
- Failed network mutations must invoke `OfflineSyncQueue.instance.enqueue(operation, table, payload)`.
- `OfflineSyncQueue.instance.flushQueue(SupabaseClient supabase)` must be triggered by `Connectivity` network restoration stream and application cold start.

### 2. Multi-Tenant Database Policy Contract
- Every RLS policy on PostgreSQL must evaluate `empresa_id = (SELECT public.get_auth_empresa_id())`.
- Secondary scopes (such as `unidad_acuicola_sigla` or `sede`) must strictly be conjoined using `AND`, never `OR`, to eliminate cross-tenant leakage.

### 3. Biological Life Cycle Calculation Contract
- Pond biomass (`estanques.biomasa_kg`) must always represent the SQL `SUM(biomasa_actual_kg)` of all active batches in that pond.
- Harvest sales must decrement both `biomasa_actual_kg` and `cantidad_actual_peces` proportionally:
  `deltaPeces = (pecesActuales * (biomasaVendida / biomasaActual)).round()`.
- Batch desdoble / split must be executed via atomic PostgreSQL RPC `public.split_or_transfer_batch` to guarantee transaction atomicity and feed history proportional attribution.

---

## Code Layout

```
lib/
├── app/
│   ├── app.dart                   # MaterialApp.router, theme, ScrollBehavior
│   ├── main_navigation_shell.dart # Floating navigation dock & layout
│   └── router.dart                # GoRouter route definitions & shell
├── core/
│   ├── design_system/             # AppColors, AppTypography, GlassContainer, FloatingDock
│   ├── errors/                    # AppFailure hierarchy
│   ├── reports/                   # IcaOfficialReportsEngine & download helpers
│   └── sync/                      # OfflineSyncQueue & Hive persistence
└── modules/
    ├── bitacora/                  # Field operation logs (water, feeding, biometry, mortality)
    ├── feeding_nutrition/         # Feeding logs, feeding tables, nutrition repository
    ├── finance_payroll/           # Cost engines, sales records, payroll
    ├── ica_compliance/            # Regulatory reports & certification screens
    ├── ponds_batches/             # Ponds grid, batch models, bento cards, modals
    ├── sales_harvest/             # Harvest sales records & rapid sale modals
    ├── warehouse_inventory/       # Feed & alevin stock deduction & tracking
    └── water_quality/             # Physical-chemical parameter monitoring & modals
```
