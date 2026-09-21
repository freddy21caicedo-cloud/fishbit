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
