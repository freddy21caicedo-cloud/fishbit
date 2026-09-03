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
