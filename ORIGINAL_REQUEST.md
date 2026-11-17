# Original User Request

## Initial Request — 2026-08-31T14:52:12-05:00

You are the Project Orchestrator for the following mission:
Auditoría integral de rendimiento de la aplicación (frontend Flutter & backend Supabase), optimización avanzada de consultas e índices SQL en PostgreSQL, y endurecimiento de la infraestructura para despliegue y producción de FishBit.

Your working directory is:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\orchestrator_1

Authoritative request file:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\ORIGINAL_REQUEST.md

Project root workspace:
c:\Users\Freddy\Desktop\Desarrollo de app\FishBit

Requirements & Scope:
1. Auditoría y Optimización de Rendimiento Frontend (Flutter):
   - Identificar y resolver cuellos de botella en renderización, fugas de memoria, reconstrucciones innecesarias en PondsDashboardScreen, BitacoraScreen, IcaCertificationScreen.
   - Optimizar estado reactivo con Riverpod y asegurar fluidez a 60 FPS sin jank ni overflow (360px a 1920px).
2. Optimización Avanzada de SQL y Base de Datos (PostgreSQL / Supabase):
   - Auditar y optimizar consultas en parametros_calidad_agua, alimentacion_diaria, lotes, biometrias, mortalidad, traslados_lotes.
   - Crear índices compuestos estratégicos en (empresa_id, fecha DESC) y claves foráneas.
   - Optimizar políticas RLS para evitar lecturas secuenciales completas y subqueries costosas.
3. Preparación de Despliegue y Validación para Producción:
   - Configuración y validación de compilación para producción.
   - flutter analyze con 0 errores y 0 advertencias (--no-fatal-infos).
   - Suite de pruebas unitarias e integración pasando al 100%.

Decompose the project, dispatch specialist subagents, coordinate execution, maintain progress.md and BRIEFING.md in your working directory, and deliver a comprehensive solution. When complete, send a final completion report.

## Follow-up — 2026-09-12T23:15:00Z

Conduct a comprehensive, multi-dimensional audit of the FishBit application codebase, covering architecture, performance, security, data handling, and UI/UX interaction design, culminating in an actionable, prioritized report without altering the existing code.

Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Integrity mode: development

## Requirements

### R1. Deep Codebase, Architecture & Security Audit
- Inspect all application layers (UI widgets, state management, services/repositories, and backend/Supabase integrations).
- Identify technical debt, anti-patterns, performance bottlenecks (rebuilds, async leaks, unoptimized queries), and potential security risks (auth flows, credential handling, inputs).

### R2. UI/UX Interaction & Visual Design Review
- Evaluate screen workflows, visual hierarchy, ergonomics, feedback states (loading, errors, empty states), accessibility, and micro-interactions.
- Highlight specific friction points in user journeys and propose concrete, modern mobile UI/UX improvements.

### R3. Comprehensive & Actionable Audit Report
- Synthesize all findings into a structured markdown report categorized by impact:
  - Critical / High (bugs, security flaws, major performance degradation)
  - Medium (code smells, state management flaws, edge-case UX friction)
  - Low / Polish (styling inconsistencies, minor cleanups, optimization tips)
- For every finding, provide: file path reference, line context or problematic pattern explanation, impact assessment, and proposed code diff or solution pattern.
- Do not modify or delete existing application files; this task is strictly analytical and advisory.

## Acceptance Criteria

### Completeness & Rigor
- [ ] The audit covers both code/system architecture and front-end interaction/design.
- [ ] Every finding includes exact file paths, explanation of the issue, and concrete recommendations/examples for resolution.
- [ ] Deliverable is structured as a clear, prioritized Markdown report ready for review.
- [ ] No repository source files are modified during this phase.

## Follow-up — 2026-09-13T23:35:53Z

Implementación y resolución integral de los hallazgos críticos y de alta prioridad del Informe Ejecutivo de Auditoría 360° en FishBit Finance 2.0 (Flutter + Riverpod + Supabase PostgreSQL).

Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Integrity mode: development

## Requirements

### R1. Seguridad & Multi-Tenancy (SEC-01, SEC-02, SEC-03)
- Retirar claves de Supabase (URL y anonKey) hardcodeadas en `lib/main.dart` como valores por defecto; utilizar variables de entorno estrictas con validación previa (`assert` o verificación en arranque).
- Eliminar la condición vulnerable `OR empresa_id IS NULL` en las políticas RLS de Supabase (`supabase_migration_v10_canonical_v2.sql` y base de datos) para garantizar el estricto aislamiento por tenant en todas las tablas transaccionales.
- Asegurar que la creación de usuarios y miembros de equipo valide permisos administrativos y maneje credenciales con hashing seguro y sin contraseñas en texto claro.

### R2. Integridad de Datos Regulatorios ICA (DATA-01)
- Modificar el modal de registro de calidad de agua (`lib/modules/water_quality/presentation/dialogs/parametro_modal.dart`) para que los controladores numéricos inicialicen completamente vacíos, eliminando cualquier valor precargado simulado (pH 7.4, O₂ 6.2, etc.).
- Exigir validación obligatoria para los parámetros de rutina de campo (Oxígeno Disuelto, Temperatura y pH) antes de permitir el guardado.

### R3. Ergonomía de Campo y Accesibilidad WCAG (UX-01, UX-02, A11Y-01)
- Reestructurar los micro-botones de acción rápida en `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` para cumplir con el estándar WCAG 2.5.5 (área táctil mínima de 48x48 dp), implementando un botón de acción principal o Bottom Sheet operativo optimizado para manos húmedas.
- Incorporar `SafeArea(bottom: true)` y soporte de insets de navegación en `lib/app/main_navigation_shell.dart`, evitando colisiones con la barra de gestos del sistema y eliminando parches frágiles (`bottom: 78`) en FABs.
- Corregir los tokens de color en `AppTypography` para que se adapten reactivamente al tema claro/oscuro asegurando un ratio de contraste mínimo de 4.5:1 (WCAG 2.2 AA) en exteriores.

### R4. Resiliencia de Datos Offline y Manejo de Errores (DATA-02, PERF-01)
- Conectar `OfflineSyncQueue` en los repositorios de Supabase (`SupabasePondsRepository`, `SupabaseWaterQualityRepository`, `SupabaseNutritionRepository`) para que las mutaciones fallidas por falta de conectividad queden encoladas localmente y se sincronicen automáticamente al restablecer la red.
- Reemplazar bloques `catch (_)` silenciosos por tipado de excepciones (`AppFailure`), permitiendo notificar al usuario de fallas de red o persistencia.

## Acceptance Criteria

### Security & Multi-Tenancy
- [ ] No existen credenciales activas ni tokens JWT quemados como strings literales en el código fuente de Flutter.
- [ ] Todas las políticas RLS exigen que `empresa_id` pertenezca al tenant del usuario autenticado sin cláusulas de escape permisivas (`IS NULL`).

### Data Integrity & Field Usability
- [ ] Al abrir `parametro_modal.dart`, ningún campo físico-químico muestra valores por defecto; el formulario exige el ingreso real de las mediciones antes de guardar.
- [ ] Todas las áreas de toque interactivas en `pond_bento_card.dart` cumplen el mínimo de 48x48 dp.
- [ ] El dock flotante inferior respeta el `SafeArea` del dispositivo sin solaparse con la barra de gestos en iOS o Android.
- [ ] `flutter analyze --no-fatal-infos` retorna `No issues found!`.


## Follow-up — 2026-10-27T16:43:34Z

Conduct a comprehensive, multi-dimensional audit and optimization assessment of the FishBit application codebase, covering end-to-end aquaculture data traceability, dual Web and Mobile performance, field UI/UX ergonomics, and offline data resilience without altering existing code.

Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Integrity mode: development

## Requirements

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
- Review GoRouter lifecycle stability and eliminate silent `catch (_)` blocks that conceal network or persistence failures.
- Produce an actionable, prioritized report with exact file locations, line references, root cause analyses, and drop-in code diffs.

## Acceptance Criteria

### Rigor & Actionability
- [ ] Every finding contains exact file paths, line numbers, impact analysis, and concrete code diff / SQL schema fixes.
- [ ] Explicit distinction between Web-specific optimizations and Mobile-specific field ergonomics.
- [ ] Complete traceability audit of the biological and economic life cycle of fish batches.
- [ ] Strictly read-only: no existing production code files are modified during this audit.

## Follow-up — 2026-10-27T18:05:59Z

Execute the end-to-end implementation and remediation of all 16 architectural, performance, data traceability, and UX/ergonomics findings identified in FishBit Finance 2.0 based on `.agents/teamwork/orchestrator_1/FINAL_AUDIT_REPORT.md`.

Working directory: c:\Users\Freddy\Desktop\Desarrollo de app\FishBit
Integrity mode: development

## Requirements

### R1. Database Schema, Atomic RPC & Data Traceability Remediation
- Deploy the complete DDL for `public.traslados_lotes` with indexes, foreign keys, and hardened RLS tenant isolation (`FINAL_AUDIT_REPORT.md §6.1`).
- Harden RLS policies across the 5 vulnerable tables (`compras_mat_biologico`, `equipos`, `mantenimientos`, `facturas`, `inventario_insumos`) enforcing `empresa_id` tenant isolation.
- Implement the PostgreSQL atomic RPC `public.split_or_transfer_batch` to prevent FCR distortion on lot batch splits (`§6.2`).
- Fix polyculture biomass overwriting in `SupabasePondsRepository` by aggregating total pond biomass with SQL `SUM()` across all active lots.
- Implement proportional fish count deduction on partial harvest sales in `PondsNotifier` and `SalesNotifier`.
- Wire non-web ICA official report downloads via `path_provider` and `share_plus` in `web_download_helper_stub.dart`.
- Clear hardcoded default values across the 8 field dialogs (`parametro_modal.dart`, `siembra_modal.dart`, `mortalidad_modal.dart`, etc.) and require user input.

### R2. Dual Platform (Web & Mobile) Performance Optimization
- Add `enableBlur: false` to `GlassContainer` and bypass `BackdropFilter` shaders on high-opacity light theme surfaces and virtualized list items in `BitacoraScreen` (`§6.4.A`).
- Optimize `PondBentoCard` flip animation by lazily instantiating only the visible card face based on the rotation angle.
- Scope broad Riverpod watchers with `select(...)` in `IcaCertificationScreen` and `BitacoraScreen`.
- Implement responsive Web constraints (`maxWidth: 1200`) and desktop drag support via `AppScrollBehavior`.
- Fix mobile navigation dock occlusion by replacing hardcoded spacers with `DockBottomSpacer` adaptively respecting SafeArea.

### R3. UI/UX Interaction Design & Field Ergonomics (WCAG 2.2)
- Enlarge all primary action targets in `PondBentoCard` and modal dialogs to meet WCAG 2.5.5 minimums (48x48 dp).
- Fix light-mode color token contrast failures in `AppColors` and `AppTypography` to achieve >= 4.5:1 contrast against light backgrounds.
- Provide responsive mobile bottom sheet presentation for field actions while keeping centered dialogs for desktop web.

### R4. Offline Data Resilience & State Preservation
- Wire `OfflineSyncQueue` directly into repository mutation methods and hook `flushQueue` to network reconnection (`connectivity_plus`) and app startup.
- Refactor `router.dart` navigation shell to use `StatefulShellRoute.indexedStack` to preserve tab scroll states across navigation.
- Replace silent `catch (_)` blocks across repositories with typed `AppFailure` propagation and UI snackbar/toast feedback.

## Acceptance Criteria

### Verification & Quality Assurance
- [ ] `flutter analyze` runs clean with 0 new errors or warnings on all modified files.
- [ ] Supabase schema migration script and RPC functions are syntactically valid and tested.
- [ ] All 8 field dialogs load with clean, empty inputs and active form validators.
- [ ] `OfflineSyncQueue` properly queues operations when simulated offline and flushes upon network restoration.
- [ ] Web layout does not stretch uncontrollably past 1200px on widescreen monitors.
- [ ] Touch targets on Bento cards measure at least 48x48 dp.
- [ ] Tab switching retains scroll position without re-triggering full screen re-fetch.
