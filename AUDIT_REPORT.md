# Informe Maestro de Auditoría Integral: FishBit Mobile & Supabase Backend
**Proyecto:** FishBit Finance 2.0 (ERP Acuícola de Precisión y Trazabilidad Biológica)  
**Entorno:** Frontend Móvil Flutter (Android/iOS/Web) & Backend Supabase (PostgreSQL 15+, Auth, Storage, Edge Functions)  
**Fecha de Publicación:** 13 de Septiembre de 2026  
**Auditoría:** Master Multi-Agent Synthesis Team (`worker_report_writer_1`)  
**Fuentes de Entrada:**
1. *Auditoría de Arquitectura, Backend y Seguridad* (`explorer_arch_sec_2` — 22 hallazgos)
2. *Auditoría de UI/UX, Ergonomía de Campo y Accesibilidad WCAG 2.2* (`explorer_ui_ux_1` — 13 hallazgos)
3. *Auditoría de Rendimiento, Gestión de Estado y Base de Datos* (`explorer_perf_state_2` — 20 hallazgos)
**Estado de Integridad:** Conforme a Directiva de Auditoría Forense (Solo Lectura / Cero Alteración de Código Fuente en Producción)

---

## 1. Resumen Ejecutivo y Métricas Globales de Auditoría

Se ha completado una inspección forense exhaustiva y multidimensional sobre el código fuente, la arquitectura de capas, el diseño visual, el modelo de datos PostgreSQL y los flujos reactivos de la plataforma FishBit. La auditoría identificó un total de **55 hallazgos técnicos** categorizados por severidad e impacto operativo, superando el estimado inicial de 54 hallazgos tras documentar la degradación de planes de ejecución B-Tree en PostgreSQL por cláusulas disyuntivas en RLS (`DB-09`).

### 1.1 Distribución de Hallazgos por Dimensión y Severidad

| Flujo de Auditoría (Stream) | Total Hallazgos | 🔴 Crítico | 🟠 Alto | 🟡 Medio | 🟢 Bajo / Polish |
|---|:---:|:---:|:---:|:---:|:---:|
| **1. Arquitectura, Backend & Seguridad** | **22** | 2 | 9 | 8 | 3 |
| **2. UI/UX, Ergonomía & Accesibilidad** | **13** | 2 | 5 | 6 | 0 |
| **3. Rendimiento, Estado & Base de Datos** | **20** | 4 | 8 | 8 | 0 |
| **TOTAL CONSOLIDADO** | **55** | **8** | **22** | **22** | **3** |

```
  DISTRIBUCIÓN DE SEVERIDAD GLOBAL (55 HALLAZGOS)
  ┌─────────────────────────────────────────────────────────────┐
  │ 🔴 Críticos (P0): 8 (14.5%)                                 │
  │ 🟠 Altos (P1):    22 (40.0%)                                │
  │ 🟡 Medios (P2):   22 (40.0%)                                │
  │ 🟢 Bajos (P3):    3 (5.5%)                                  │
  └─────────────────────────────────────────────────────────────┘
```

### 1.2 Principales Vectores de Riesgo y Vulnerabilidades Sistémicas

1. **Escalada Crítica de Privilegios a Nivel Base de Datos (`SEC-01`):** La política de actualización RLS sobre `public.profiles` carece de restricción a nivel de columna. Cualquier operario de campo autenticado puede mutar su propio rol a `'master'` o marcar `is_superadmin = true`, asumiendo el control global de todos los inquilinos.
2. **Bypass Completo de Autenticación (`SEC-02`) y Backdoor de Invitaciones (`SEC-03`):** El repositorio de autenticación intercepta excepciones de contraseñas erróneas y permite el acceso al sistema si el correo existe en `miembros_equipo`. Además, cualquier token de invitación inexistente otorga una sesión activa sobre un inquilino de prueba.
3. **Peligro de Falsificación de Registros Sanitarios ICA (`UX-05`):** El modal de calidad de agua inicializa 11 parámetros físico-químicos con valores óptimos pre-cargados (OD 6.2 mg/L, Temp 28.5 °C, pH 7.4). Si el operario solo mide oxígeno y temperatura pero guarda, se almacenan 9 valores ficticios en la bitácora legal colombiana (Resolución ICA 065463).
4. **Pérdida Irreversible de Datos en Campo por Cola Offline Muerta (`DB-06` / `ARCH-07`):** La clase `OfflineSyncQueue` existe pero no está conectada a ningún repositorio. En zonas rurales sin señal celular, las fallas de red guardan las alimentaciones y biometrías en listas estáticas de memoria RAM (`_demoRecords`), perdiéndose irremediablemente al cerrar la aplicación.
5. **Agotamiento Gráfico de GPU por `BackdropFilter` Masivo (`PERF-01` / `UX-10`):** El uso ubicuo del shader gaussiano de desenfoque en listas virtualizadas con scroll continuo genera severo estrangulamiento del fill-rate en dispositivos móviles, degradando la tasa de cuadros a menos de 30 FPS.
6. **Violación Ergonómica en Campo por Blancos Táctiles de 30 dp (`UX-01`):** Los cuatro botones de acción primaria (`Alimentar`, `Muestreo`, `Bajas`, `Traslado`) en las tarjetas Bento miden apenas 30 dp de alto en una sola fila, provocando frecuentes pulsaciones erróneas de "Mortalidad" en vez de "Alimentar" con manos húmedas o guantes.
7. **Ausencia de Índices Compuestos y Degeneración de Planes RLS (`DB-03`, `DB-09`):** Las tablas más voluminosas (`parametros_calidad_agua`, `alimentacion_diaria`, `biometrias`) carecen de índices `(empresa_id, fecha DESC)` para consultas globales, forzando Sequential Scans y ordenamientos top-N en memoria.
8. **Destrucción Destructiva de `GoRouter` por Cambios de Auth (`STATE-06`):** La suscripción reactiva incondicional en `routerProvider` destruye la instancia completa del enrutador en cada refresco de sesión o cambio de unidad.

---

## 2. Matriz Maestra de Hallazgos Priorizados

La siguiente tabla consolida la totalidad de los 55 hallazgos clasificados de mayor a menor impacto:

| ID | Dominio / Stream | Severidad | Componente / Archivo | Resumen Ejecutivo del Problema |
|:---|:---|:---:|:---|:---|
| **SEC-01** | Seguridad | **Critical** | `supabase/migrations/...rls_optimization.sql:443` | Mutación no restringida en `profiles` permite auto-ascenso a Superadmin/Master. |
| **SEC-02** | Seguridad | **Critical** | `supabase_auth_repository.dart:117-134` | Contraseñas incorrectas ignoradas; inicio de sesión concedido si el email existe. |
| **UX-01** | UI/UX & Campo | **Critical** | `pond_bento_card.dart:395-505` | Botones de 30 dp apiñados en una fila causan registro accidental de bajas en campo. |
| **A11Y-01** | Accesibilidad | **Critical** | `app_typography.dart:8-67`, `bitacora_screen.dart` | Colores oscuros fijos causan ratio de contraste ilegible (2.6:1 y 1.6:1) en tema claro. |
| **STATE-06** | Estado & Router | **Critical** | `lib/app/router.dart:33-37` | `ref.watch(authProvider)` destruye y recrea la instancia `GoRouter` en cada cambio. |
| **PERF-01** | Rendimiento UI | **Critical** | `glass_container.dart:89-91`, `glass_card.dart` | `BackdropFilter` en tarjetas de listas en scroll causa estrangulamiento de shaders GPU. |
| **DB-03** | Base de Datos | **Critical** | `20260831...rls_optimization.sql:63-128` | Falta de índices `(empresa_id, fecha DESC)` provoca Sequential Scans en tablas de alto flujo. |
| **DB-06** | Base de Datos | **Critical** | `lib/core/storage/offline_sync_queue.dart:51-133` | Cola offline desconectada; fallas de red guardan datos en RAM volátil que se pierde al salir. |
| **SEC-03** | Seguridad | **High** | `supabase_auth_repository.dart:740-763` | Token de invitación inválido o caducado otorga sesión activa en tenant de prueba. |
| **SEC-04** | Seguridad | **High** | `auth_provider.dart:121`, `router.dart:51`, SQL | Correo personal `especialistaacuicola@gmail.com` cableado como superadmin en código y BD. |
| **SEC-05** | Seguridad | **High** | `saas_console_screen.dart:21-24, 270-288` | Datos reales de clientes (NITs, correos, tarifas comerciales) expuestos en código fuente. |
| **SEC-06** | Seguridad | **High** | `20260831_cost_security_and_immutability.sql` | Funciones `SECURITY DEFINER` en PostgreSQL carecen de `SET search_path = public, pg_temp`. |
| **SEC-07** | Seguridad | **High** | `supabase_auth_repository.dart:600-608` | `empresa_id` omitido en payload de inserción de `unidades_acuicolas`, creando sedes huérfanas. |
| **ARCH-01** | Arquitectura | **High** | Repositorios de Nómina, Equipos, Bodega y Agua | Consultas a Supabase omiten filtro `.eq('empresa_id')`, violando defensa en profundidad. |
| **ARCH-02** | Arquitectura | **High** | Repositorios (`sales`, `auth`, `ponds`, providers) | Bloques `catch (_) {}` vacíos ocultan fallos de escritura de BD y simulan éxito en UI. |
| **ARCH-03** | Arquitectura | **High** | `supabase_nutrition_repository.dart:118-127` | Descuento de stock en cliente sin transacción ni bloqueo; propenso a carreras y desbalance. |
| **ARCH-04** | Arquitectura | **High** | `supabase_auth_repository.dart:297` | Función RPC `setup_company_for_user` invocada en cliente pero inexistente en migraciones SQL. |
| **UX-02** | UI/UX & Layout | **High** | `main_navigation_shell.dart:62`, Screens | Dock flotante choca con barra de gestos del SO; pantallas usan parche frágil `bottom: 78`. |
| **UX-03** | UI/UX & Form | **High** | `crear_estanque_modal.dart:262`, `register...` | `SizedBox(height: 400/480)` en `PageView` provoca desbordamientos RenderFlex al abrir teclado. |
| **UX-04** | UI/UX & Ergonomía| **High** | Modales de alimentación, biometría, mortalidad | Diálogos centrales `showDialog` fuera de la zona del pulgar y colisionan con el teclado. |
| **UX-05** | UI/UX & Integridad | **High** | `parametro_modal.dart:36-46` | 11 parámetros de laboratorio prellenados con datos simulados arriesgan multas ICA. |
| **A11Y-02** | Accesibilidad | **High** | `glass_form_field.dart:211-218, 284-292` | Validador retorna `''` y oculta error nativo; lectores TalkBack/VoiceOver no anuncian el error. |
| **STATE-01** | Estado | **High** | `bitacora_screen.dart:418-425, 564-579` | `ref.watch` monolítico de 3 providers reconstruye 1,860 líneas de UI ante cualquier evento. |
| **STATE-02** | Estado & Rendimiento| **High** | `bitacora_screen.dart:1050, 1750-1858` | Cálculo síncrono $O(N \log N)$ de curvas de crecimiento GDP ejecutado dentro de `build()`. |
| **LEAK-01** | Fugas de Memoria | **High** | `login_screen.dart:63-134` | `TextEditingController` en modal de recuperar contraseña nunca ejecuta `dispose()`. |
| **LEAK-02** | Fugas de Memoria | **High** | `video_background_widget.dart:32-53` | Carrera asíncrona: invocación de `play()` sobre controlador de video ya desechado. |
| **PERF-02** | Rendimiento CPU | **High** | `ica_official_reports_engine.dart:949-981` | Compresión síncrona ZIP/Excel en hilo principal congela la UI durante 1.5 a 4 segundos. |
| **DB-01** | Base de Datos | **High** | `ponds_provider.dart:173-182, 289-296` | Tormenta de 5 consultas en paralelo y reseteo destructivo con `isLoading: true` tras cada mutación. |
| **DB-02** | Base de Datos | **High** | `supabase_ponds_repository.dart:191-196` | Consultas no acotadas sin `.limit()` descargan lotes históricos cerrados indefinidamente. |
| **DB-09** | Base de Datos | **High** | `20260831...rls_optimization.sql:205-208` | Cláusula `OR (SELECT is_superadmin())` en políticas RLS invalida Index Scan para usuarios estándar. |
| **SEC-08** | Seguridad | **Medium** | `router.dart:102-138`, `glass_action_hub_sheet` | Rutas sensibles (`/finance`, `/team`) sin guardias en el router; ocultamiento solo por UI. |
| **SEC-09** | Seguridad | **Medium** | `local_storage_service.dart:45-59`, `main.dart` | Tokens de sesión Supabase guardados en SharedPreferences plano sin cifrar. |
| **SEC-10** | Seguridad | **Medium** | `lib/main.dart:33-41` | URL de producción y Anon Key de Supabase cableadas como valores por defecto en compilación. |
| **ARCH-05** | Arquitectura | **Medium** | Esquemas SQL y Repositorios | Esquema híbrido/dividido (tablas en inglés legacy vs canónicas en español v10). |
| **ARCH-06** | Arquitectura | **Medium** | `bitacora_screen.dart`, `ica_official_reports...` | Clases Dios monolíticas de 1,860 y 1,513 líneas concentran lógica dispar y acoplada. |
| **ARCH-07** | Arquitectura | **Medium** | `offline_sync_queue.dart:51-132` | Cola offline huérfana no importada en la aplicación; código muerto en almacenamiento. |
| **ARCH-08** | Arquitectura | **Medium** | `register_company_screen.dart:104` | Navegación hacia ruta inexistente `context.go('/home')` en lugar de `/`. |
| **ARCH-09** | Arquitectura | **Medium** | `ica_official_reports_engine.dart:53-58` | Descarga de Excel no implementada en móviles (`web_download_helper_stub` vacío). |
| **UX-06** | UI/UX | **Medium** | `glass_action_hub_sheet.dart:123-130` | `GridView.count` con `childAspectRatio: 1.45` fijo se desborda con fuentes grandes o en 360 dp. |
| **UX-07** | UI/UX | **Medium** | `ponds_dashboard_screen.dart:297` | `mainAxisExtent: 380` fijo corta tarjetas con alertas de retiro sanitario ICA o policultivo. |
| **UX-08** | UI/UX | **Medium** | `ponds_dashboard_screen.dart:284-289` | Estados vacíos mudos sin ilustración, iconografía ni botón de llamada a la acción (CTA). |
| **UX-09** | UI/UX | **Medium** | DatePickers, Chips de Traslado, Giro 3D | Micro blancos táctiles (16 a 30 dp) violan pautas WCAG 2.5.5 y dificultan toque en campo. |
| **UX-10** | UI/UX | **Medium** | `glass_card.dart`, `glass_container.dart` | Ausencia de perfil de alto contraste solar; bordes sutiles invisibles a plena luz tropical. |
| **A11Y-03** | Accesibilidad | **Medium** | `home_dashboard_screen.dart:150`, `mortalidad...` | Semáforos basados exclusivamente en color; bajo contraste en chip de mortalidad severa. |
| **STATE-03** | Estado | **Medium** | `ica_certification_screen.dart:47-52` | Sobresuscripción a 6 providers en `build()` y `ref.watch` de un motor usado solo en botones. |
| **STATE-04** | Estado | **Medium** | `ponds_dashboard_screen.dart:27-28, 144, 381` | `setState` en pantalla raíz para alternar SpeedDial y filtros reconstruye todos los estanques. |
| **STATE-05** | Estado | **Medium** | `pond_bento_card.dart:81-90` | Instanciación incondicional de cara frontal y trasera 3D en cada frame del dashboard. |
| **LEAK-03** | Fugas de Memoria | **Medium** | `register_company_screen.dart:103-105` | Uso de `BuildContext` desactivado tras `context.go()` para invocar `ScaffoldMessenger`. |
| **DB-04** | Base de Datos | **Medium** | `supabase_sales_repository.dart:90-97` | Doble petición POST secuencial para escribir en `ventas` legacy y `ventas_lotes` canónica. |
| **DB-05** | Base de Datos | **Medium** | `supabase_ponds_repository.dart:509-516` | Consulta con operador `.or()` sobre columnas no indexadas compuestas en `traslados_lotes`. |
| **DB-07** | Base de Datos | **Medium** | `auth_provider.dart:136-152` | Tres consultas de red en serie (`company`, `units`, `team`) alargan el tiempo de arranque. |
| **DB-08** | Base de Datos | **Medium** | `supabase_schema_canonical_v10.sql:193` | Clave foránea `registrado_por` sin índice B-Tree en calidad de agua y biometrías. |
| **SEC-11** | Seguridad | **Low** | `lib/main.dart:14-26` | Registro no condicional de stack traces y errores de plataforma en consola de producción. |
| **ARCH-10** | Arquitectura | **Low** | `theme_provider.dart`, `local_storage_service` | Persistencia duplicada y divergente del modo de tema (bool vs String). |
| **ARCH-11** | Arquitectura | **Low** | `login_screen.dart:27, 316-339` | Selector decorativo "Recordarme" no enlazado con la persistencia real de sesión. |

---

## 3. Parte I: Hallazgos Críticos y de Alta Prioridad (P0 / P1)

Esta sección desglosa exhaustivamente los problemas de mayor severidad que comprometen la seguridad del sistema, la integridad de los datos biológicos y comerciales, la estabilidad del runtime y la viabilidad regulatoria ante el ICA.

### 3.1 Hallazgos de Severidad Crítica (P0)

#### SEC-01: Escalada Crítica de Privilegios a través de Política RLS Insegura en `profiles`
- **Severidad:** 🔴 **Critical**
- **Categoría:** Seguridad de Backend & Autorización de Datos
- **Archivo Afectado:** `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Líneas 443–455)
- **Causa Raíz y Explicación Técnica:**
  La política de seguridad a nivel de filas `profiles_tenant_isolation_update` autoriza a cualquier usuario autenticado a actualizar su propia fila de perfil basándose en la condición `id = (SELECT auth.uid())`:
  ```sql
  CREATE POLICY profiles_tenant_isolation_update ON public.profiles
    FOR UPDATE TO authenticated
    USING (
      id = (SELECT auth.uid()) 
      OR (empresa_id = (SELECT public.get_auth_empresa_id()) AND (SELECT public.get_auth_user_role()) = ANY (ARRAY['admin', 'creador', 'master'])) 
      OR (SELECT public.is_superadmin())
    )
    WITH CHECK (
      id = (SELECT auth.uid()) 
      OR ...
  ```
  PostgreSQL RLS verifica visibilidad de filas completas, no restricciones a nivel de columnas individuales. Dado que no existe una restricción de permisos de columna (`REVOKE UPDATE (role, is_superadmin, empresa_id) ON public.profiles`) ni un trigger de validación `BEFORE UPDATE`, cualquier cliente con credenciales válidas (incluso un técnico temporal o alimentador de campo) puede enviar una mutación directa mediante el SDK de Supabase:
  ```dart
  await supabase.from('profiles').update({
    'role': 'master',
    'is_superadmin': true,
    'empresa_id': '<uuid-de-otra-empresa>',
  }).eq('id', supabase.auth.currentUser!.id);
  ```
  Dado que las funciones de seguridad `public.is_superadmin()`, `public.get_auth_user_role()` y `public.get_auth_empresa_id()` consultan directamente `public.profiles WHERE id = auth.uid()`, el atacante adquiere de inmediato permisos de superadministrador global, logrando lectura y escritura arbitraria sobre todas las empresas de la base de datos.
- **Evaluación de Impacto:**
  Quiebre total del modelo de aislamiento multi-inquilino (*tenant isolation*). Un usuario no privilegiado puede usurpar identidades administrativas, acceder a balances financieros ajenos, alterar inventarios o borrar empresas competidoras.
- **Solución Concreta / Código Diff (SQL):**
  Implementar un trigger estricto `BEFORE UPDATE` con privilegios `SECURITY DEFINER` que impida la alteración de columnas de privilegio a usuarios no autorizados:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_sec01_profiles_privilege_escalation.sql
  CREATE OR REPLACE FUNCTION public.trg_protect_profile_privileges()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
  BEGIN
    -- Si se intenta mutar el rol, la bandera de superadmin o la empresa asignada:
    IF (NEW.role IS DISTINCT FROM OLD.role 
        OR NEW.is_superadmin IS DISTINCT FROM OLD.is_superadmin 
        OR NEW.empresa_id IS DISTINCT FROM OLD.empresa_id) THEN
      
      -- Solo un superadministrador previo o el proceso de bootstrap puede mutar estos campos
      IF NOT (SELECT public.is_superadmin()) THEN
        RAISE EXCEPTION 'FishBit Security Violation: No posee autorización para alterar roles, asignación de empresa o banderas de superadministrador.'
          USING ERRCODE = '42501';
      END IF;
    END IF;

    RETURN NEW;
  END;
  $$;

  DROP TRIGGER IF EXISTS trg_enforce_profile_privilege_protection ON public.profiles;
  CREATE TRIGGER trg_enforce_profile_privilege_protection
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_protect_profile_privileges();
  ```

---

#### SEC-02: Bypass Crítico de Autenticación en `signInWithEmailPassword`
- **Severidad:** 🔴 **Critical**
- **Categoría:** Autenticación & Control de Acceso
- **Archivo Afectado:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Líneas 117–134, 184–202)
- **Causa Raíz y Explicación Técnica:**
  En el método de inicio de sesión estándar con usuario y contraseña, el código intenta autenticar contra Supabase Auth mediante `_supabase.auth.signInWithPassword`. Si la contraseña es errónea, Supabase arroja un `AuthException`. Sin embargo, el bloque de captura maneja la excepción de manera deficiente:
  ```dart
  try {
    authRes = await _supabase.auth.signInWithPassword(email: cleanEmail, password: cleanPassword);
  } catch (authError) {
    // Si no pudo autenticar en Supabase Auth, verificar si existe en miembros_equipo
    final memberCheck = await _supabase
        .from('miembros_equipo')
        .select('id')
        .eq('email', cleanEmail)
        .maybeSingle();

    if (memberCheck == null) {
      throw AuthFailure('Credenciales incorrectas: ${authError.toString()}');
    }
  }
  ```
  Si `memberCheck != null` (es decir, el correo existe en el directorio de colaboradores de cualquier piscícola), el bloque `catch` finaliza de forma silenciosa sin relanzar el error. El flujo continúa hacia las líneas 184–202, donde se consulta el registro del usuario por correo, se guarda el ID de sesión en el almacenamiento local y se retorna el usuario como exitosamente autenticado.
- **Evaluación de Impacto:**
  Cualquier persona que conozca el correo electrónico de un operario, veterinario o gerente puede iniciar sesión tecleando cualquier contraseña arbitraria o vacía. Además, al haber fallado la autenticación real en Supabase, el cliente no posee un JWT válido (`supabase.auth.currentSession == null`), lo que deja la aplicación en un estado zombi que falla ante cualquier política RLS o desencadena fallbacks desincronizados.
- **Solución Concreta / Código Diff (Dart):**
  Eliminar el bloque permisivo de bypass y asegurar que cualquier fallo en la verificación de contraseña aborte la transacción:
  ```dart
  // En lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart
  @override
  Future<UserMember> signInWithEmailPassword(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final authRes = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = authRes.user;
      if (user == null) {
        throw const AuthFailure('No se pudo establecer la sesión con el servidor.');
      }

      final profileRow = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profileRow != null) {
        final member = UserMember.fromJson(profileRow);
        await _storage.setSessionUserId(member.id);
        if (member.unidadAcuicolaId != null) {
          await _storage.setActiveSedeId(member.unidadAcuicolaId!);
        }
        return member;
      }

      throw const AuthFailure('Perfil de usuario no configurado.');
    } on AuthException catch (e) {
      throw AuthFailure('Credenciales incorrectas: ${e.message}');
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw ServerFailure('Error durante la autenticación: $e');
    }
  }
  ```

---

#### UX-01: Botones de Acción Rápida en Bento Card Violando WCAG 2.5.5 y Provocando Errores de Registro en Campo
- **Severidad:** 🔴 **Critical**
- **Categoría:** Ergonomía de Campo & Factor Humano Acuícola
- **Archivo Afectado:** `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (Líneas 395–505)
- **Causa Raíz y Explicación Técnica:**
  En la base de cada tarjeta Bento de estanque se concentran los cuatro botones de operación cotidiana (`Alimentar`, `Muestreo`, `Bajas`, `Traslado`) en un solo `Row`. Cada botón tiene definida una restricción física de dimensiones mínimas de 30 dp:
  ```dart
  minimumSize: const Size(0, 30),
  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
  ```
  En un teléfono móvil estándar utilizado en granjas (pantalla de 360 dp de ancho útil), descontando márgenes y espaciadores, cada botón dispone de solo **69 dp de ancho por 30 dp de alto**, prácticamente pegados unos con otros.
- **Evaluación de Impacto:**
  El entorno real de una granja piscícola implica operarios sosteniendo el dispositivo con una mano junto al estanque, a menudo con dedos húmedos, salpicaduras de agua o guantes de nitrilo/caucho. Un blanco táctil de 30 dp viola flagrantemente la recomendación internacional WCAG 2.5.5 (mínimo 48×48 dp). En la práctica de campo, esto provoca que el operario pulse involuntariamente "Bajas" (mortalidad de peces) cuando pretendía pulsar "Alimentar", falseando el inventario de biomasa viva y disparando alertas fitosanitarias falsas en la granja.
- **Solución Concreta / Código Diff (Dart):**
  Reorganizar la botonera inferior de la tarjeta en una cuadrícula ergonómica de 2×2 con altura mínima de 48 dp y separación entre botones de 8 dp:
  ```dart
  // En lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart
  // Reemplazar el Row(children: [4 botones de 30dp]) por:
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _PondActionButton(
                icon: Icons.restaurant_rounded,
                label: 'Alimentar',
                color: AppColors.greenBiomass,
                minHeight: 48,
                onTap: () => AlimentarModal.show(context, pond: widget.pond, batch: batch),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PondActionButton(
                icon: Icons.scale_rounded,
                label: 'Muestreo',
                color: AppColors.cyanWater,
                minHeight: 48,
                onTap: () => BiometriaModal.show(context, pond: widget.pond, batch: batch),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PondActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Mortalidad',
                color: AppColors.coralAction,
                minHeight: 48,
                onTap: () => MortalidadModal.show(context, pond: widget.pond, batch: batch),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PondActionButton(
                icon: Icons.sync_alt_rounded,
                label: 'Traslado',
                color: Colors.purpleAccent,
                minHeight: 48,
                onTap: () => TrasladoModal.show(context, pond: widget.pond, batch: batch),
              ),
            ),
          ],
        ),
      ],
    ),
  )
  ```

---

#### A11Y-01: Tipografía con Colores Oscuros Fijos Invalida el Contraste en Tema Claro (WCAG 1.4.3)
- **Severidad:** 🔴 **Critical**
- **Categoría:** Accesibilidad Visual & Ergonomía Outdoor
- **Archivos Afectados:**
  - `lib/core/design_system/app_typography.dart` (Líneas 8–67)
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Líneas 827, 1302)
  - `lib/modules/water_quality/presentation/screens/water_quality_records_screen.dart` (Líneas 148, 181–189)
- **Causa Raíz y Explicación Técnica:**
  Las constantes de estilo de texto en `AppTypography` definen directamente colores estáticos propios del modo oscuro:
  ```dart
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryDark, // #8E9BAE
  );
  ```
  Cuando el usuario activa el modo claro (`ThemeMode.light`), donde los fondos son blancos (`#FFFFFF`) o gris claro (`#F4F6F9`), cualquier widget que invoca `AppTypography.bodySmall` dibuja texto `#8E9BAE` sobre fondo blanco.
  Adicionalmente, en `bitacora_screen.dart:827` y `1302` se usan literales `color: Colors.white54` sin contemplar el tema.
- **Evaluación de Impacto:**
  - El contraste entre `#8E9BAE` y `#FFFFFF` es de apenas **2.6:1**.
  - El contraste de `Colors.white54` sobre fondo claro cae a un catastrófico **1.6:1** (texto completamente invisible).
  - La norma internacional **WCAG 2.2 AA (Criterio 1.4.3)** exige un ratio mínimo de **4.5:1** para texto normal.
  - En condiciones de campo a plena luz solar tropical (más de 25.000 lux), las etiquetas de parámetros, lotes y fechas desaparecen de la vista del operario.
- **Solución Concreta / Código Diff (Dart):**
  Desacoplar los colores de las definiciones estáticas y crear un `ThemeExtension` o métodos que consuman dinámicamente el `Brightness` del contexto:
  ```dart
  // En lib/core/design_system/app_typography.dart
  class AppTypography {
    AppTypography._();

    static TextStyle bodySmall(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569), // Contraste 5.2:1 en claro
      );
    }

    static TextStyle labelMicro(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
      );
    }
  }
  ```

---

#### STATE-06: Destrucción y Recreación Total de `GoRouter` en Cambios de Autenticación
- **Severidad:** 🔴 **Critical**
- **Categoría:** Enrutamiento, Ciclo de Vida & Gestión de Estado
- **Archivo Afectado:** `lib/app/router.dart` (Líneas 33–37)
- **Causa Raíz y Explicación Técnica:**
  El proveedor del enrutador de la aplicación (`routerProvider`) está configurado con una suscripción reactiva directa a `authProvider`:
  ```dart
  final routerProvider = Provider<GoRouter>((ref) {
    final authNotifier = ref.watch(authRouterNotifierProvider);
    final authState = ref.watch(authProvider); // <-- Causa de la destrucción

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authNotifier,
      redirect: (context, state) { ... },
      routes: [ ... ],
    );
  });
  ```
  Al declarar `ref.watch(authProvider)`, Riverpod destruye y desecha la instancia completa de `GoRouter` cada vez que el estado de autenticación sufre una mutación (p. ej. refresco automático de token JWT en segundo plano, cambio de sede acuícola activa o modificación de datos del perfil).
- **Evaluación de Impacto:**
  Destrucción forzosa del stack histórico de navegación de Flutter. El usuario experimenta parpadeos de pantalla en blanco (white flash), reinicio involuntario de transiciones animadas y potenciales desajustes de estado al volver hacia atrás en la jerarquía de pantallas.
- **Solución Concreta / Código Diff (Dart):**
  Desacoplar la reactividad de GoRouter mediante `refreshListenable` y leer el estado en la función de redirección utilizando `ref.read`:
  ```dart
  // En lib/app/router.dart
  final routerProvider = Provider<GoRouter>((ref) {
    // Escuchar únicamente el ChangeNotifier de señalización de auth
    final authNotifier = ref.watch(authRouterNotifierProvider);

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authNotifier,
      redirect: (context, state) {
        // Consultar el estado actual bajo demanda sin destruir el enrutador
        final authState = ref.read(authProvider);
        final isAuth = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuth && !isLoggingIn) return '/login';
        if (isAuth && isLoggingIn) return '/';
        return null;
      },
      routes: appRoutes,
    );
  });
  ```

---

#### PERF-01: Sobrecarga Crítica de Shaders GPU por `BackdropFilter` en Listas con Desplazamiento
- **Severidad:** 🔴 **Critical**
- **Categoría:** Rendimiento Gráfico & Optimización de Shaders GPU
- **Archivos Afectados:**
  - `lib/core/design_system/glass_container.dart` (Líneas 89–91)
  - `lib/core/design_system/glass_card.dart` (Líneas 87–93)
- **Causa Raíz y Explicación Técnica:**
  `GlassContainer` implementa el efecto de vidrio esmerilado aplicando:
  ```dart
  ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(...),
    ),
  )
  ```
  `BackdropFilter` obliga al pipeline gráfico de Skia/Impeller a ejecutar un `saveLayer`, copiar el framebuffer anterior y aplicar un shader de convolución gaussiana de dos pasadas por cada cuadro dibujado. Debido a que casi todos los componentes de la app (`PondBentoCard`, celdas de parámetros en `BitacoraScreen`, tarjetas de insumos en `WarehouseScreen`) están envueltos en `GlassCard`, una pantalla en desplazamiento activo contiene entre 12 y 25 instancias de `BackdropFilter` simultáneas.
- **Evaluación de Impacto:**
  Agotamiento masivo del fill-rate de la GPU (*GPU stall*). Caída severa de la tasa de refresco a **15–28 FPS** en teléfonos inteligentes Android de gama baja y media comunes en explotaciones agropecuarias. Sobrecalentamiento térmico del dispositivo móvil y drenaje acelerado de batería.
- **Solución Concreta / Código Diff (Dart):**
  Añadir un parámetro `enableBlur` en `GlassContainer` (apagado por defecto para elementos dentro de listas con scroll), emulando el efecto translúcido mediante gradientes y colores `alpha`:
  ```dart
  // En lib/core/design_system/glass_container.dart
  class GlassContainer extends StatelessWidget {
    final Widget child;
    final double borderRadius;
    final bool enableBlur; // Flag para listas en scroll
    final Color? fillColor;
    final Border? border;

    const GlassContainer({
      super.key,
      required this.child,
      this.borderRadius = 16,
      this.enableBlur = false, // Por defecto optimizado para rendimiento
      this.fillColor,
      this.border,
    });

    @override
    Widget build(BuildContext context) {
      final effectiveFill = fillColor ?? Colors.white.withValues(alpha: 0.08);

      if (!enableBlur) {
        // Ruta de alto rendimiento: cero operaciones saveLayer en GPU
        return Container(
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        );
      }

      // Ruta con shader gaussiano reservada para Dock inferior y modales estáticos
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border,
            ),
            child: child,
          ),
        ),
      );
    }
  }
  ```

---

#### DB-03: Ausencia Crítica de Índices Compuestos `(empresa_id, fecha DESC)` en Tablas de Alto Tráfico
- **Severidad:** 🔴 **Critical**
- **Categoría:** Rendimiento de Base de Datos PostgreSQL
- **Archivo Afectado:** `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Líneas 63–128)
- **Causa Raíz y Explicación Técnica:**
  Las consultas operativas más frecuentes de los repositorios de FishBit filtran directamente por empresa y ordenan cronológicamente:
  - `parametros_calidad_agua WHERE empresa_id = $1 ORDER BY fecha DESC LIMIT 50;`
  - `alimentacion_diaria WHERE empresa_id = $1 ORDER BY fecha DESC LIMIT 100;`
  - `biometrias WHERE empresa_id = $1 ORDER BY date DESC LIMIT 100;`
  - `traslados_lotes WHERE empresa_id = $1 ORDER BY fecha_operacion DESC LIMIT 100;`

  En la migración `20260831...` los índices existentes están estructurados como `(empresa_id, estanque_id, fecha DESC)` o `(empresa_id, lote_id, fecha DESC)`. Cuando la consulta no especifica `estanque_id` o `lote_id`, PostgreSQL no puede emplear el índice para ordenar el conjunto resultante.
- **Evaluación de Impacto:**
  El planificador de consultas de PostgreSQL se ve obligado a realizar un escaneo secuencial (*Seq Scan*) de todas las filas del tenant o un *Bitmap Index Scan* disperso, seguido de un ordenamiento forzado en memoria (`Sort Method: top-N heapsort`). A medida que la granja acumula meses de operación, el consumo de CPU de Supabase se dispara exponencialmente.
- **Solución Concreta / Código Diff (SQL):**
  Desplegar una migración con los índices compuestos directos requeridos utilizando `CREATE INDEX CONCURRENTLY`:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_db03_composite_indexes.sql
  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_calidad_agua_empresa_fecha_desc 
    ON public.parametros_calidad_agua (empresa_id, fecha DESC);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_alimentacion_empresa_fecha_desc 
    ON public.alimentacion_diaria (empresa_id, fecha DESC);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_biometrias_empresa_date_desc 
    ON public.biometrias (empresa_id, date DESC);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_biometrias_empresa_estanque_date 
    ON public.biometrias (empresa_id, estanque_id, date DESC);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mortalidad_empresa_date_desc 
    ON public.mortalidad (empresa_id, date DESC);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_traslados_empresa_fecha_desc 
    ON public.traslados_lotes (empresa_id, fecha_operacion DESC);
  ```

---

#### DB-06: Cola Offline (`OfflineSyncQueue`) Desconectada y Pérdida Irreversible de Datos en Campo
- **Severidad:** 🔴 **Critical**
- **Categoría:** Resiliencia Offline & Persistencia de Datos
- **Archivo Afectado:** `lib/core/storage/offline_sync_queue.dart` (Líneas 51–133)
- **Causa Raíz y Explicación Técnica:**
  La clase `OfflineSyncQueue` implementa un buffer estructurado con almacenamiento persistente para acciones pendientes. Sin embargo, **ningún repositorio del proyecto la importa ni la invoca**.
  Cuando un operario registra una labor de alimentación o biometría sin señal en un estanque rural, los repositorios (`SupabasePondsRepository`, `SupabaseNutritionRepository`) ejecutan:
  ```dart
  catch (_) {
    _demoRecords.insert(0, record);
    return record;
  }
  ```
  Los datos se insertan en una lista estática en memoria RAM (`_demoRecords`). Al cerrar la app o al ser descartada por el sistema operativo para liberar memoria, la totalidad de los datos zootécnicos ingresados en campo se destruyen irreversiblemente.
- **Evaluación de Impacto:**
  Pérdida catastrófica de información zootécnica real en entornos rurales con cobertura celular intermitente o nula, violando el requerimiento de resiliencia operativa de FishBit.
- **Solución Concreta / Código Diff (Dart):**
  Conectar los repositorios con `OfflineSyncQueue.enqueue` en caso de fallo de red y programar el vaciado de cola (*batch flush*) al detectar reconexión:
  ```dart
  // En lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart
  catch (e) {
    // Persistir la acción en disco local antes de retornar el objeto a la UI
    await OfflineSyncQueue.enqueue(
      type: OfflineActionType.feeding,
      table: 'alimentacion_diaria',
      payload: insertData,
    );

    _eventBus.fire(DailyFeedingRecordedEvent(record: record));
    return record;
  }
  ```


### 3.2 Hallazgos de Severidad Alta (P1)

#### SEC-03: Token de Invitación con Puerta Trasera (Backdoor) y Sesión Ficticia Multinquilino
- **Severidad:** 🟠 **High**
- **Categoría:** Seguridad de Autenticación & Aislamiento de Tenant
- **Archivo Afectado:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Líneas 740–763)
- **Causa Raíz y Explicación Técnica:**
  En el método `registerWithInvitationToken(String token, String password)`:
  ```dart
  if (res == null) {
    // Mock fallback para tokens de prueba
    final mockUser = UserMember(
      id: const Uuid().v4(),
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      nombre: 'Usuario Activado',
      email: 'invitado@fishbit.com',
      role: UserRole.technician,
      permisoGlobalEmpresa: false,
      estado: MemberStatus.active,
      creadoEn: DateTime.now(),
    );
    await _storage.setSessionUserId(mockUser.id);
    return mockUser;
  }
  ```
  Si el token introducido no existe en la base de datos o ha expirado, en lugar de denegar el acceso, el código genera un usuario simulado con rol `UserRole.technician` y le asigna una sesión activa en la empresa mock `c1000000-0000-0000-0000-000000000001`.
- **Evaluación de Impacto:**
  Un atacante sin invitación legítima puede escribir cualquier cadena de texto arbitraria en el formulario de invitación y acceder inmediatamente a la interfaz funcional del sistema, interactuando con datos y explorando la superficie de ataque interna.
- **Solución Concreta / Código Diff (Dart):**
  Rechazar inmediatamente cualquier token no encontrado o con fecha de vigencia caducada:
  ```dart
  // En lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart
  if (res == null) {
    throw const AuthFailure('El código o enlace de invitación no existe o es inválido.');
  }

  final expiraStr = res['token_invitacion_expira'] as String?;
  if (expiraStr != null && DateTime.parse(expiraStr).isBefore(DateTime.now())) {
    throw const AuthFailure('El enlace de invitación ha expirado. Solicite uno nuevo al administrador.');
  }
  ```

---

#### SEC-04: Correo Electrónico de Superadministrador Cableado en Código y Base de Datos
- **Severidad:** 🟠 **High**
- **Categoría:** Gestión de Credenciales & Autorización Criptográfica
- **Archivos Afectados:**
  - `lib/modules/auth_tenant/presentation/providers/auth_provider.dart` (Línea 121)
  - `lib/app/router.dart` (Línea 51)
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Línea 52)
- **Causa Raíz y Explicación Técnica:**
  La dirección `especialistaacuicola@gmail.com` está escrita en duro en múltiples niveles para conceder permisos maestros:
  ```sql
  -- En función SQL is_superadmin():
  (SELECT is_superadmin OR LOWER(role) IN ('creador', 'master', 'billingadmin') 
          OR LOWER(email) = 'especialistaacuicola@gmail.com' 
   FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1)
  ```
  En el cliente, la lógica de GoRouter y los proveedores omiten validaciones si el usuario logueado coincide con esa cadena de texto literal.
- **Evaluación de Impacto:**
  - Acoplamiento rígido a una cuenta personal. Si la persona abandona la organización o cambia su correo, las capacidades operativas de la plataforma fallan.
  - La verificación de roles basada en cadenas de correo en SQL elude la verificación de claims JWT firmados criptográficamente.
- **Solución Concreta / Código Diff (SQL):**
  Migrar la verificación de superadmin a `app_metadata` en el JWT de Supabase Auth:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_sec04_superadmin_claim.sql
  CREATE OR REPLACE FUNCTION public.is_superadmin()
  RETURNS BOOLEAN
  LANGUAGE sql
  STABLE SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
    SELECT COALESCE(
      ((SELECT auth.jwt() -> 'app_metadata' ->> 'is_superadmin')::boolean),
      (SELECT is_superadmin FROM public.profiles WHERE id = (SELECT auth.uid()) LIMIT 1),
      false
    );
  $$;
  ```

---

#### SEC-05: Datos Personales (PII) y Contratos Comerciales Reales Expuestos en Código Fuente
- **Severidad:** 🟠 **High**
- **Categoría:** Protección de Datos Personales & Cumplimiento Legal (Ley 1581 de 2012)
- **Archivo Afectado:** `lib/modules/auth_tenant/presentation/screens/saas_console_screen.dart` (Líneas 21–24, 270–288)
- **Causa Raíz y Explicación Técnica:**
  La pantalla de administración SaaS contiene tarjetas cableadas con identidades de clientes comerciales reales:
  ```dart
  // Cliente 1: Los Compadres
  _buildCompanyControlCard(
    companyId: '3500cc63-5477-4f83-b4a3-7758b7cd6509',
    name: 'Piscícola Los Compadres',
    nit: '901.530.907-1',
    adminEmail: 'piscicolaloscompadres@gmail.com',
    planPrice: '400.000 COP / año',
    renewalDate: '15 Dic 2026',
  ),
  ```
- **Evaluación de Impacto:**
  Infracción severa de la Ley Estatutaria de Protección de Datos Personales en Colombia (Ley 1581 de 2012 / SIC). Cualquier usuario con acceso al binario APK, IPA o JavaScript Web puede extraer nombres de empresas, números de identificación tributaria (NIT), correos corporativos y acuerdos de precios contractuales.
- **Solución Concreta / Código Diff (Dart):**
  Eliminar las estructuras cableadas del código fuente y consumirlas mediante un endpoint seguro o provider restringido a superadministradores:
  ```dart
  // En lib/modules/auth_tenant/presentation/screens/saas_console_screen.dart
  // Reemplazar tarjetas fijas por consumo dinámico:
  final subscribersAsync = ref.watch(saasSubscribersProvider);

  return subscribersAsync.when(
    data: (clients) => ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) => _buildCompanyControlCard(client: clients[index]),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, _) => Center(child: Text('Error al consultar suscriptores: $err')),
  );
  ```

---

#### SEC-06: Funciones PostgreSQL `SECURITY DEFINER` Sin `search_path` Explícito
- **Severidad:** 🟠 **High**
- **Categoría:** Endurecimiento de Base de Datos PostgreSQL
- **Archivo Afectado:** `supabase/migrations/20260831_cost_security_and_immutability.sql` (Líneas 53–57, 94–98, 125–129)
- **Causa Raíz y Explicación Técnica:**
  Las funciones de trigger `fn_prevent_harvested_lot_mutation()`, `fn_enforce_payroll_immutability()` y `fn_record_cost_audit_log()` se definen como `SECURITY DEFINER` pero omiten fijar el `search_path`.
  En PostgreSQL, las funciones `SECURITY DEFINER` se ejecutan con los privilegios del rol propietario (usualmente `postgres` o `supabase_admin`). Sin un `search_path` fijo, un usuario malicioso puede crear tablas, operadores o funciones homónimas en un esquema temporal y secuestrar la ejecución de la función.
- **Evaluación de Impacto:**
  Vulnerabilidad a ataques de inyección de esquema y potencial escalada de privilegios a nivel del motor relacional.
- **Solución Concreta / Código Diff (SQL):**
  Fijar explícitamente `search_path = public, pg_temp` en todas las funciones afectadas:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_sec06_search_path.sql
  ALTER FUNCTION public.fn_prevent_harvested_lot_mutation() SET search_path = public, pg_temp;
  ALTER FUNCTION public.fn_enforce_payroll_immutability() SET search_path = public, pg_temp;
  ALTER FUNCTION public.fn_record_cost_audit_log() SET search_path = public, pg_temp;
  ```

---

#### SEC-07: Omisión de `empresa_id` en el Payload SQL de Creación de Unidad Acuícola
- **Severidad:** 🟠 **High**
- **Categoría:** Integridad Referencial & Aislamiento Multi-inquilino
- **Archivo Afectado:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Líneas 600–608)
- **Causa Raíz y Explicación Técnica:**
  En la función `createUnit(String empresaId, String nombre, String sigla, String? ubicacion)`:
  ```dart
  final res = await _supabase
      .from('unidades_acuicolas')
      .insert({
        'nombre': nombre,
        'sigla': sigla.toUpperCase(),
        'ubicacion': ubicacion,
      })
      .select()
      .single();
  ```
  El parámetro `empresaId` es recibido en el método pero **no se incluye en el mapa de inserción**.
- **Evaluación de Impacto:**
  Si la columna `empresa_id` admite nulos en la tabla, la nueva sede se almacena como un registro huérfano sin dueño. Si la columna tiene restricción `NOT NULL` o política RLS activa, la inserción arroja un error que es capturado silenciosamente por el bloque `catch`, retornando una unidad ficticia en memoria que nunca existió en la base de datos.
- **Solución Concreta / Código Diff (Dart):**
  Incorporar `empresa_id: empresaId` en el payload JSON:
  ```dart
  final res = await _supabase
      .from('unidades_acuicolas')
      .insert({
        'empresa_id': empresaId, // Inclusión obligatoria del tenant
        'nombre': nombre,
        'sigla': sigla.toUpperCase(),
        'ubicacion': ubicacion,
      })
      .select()
      .single();
  ```

---

#### ARCH-01: Omisión del Filtro `empresa_id` en Repositorios (Quiebre de Defensa en Profundidad)
- **Severidad:** 🟠 **High**
- **Categoría:** Arquitectura de Software & Multi-Tenancy
- **Archivos Afectados:**
  - `lib/modules/finance_payroll/infrastructure/repositories/supabase_finance_repository.dart` (Líneas 23–35, 110–120)
  - `lib/modules/equipment_capex/infrastructure/repositories/supabase_equipment_repository.dart` (Líneas 48–52)
  - `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart` (Líneas 124–127)
  - `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart` (Líneas 77–85)
- **Causa Raíz y Explicación Técnica:**
  Diversos métodos reciben `empresaId` pero no aplican `.eq('empresa_id', empresaId)` en la consulta Supabase:
  ```dart
  // supabase_finance_repository.dart
  var query = _supabase.from('registros_nomina').select('*');
  if (unidadAcuicolaId.isNotEmpty) {
    query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
  }
  final res = await query.order('fecha_pago', ascending: false).limit(100);
  ```
  Se depende de forma exclusiva de las políticas RLS de PostgreSQL para filtrar los datos.
- **Evaluación de Impacto:**
  Violación del principio de defensa en profundidad. Si la sigla de la unidad acuícola coincide entre empresas (ej. `'PRIN'`, `'SEDE-1'`), o si un administrador consulta la API con un rol elevado, la consulta devuelve registros de nómina, equipos o insumos de terceros.
- **Solución Concreta / Código Diff (Dart):**
  Anteponer siempre el filtro de tenant en la raíz de la consulta:
  ```dart
  var query = _supabase
      .from('registros_nomina')
      .select('*')
      .eq('empresa_id', empresaId); // Garantía explícita en capa de aplicación
  ```

---

#### ARCH-02: Bloques `catch (_) {}` Vacíos Generalizados Enmascarando Fallos de Escritura
- **Severidad:** 🟠 **High**
- **Categoría:** Manejo de Errores & Sincronización de Estado
- **Archivos Afectados:**
  - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` (Líneas 90–97)
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (Líneas 238, 250)
  - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` (Líneas 122, 153)
- **Causa Raíz y Explicación Técnica:**
  Se detectaron más de 25 bloques de captura de excepción completamente vacíos:
  ```dart
  try {
    await _supabase.from('ventas').insert(ventaPayload);
  } catch (_) {}

  try {
    await _supabase.from('ventas_lotes').insert(sale.toJson());
  } catch (_) {}
  ```
  Si ambas peticiones fallan por caída de conexión, violación de clave foránea o rechazo de RLS, la función no arroja ningún error, el proveedor asume éxito y emite un evento de dominio informando que la venta se completó satisfactoriamente.
- **Evaluación de Impacto:**
  Desincronización severa entre la interfaz visual y la base de datos persistente. Los usuarios asumen que transacciones financieras y cosechas están registradas cuando en realidad nunca se guardaron.
- **Solución Concreta / Código Diff (Dart):**
  Propagar los fallos mediante tipos sellados de error (`AppFailure`) y reportarlos en la UI:
  ```dart
  try {
    await _supabase.from('ventas_lotes').insert(sale.toJson());
  } on PostgrestException catch (e) {
    throw DatabaseFailure('Error al persistir la venta en base de datos: ${e.message}');
  } catch (e) {
    throw NetworkFailure('Fallo de conectividad al registrar venta: $e');
  }
  ```

---

#### ARCH-03: Condición de Carrera en Descuento No Atómico de Inventario en Cliente
- **Severidad:** 🟠 **High**
- **Categoría:** Consistencia Transaccional & Control de Bodega
- **Archivo Afectado:** `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart` (Líneas 118–127)
- **Causa Raíz y Explicación Técnica:**
  El descuento de alimento balanceado al registrar una alimentación se hace leyendo y reescribiendo desde el móvil:
  ```dart
  final item = await _supabase.from('inventory').select('current_stock').eq('id', insumoId).maybeSingle();
  if (item != null) {
    final curr = (item['current_stock'] as num?)?.toDouble() ?? 0.0;
    final updatedStock = (curr - kgConsumidos).clamp(0.0, double.infinity);
    await _supabase.from('inventory').update({'current_stock': updatedStock}).eq('id', insumoId);
  }
  ```
  Esta operación no utiliza transacciones (`BEGIN/COMMIT`) ni bloqueos pesimistas (`SELECT FOR UPDATE`).
- **Evaluación de Impacto:**
  En piscícolas con múltiples operarios alimentando estanques simultáneamente, las lecturas concurrentes sobrescriben los valores de stock, causando desbalances contables, pérdida de trazabilidad de costos de alimentación (que representan el 65% del costo de producción) y descuadre en auditorías ICA.
- **Solución Concreta / Código Diff (SQL):**
  Delegar el descuento de inventario a un trigger atómico de base de datos en PostgreSQL:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_arch03_inventory_decrement_trigger.sql
  CREATE OR REPLACE FUNCTION public.trg_auto_decrement_feed_stock()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
  BEGIN
    IF NEW.insumo_id IS NOT NULL AND NEW.cantidad_kg > 0 THEN
      UPDATE public.inventario_insumos
      SET cantidad_actual_kg = GREATEST(0, cantidad_actual_kg - NEW.cantidad_kg),
          actualizado_en = NOW()
      WHERE id = NEW.insumo_id;
    END IF;
    RETURN NEW;
  END;
  $$;

  DROP TRIGGER IF EXISTS trg_feed_stock_decrement ON public.alimentacion_diaria;
  CREATE TRIGGER trg_feed_stock_decrement
    AFTER INSERT ON public.alimentacion_diaria
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_auto_decrement_feed_stock();
  ```

---

#### ARCH-04: Función RPC `setup_company_for_user` Inexistente en Migraciones Versionadas
- **Severidad:** 🟠 **High**
- **Categoría:** Infraestructura & Despliegue de Base de Datos
- **Archivo Afectado:** `lib/modules/auth_tenant/infrastructure/repositories/supabase_auth_repository.dart` (Línea 297)
- **Causa Raíz y Explicación Técnica:**
  Durante el onboarding tras iniciar sesión con Google OAuth, el repositorio invoca:
  ```dart
  final res = await _supabase.rpc<dynamic>('setup_company_for_user', params: { ... });
  ```
  Sin embargo, un rastreo integral sobre el directorio `supabase/migrations/` revela que dicha función no se encuentra versionada en los scripts del repositorio.
- **Evaluación de Impacto:**
  Al aprovisionar un nuevo entorno de Supabase (Staging, Producción o Pruebas CI/CD), el flujo de bienvenida y creación de empresa falla de inmediato con `PostgrestException: function setup_company_for_user does not exist`.
- **Solución Concreta / Código Diff (SQL):**
  Crear la migración SQL canónica para la función RPC:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_arch04_setup_company_rpc.sql
  CREATE OR REPLACE FUNCTION public.setup_company_for_user(
    p_company_name TEXT,
    p_nit TEXT,
    p_unit_name TEXT,
    p_unit_sigla TEXT,
    p_user_name TEXT,
    p_user_email TEXT,
    p_departamento TEXT DEFAULT NULL,
    p_municipio TEXT DEFAULT NULL
  )
  RETURNS JSONB
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
  AS $$
  DECLARE
    v_user_id UUID := auth.uid();
    v_empresa_id UUID;
    v_unit_id UUID;
  BEGIN
    IF v_user_id IS NULL THEN
      RAISE EXCEPTION 'Usuario no autenticado.';
    END IF;

    -- 1. Crear la empresa
    INSERT INTO public.empresas (nombre, nit, departamento, municipio)
    VALUES (p_company_name, p_nit, p_departamento, p_municipio)
    RETURNING id INTO v_empresa_id;

    -- 2. Crear la unidad acuícola inicial
    INSERT INTO public.unidades_acuicolas (empresa_id, nombre, sigla)
    VALUES (v_empresa_id, p_unit_name, UPPER(p_unit_sigla))
    RETURNING id INTO v_unit_id;

    -- 3. Crear o actualizar el perfil como administrador/creador
    INSERT INTO public.profiles (id, empresa_id, unidad_acuicola_id, nombre_completo, email, role, estado)
    VALUES (v_user_id, v_empresa_id, v_unit_id, p_user_name, p_user_email, 'creador', 'activo')
    ON CONFLICT (id) DO UPDATE SET
      empresa_id = EXCLUDED.empresa_id,
      unidad_acuicola_id = EXCLUDED.unidad_acuicola_id,
      role = 'creador',
      estado = 'activo';

    RETURN jsonb_build_object(
      'empresa_id', v_empresa_id,
      'unidad_acuicola_id', v_unit_id,
      'status', 'success'
    );
  END;
  $$;
  ```

---

#### UX-02: Colisión del Dock de Navegación con Gestos del SO y Parche Generalizado de `bottom: 78`
- **Severidad:** 🟠 **High**
- **Categoría:** Layout Móvil & Ergonomía del Sistema Operativo
- **Archivos Afectados:**
  - `lib/core/navigation/main_navigation_shell.dart` (Líneas 62–66)
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Línea 430)
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Línea 47)
  - `lib/modules/finance_payroll/presentation/screens/finance_screen.dart` (Línea 57)
- **Causa Raíz y Explicación Técnica:**
  En `main_navigation_shell.dart`, el dock de navegación flotante se posiciona con:
  ```dart
  Positioned(
    left: 24,
    right: 24,
    bottom: 16,
    child: _FloatingDock(...),
  )
  ```
  No se consulta `MediaQuery.paddingOf(context).bottom` ni se utiliza `SafeArea`. En dispositivos iOS (con barra Home Indicator) o Android moderno con navegación por gestos, el dock se superpone a la barra del sistema, provocando que toques en la navegación cambien de aplicación en el teléfono. Para evitar que los botones flotantes queden tapados por el dock, prácticamente todas las pantallas de la app agregan manualmente un parche `EdgeInsets.only(bottom: 78)` en sus respectivos FABs.
- **Evaluación de Impacto:**
  Activación errónea de gestos del sistema en lugar de navegación en la app. FABs suspendidos a mitad de pantalla de forma visualmente antiestética y desalineada cuando el dock se oculta en subpantallas.
- **Solución Concreta / Código Diff (Dart):**
  Anclar el dock respetando los insets del dispositivo mediante `SafeArea`:
  ```dart
  // En lib/core/navigation/main_navigation_shell.dart
  Positioned(
    left: 16,
    right: 16,
    bottom: MediaQuery.paddingOf(context).bottom + 8,
    child: _FloatingDock(...),
  )
  ```

---

#### UX-03: `PageView` con Altura Rígida en Modales Provoca Desbordamientos de Teclado
- **Severidad:** 🟠 **High**
- **Categoría:** Responsividad Móvil & Manejo de Teclado Virtual
- **Archivos Afectados:**
  - `lib/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart` (Línea 262)
  - `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart` (Línea 225)
- **Causa Raíz y Explicación Técnica:**
  Los asistentes de varios pasos están encerrados dentro de contenedores con altura estática en duro (`SizedBox(height: 400)` y `SizedBox(height: 480)`).
  En `crear_estanque_modal.dart`, la suma de las alturas intrínsecas de los 5 inputs del Paso 1 alcanza los 425 dp.
- **Evaluación de Impacto:**
  Al pulsar en cualquier campo para ingresar el espejo de agua o la densidad, emerge el teclado virtual, reduciendo el espacio disponible a ~300 dp. Flutter lanza inmediatamente una excepción de desbordamiento visual (`RenderFlex overflowed by 125 pixels`, franja rayada amarilla/negra), ocultando los botones para avanzar o guardar.
- **Solución Concreta / Código Diff (Dart):**
  Reemplazar la altura fija por un contenedor flexible animado (`AnimatedSize` con `SingleChildScrollView`):
  ```dart
  // En lib/modules/ponds_batches/presentation/dialogs/crear_estanque_modal.dart
  // Sustituir SizedBox(height: 400, child: PageView(...)) por:
  AnimatedSize(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
    child: SingleChildScrollView(
      child: _pasoActual == 0 ? _buildPaso1(context) : _buildPaso2(context),
    ),
  )
  ```

---

#### UX-04: Diálogos Centrales (`showDialog`) Inadecuados para Operación Móvil a Una Mano en Campo
- **Severidad:** 🟠 **High**
- **Categoría:** Ergonomía de Campo & Zona del Pulgar (Thumb Zone)
- **Archivos Afectados:**
  - `lib/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart` (Líneas 23–28)
  - `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart` (Líneas 20–25)
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart` (Líneas 21–25)
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart` (Líneas 21–25)
- **Causa Raíz y Explicación Técnica:**
  Los flujos más repetitivos de la jornada piscícola se despliegan como cuadros de diálogo flotantes centrados en pantalla (`showDialog(context, builder: (ctx) => Dialog(...))`).
- **Evaluación de Impacto:**
  En terminales de 6.1 a 6.7 pulgadas, los campos principales y el botón de cierre quedan en el tercio superior de la pantalla, fuera del alcance natural del dedo pulgar. El operario se ve forzado a utilizar las dos manos o a cambiar el agarre mientras camina por el borde de un estanque. Adicionalmente, al desplegarse el teclado numérico, el diálogo se comprime contra la parte superior de la pantalla.
- **Solución Concreta / Código Diff (Dart):**
  Implementar un patrón adaptativo: `showModalBottomSheet` con `DraggableScrollableSheet` en teléfonos móviles, reservando `showDialog` exclusivamente para tabletas o pantallas de escritorio (ancho $\ge$ 600 dp):
  ```dart
  // Patrón ergonómico adaptativo para alimentar_modal.dart:
  static Future<void> show(BuildContext context, {Pond? pond, FishBatch? batch}) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    if (isTablet) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AlimentarModal(pond: pond, batch: batch),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => AlimentarModal(
            pond: pond,
            batch: batch,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
  ```

---

#### UX-05: Peligrosa Precarga de Parámetros de Laboratorio en Modal de Calidad de Agua
- **Severidad:** 🟠 **High**
- **Categoría:** Integridad de Datos Zootécnicos & Cumplimiento Normativo ICA
- **Archivo Afectado:** `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart` (Líneas 36–46)
- **Causa Raíz y Explicación Técnica:**
  Al abrir el formulario de captura de parámetros de calidad de agua, 11 controladores vienen prellenados con números fijos:
  ```dart
  final _oxigenoCtrl = TextEditingController(text: '6.2');
  final _saturacionCtrl = TextEditingController(text: '85.0');
  final _temperaturaCtrl = TextEditingController(text: '28.5');
  final _phCtrl = TextEditingController(text: '7.4');
  final _amonioCtrl = TextEditingController(text: '0.02');
  final _nitritosCtrl = TextEditingController(text: '0.5');
  final _alcalinidadCtrl = TextEditingController(text: '40.0');
  final _durezaCtrl = TextEditingController(text: '80.0');
  final _amoniacoNoIonizadoCtrl = TextEditingController(text: '0.01');
  final _co2Ctrl = TextEditingController(text: '1.2');
  final _transparenciaCtrl = TextEditingController(text: '25.0');
  ```
- **Evaluación de Impacto:**
  En la rutina de campo, los operarios toman mediciones rápidas con sonda de campo para Oxígeno y Temperatura, pero los análisis químicos (amonio, nitritos, alcalinidad) se realizan con menor frecuencia. Al presionar "Guardar Registro", el sistema almacena 11 mediciones óptimas simuladas. Estos datos nutren el cuaderno oficial exigido por el Instituto Colombiano Agropecuario (ICA) bajo Resolución 065463, lo que constituye una falsificación involuntaria de registros públicos que puede desencadenar la revocatoria del registro de predio pecuario y sanciones legales a la piscícola.
- **Solución Concreta / Código Diff (Dart):**
  Inicializar los controladores completamente vacíos y transferir los valores recomendados a etiquetas de guía (`hintText` y `helperText`):
  ```dart
  // En lib/modules/water_quality/presentation/dialogs/parametro_modal.dart
  // Inicialización limpia:
  final _oxigenoCtrl = TextEditingController();
  final _temperaturaCtrl = TextEditingController();
  final _phCtrl = TextEditingController();

  // En el widget GlassFormField:
  GlassFormField(
    controller: _oxigenoCtrl,
    label: 'OXÍGENO DISUELTO (OD)',
    hint: 'Ej: 5.8',
    suffixText: 'mg/L',
    helperText: 'Rango Óptimo ICA: 5.0 - 8.0 mg/L',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
  )
  ```

#### A11Y-02: Supresión de Semántica de Error en Formularios Afecta a Lectores de Pantalla (WCAG 4.1.2)
- **Severidad:** 🟠 **High**
- **Categoría:** Accesibilidad Digital (WCAG 2.2 AA / Criterios 4.1.2 y 3.3.1)
- **Archivo Afectado:** `lib/core/design_system/glass_form_field.dart` (Líneas 211–218, 284–292)
- **Causa Raíz y Explicación Técnica:**
  Para evitar que el widget `TextFormField` nativo de Flutter dibuje el mensaje de error por defecto en color rojo (el cual rompería la estética Glassmorphic), el validador suprime el texto devolviendo un string vacío:
  ```dart
  validator: widget.validator != null
      ? (value) {
          final error = widget.validator!(value);
          if (error != null) {
            return ''; // Oculta el mensaje nativo retornando cadena vacía
          }
          return null;
        }
      : null,
  ```
  Posteriormente, el campo renderiza el mensaje de error en un `Text` desacoplado visualmente:
  ```dart
  if (_errorText != null) ...[
    const SizedBox(height: 6),
    Text(_errorText!, style: const TextStyle(color: AppColors.coralAction, fontSize: 11)),
  ]
  ```
- **Evaluación de Impacto:**
  Los servicios de accesibilidad asistida por voz (Google TalkBack en Android y Apple VoiceOver en iOS) reconocen que el campo está en estado "no válido", pero al leer el nodo semántico del input anuncian únicamente "Campo con error: vacío". El operario con discapacidad visual o problemas de refracción bajo luz solar intensa no tiene manera de saber cuál fue el error (p. ej. "La biomasa debe ser mayor a cero" o "El NIT es inválido").
- **Solución Concreta / Código Diff (Dart):**
  Vincular el mensaje de error a un nodo semántico interactivo con `liveRegion: true`:
  ```dart
  // En lib/core/design_system/glass_form_field.dart
  if (_errorText != null) ...[
    const SizedBox(height: 6),
    Semantics(
      liveRegion: true, // Notificación inmediata al lector de pantalla
      label: 'Error en ${widget.label ?? "campo"}: $_errorText',
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.coralAction),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppColors.coralAction,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  ]
  ```

---

#### STATE-01: Suscripción Monolítica en `BitacoraScreen` Provoca Reconstrucción en Cascada de 4 Pestañas
- **Severidad:** 🟠 **High**
- **Categoría:** Gestión de Estado Reactivo (Riverpod & Flutter)
- **Archivo Afectado:** `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Líneas 418–425, 564–579)
- **Causa Raíz y Explicación Técnica:**
  En el método raíz `build()` de la pantalla de bitácora:
  ```dart
  final waterState = ref.watch(waterQualityProvider);
  final nutritionState = ref.watch(nutritionProvider);
  final pondsState = ref.watch(pondsProvider);
  final pondMap = {for (final p in pondsState.ponds) p.id: p};
  final batchMap = {for (final b in pondsState.batches) b.id: b};
  ```
  La pantalla escucha la totalidad de los 3 proveedores de estado neurálgicos de la granja. Cada vez que un sensor reporta oxígeno, o se registra un bulto de alimento o un traslado de lote, se reconstruye el `Scaffold`, el `NestedScrollView`, el selector de estanques y se vuelven a evaluar las 4 pestañas simultáneamente (`_buildWaterQualityTab`, `_buildFeedingTab`, `_buildBiometryTab` y `_buildMortalityTab`).
- **Evaluación de Impacto:**
  Reconstrucción innecesaria de 1,860 líneas de interfaz ante cualquier mutación atómica. Pérdida del scroll interno en pestañas secundarias y generación repetitiva de mapas en memoria (`pondMap`, `batchMap`).
- **Solución Concreta / Código Diff (Dart):**
  Desacoplar cada una de las 4 pestañas en un `ConsumerWidget` independiente y utilizar selectores específicos (`ref.watch(provider.select(...))`):
  ```dart
  // En lib/modules/bitacora/presentation/screens/bitacora_screen.dart
  // En la pantalla contenedor solo escuchar el filtro activo:
  TabBarView(
    controller: _tabController,
    children: [
      BitacoraWaterTab(selectedPondId: _selectedPondId),
      BitacoraFeedingTab(selectedPondId: _selectedPondId),
      BitacoraBiometryTab(selectedPondId: _selectedPondId),
      BitacoraMortalityTab(selectedPondId: _selectedPondId),
    ],
  )
  ```

---

#### STATE-02: Cálculo Síncrono Pesado de Ganancia Diaria de Peso (GDP) en el Método `build()`
- **Severidad:** 🟠 **High**
- **Categoría:** Rendimiento de CPU & Tasa de Cuadros (Jank)
- **Archivo Afectado:** `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (Líneas 1050, 1750–1858)
- **Causa Raíz y Explicación Técnica:**
  Dentro de `_buildBiometryTab` (que se ejecuta en cada repintado de la pantalla de bitácora), se ejecuta síncronamente:
  ```dart
  final analysis = _BiometryAnalysis.compute(
    allBiometries: pondsState.biometries,
    batches: pondsState.batches,
    selectedPondId: _selectedPondId,
  );
  ```
  La rutina `_BiometryAnalysis.compute` itera miles de registros históricos de pesajes, calcula ganancias de peso diarias promedio (GDP en g/día), deltas de biomasa, genera cuatro mapas en memoria y ordena las listas descendentemente mediante `sort()`.
- **Evaluación de Impacto:**
  Ejecución de un algoritmo $O(N \log N)$ directamente en el hilo principal de la interfaz de usuario (Root UI Isolate). Provoca caídas notorias de frames (jank de 80–200 ms) cada vez que el operario cambia de pestaña o interactúa con el teclado.
- **Solución Concreta / Código Diff (Dart):**
  Mover el cálculo a un proveedor Riverpod memoizado (`Provider.family`):
  ```dart
  // En lib/modules/ponds_batches/presentation/providers/ponds_provider.dart
  final biometryAnalysisProvider = Provider.family.autoDispose<BiometryAnalysis, String?>((ref, selectedPondId) {
    final biometries = ref.watch(pondsProvider.select((s) => s.biometries));
    final batches = ref.watch(pondsProvider.select((s) => s.batches));

    return BiometryAnalysis.compute(
      allBiometries: biometries,
      batches: batches,
      selectedPondId: selectedPondId,
    );
  });

  // En el widget de la pestaña de biometría:
  class BitacoraBiometryTab extends ConsumerWidget {
    final String? selectedPondId;
    const BitacoraBiometryTab({super.key, this.selectedPondId});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      // Consumo instantáneo en O(1) de datos memoizados
      final analysis = ref.watch(biometryAnalysisProvider(selectedPondId));
      ...
    }
  }
  ```

---

#### LEAK-01: Fuga de Memoria por `TextEditingController` No Liberado en Modal de Recuperación
- **Severidad:** 🟠 **High**
- **Categoría:** Fugas de Memoria & Ciclo de Vida de Recursos
- **Archivo Afectado:** `lib/modules/auth_tenant/presentation/screens/login_screen.dart` (Líneas 63–134)
- **Causa Raíz y Explicación Técnica:**
  En la función `_showForgotPasswordModal`:
  ```dart
  void _showForgotPasswordModal() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(...),
    );
  }
  ```
  El controlador `resetEmailCtrl` se instancia como variable local de método y se asocia a los listeners de teclado nativos. Cuando el usuario cierra el diálogo (tocando fuera, presionando atrás o enviando la solicitud), **`resetEmailCtrl.dispose()` nunca es invocado**.
- **Evaluación de Impacto:**
  Fuga permanente del objeto `TextEditingController`, sus escuchas de cambio (`ChangeNotifier`) y la conexión de entrada con el subsistema de texto del sistema operativo.
- **Solución Concreta / Código Diff (Dart):**
  Liberar el controlador en el callback `whenComplete` del diálogo:
  ```dart
  // En lib/modules/auth_tenant/presentation/screens/login_screen.dart
  void _showForgotPasswordModal() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        child: _ForgotPasswordDialogContent(controller: resetEmailCtrl),
      ),
    ).whenComplete(() {
      resetEmailCtrl.dispose(); // Liberación garantizada de memoria
    });
  }
  ```

---

#### LEAK-02: Condición de Carrera y Fallo en `VideoBackgroundWidget` por Uso Post-Dispose
- **Severidad:** 🟠 **High**
- **Categoría:** Fugas de Hardware & Ciclo de Vida Asíncrono
- **Archivo Afectado:** `lib/core/design_system/video_background_widget.dart` (Líneas 32–53)
- **Causa Raíz y Explicación Técnica:**
  En `_VideoBackgroundWidgetState`:
  ```dart
  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.assetPath);
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0);
      await _controller.play();
      if (mounted) setState(() => _isInitialized = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  ```
  Si el usuario navega rápidamente fuera de la pantalla de bienvenida antes de que termine el `await _controller.initialize()`, `dispose()` se invoca de inmediato. Cuando el `Future` de inicialización despierta en el bucle de eventos, intenta llamar a `setLooping(true)` y `play()` sobre un controlador que ya fue destruido.
- **Evaluación de Impacto:**
  Excepción no controlada `Bad state: Cannot use a VideoPlayerController after it has been disposed.`, fugas de decodificadores nativos de hardware en Android/iOS y potenciales bloqueos en el hilo multimedia.
- **Solución Concreta / Código Diff (Dart):**
  Comprobar `if (!mounted)` después de cada paso asíncrono y declarar el controlador como nullable:
  ```dart
  // En lib/core/design_system/video_background_widget.dart
  class _VideoBackgroundWidgetState extends State<VideoBackgroundWidget> {
    VideoPlayerController? _controller;
    bool _isInitialized = false;

    @override
    void initState() {
      super.initState();
      _initializeVideo();
    }

    Future<void> _initializeVideo() async {
      final controller = VideoPlayerController.asset(widget.assetPath);
      _controller = controller;
      try {
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        await controller.setLooping(true);
        await controller.setVolume(0.0);
        await controller.play();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } catch (_) {}
    }

    @override
    void dispose() {
      _controller?.dispose();
      _controller = null;
      super.dispose();
    }
  }
  ```

---

#### PERF-02: Bloqueo del Hilo Principal por Compresión Síncrona de Archivos Excel en `IcaOfficialReportsEngine`
- **Severidad:** 🟠 **High**
- **Categoría:** Rendimiento de CPU & Experiencia de Usuario
- **Archivos Afectados:**
  - `lib/core/reports/ica_official_reports_engine.dart` (Líneas 949–981)
  - `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart` (Línea 482)
- **Causa Raíz y Explicación Técnica:**
  Al presionar "Exportar Cuaderno de Campo Completo", el motor construye 9 hojas de cálculo, recorre celda por celda miles de registros zootécnicos y sanitarios, y ejecuta la compresión en formato ZIP OpenXML invocando `excel.save()` de forma 100% síncrona en el hilo principal de Dart (Root Isolate).
- **Evaluación de Impacto:**
  Congelamiento total de la aplicación durante 1.5 a 4.0 segundos en dispositivos móviles. En dispositivos Android modestos, esto dispara frecuentemente el cuadro de diálogo del sistema **ANR** ("Application Not Responding: ¿Desea esperar o cerrar la app?").
- **Solución Concreta / Código Diff (Dart):**
  Mover la serialización y compresión a un isolate en segundo plano mediante `compute()` o `Isolate.run()`:
  ```dart
  // En lib/core/reports/ica_official_reports_engine.dart
  Future<void> exportCuadernoCampoCompletoAsync() async {
    final payload = _buildExportPayload();
    
    // Ejecución off-thread en worker isolate:
    final bytes = await compute(_generateExcelBytesTask, payload);

    if (bytes != null) {
      if (kIsWeb) {
        downloadFileWeb(bytes, 'Cuaderno_Campo_Oficial_ICA.xlsx');
      } else {
        await saveAndShareFileMobile(bytes, 'Cuaderno_Campo_Oficial_ICA.xlsx');
      }
    }
  }
  ```

---

#### DB-01: Tormenta de 5 Consultas Paralelas y Reseteo Destructivo de UI en `PondsNotifier`
- **Severidad:** 🟠 **High**
- **Categoría:** Eficiencia de Base de Datos & Resiliencia Visual
- **Archivo Afectado:** `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart` (Líneas 173–182, 289–296, 340–346)
- **Causa Raíz y Explicación Técnica:**
  Al registrar una mortalidad o un muestreo de peso, el notificador inserta el registro en memoria y luego ejecuta `await loadPondsAndBatches()`. En ese método:
  ```dart
  state = state.copyWith(isLoading: true, errorMessage: null);
  final results = await Future.wait([
    _repository.fetchPondsByUnit(empresaId, finalUnitId),
    _repository.fetchBatchesByUnit(empresaId, finalUnitId),
    _repository.fetchBiometriesByUnit(empresaId, finalUnitId),
    _repository.fetchMortalityByUnit(empresaId, finalUnitId),
    _repository.fetchTransfersByUnit(empresaId, finalUnitId),
  ]);
  ```
- **Evaluación de Impacto:**
  Al activar `isLoading: true`, toda la pantalla de estanques se desmonta, mostrando un spinner de carga en blanco. Cada registro elemental de 3 peces muertos satura la conexión celular con **5 peticiones masivas en paralelo** a Supabase para volver a descargar todo el historial.
- **Solución Concreta / Código Diff (Dart):**
  Implementar actualización optimista local de los lotes y estanques afectados sin activar `isLoading: true` ni descargar las 5 tablas:
  ```dart
  // En PondsNotifier.recordMortality:
  final updatedPonds = state.ponds.map((p) => p.id == estanqueId ? p.copyWith(biomasaKg: newBiomass) : p).toList();
  final updatedBatches = state.batches.map((b) => b.id == loteId ? b.copyWith(cantidadActualPeces: newCount, biomasaActualKg: newBiomass) : b).toList();

  state = state.copyWith(
    mortalityRecords: [savedRecord, ...state.mortalityRecords],
    ponds: updatedPonds,
    batches: updatedBatches,
    // NO poner isLoading: true ni invocar loadPondsAndBatches()
  );
  ```

---

#### DB-02: Consultas No Acotadas Sin `.limit()` en Tablas de Crecimiento Infinito
- **Severidad:** 🟠 **High**
- **Categoría:** Optimización de Consultas SQL & Tráfico de Red
- **Archivo Afectado:** `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (Líneas 191–196, 259–264)
- **Causa Raíz y Explicación Técnica:**
  Las consultas de carga de estanques y lotes no contienen límite de filas ni filtros por ciclo activo:
  ```dart
  final res = await _supabase
      .from('lotes')
      .select('*')
      .eq('empresa_id', empresaId)
      .order('creado_en', ascending: true);
  ```
- **Evaluación de Impacto:**
  En una empresa con dos o tres años de operación continua, la aplicación descarga cientos de lotes ya cosechados y cerrados. Esto ralentiza el inicio en redes 3G/4G rurales y causa un alto consumo de memoria RAM en el cliente.
- **Solución Concreta / Código Diff (Dart):**
  Filtrar por defecto por lotes en curso y aplicar un límite de seguridad razonable:
  ```dart
  final res = await _supabase
      .from('lotes')
      .select('*')
      .eq('empresa_id', empresaId)
      .inFilter('estado', ['Activo', 'En Engorde', 'Pre-cria', 'Alevinaje'])
      .order('creado_en', ascending: false)
      .limit(100);
  ```

---

#### DB-09: Degradación de Planes de Ejecución RLS por Cláusula Disyuntiva `OR` con Superadmin
- **Severidad:** 🟠 **High**
- **Categoría:** Planes de Ejecución PostgreSQL & Optimización RLS
- **Archivo Afectado:** `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Líneas 205–208, 242–245)
- **Causa Raíz y Explicación Técnica:**
  Las políticas de seguridad en tablas críticas están formuladas como:
  ```sql
  CREATE POLICY parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));
  ```
  En PostgreSQL, una política RLS con una disyunción `OR` impide que el planificador realice un escaneo de índice B-Tree directo sobre `empresa_id`, porque el optimizador no puede descartar filas sin evaluar si la condición de superadmin abre el acceso global.
- **Evaluación de Impacto:**
  Pérdida de eficiencia en todas las lecturas de los usuarios estándar, multiplicando los buffers compartidos leídos (*shared buffer hits*) por un factor de 2x a 5x y degradando el tiempo de respuesta de las consultas.
- **Solución Concreta / Código Diff (SQL):**
  Dividir la regla en dos políticas independientes de tipo `PERMISSIVE`:
  ```sql
  -- Migración: supabase/migrations/20260913_fix_db09_rls_split_policies.sql
  DROP POLICY IF EXISTS parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua;

  -- Política 1: Index Scan puro para usuarios de la empresa
  CREATE POLICY parametros_calidad_agua_tenant_select ON public.parametros_calidad_agua
    FOR SELECT TO authenticated
    USING (empresa_id = (SELECT public.get_auth_empresa_id()));

  -- Política 2: Bypass limpio para superadministradores
  CREATE POLICY parametros_calidad_agua_superadmin_select ON public.parametros_calidad_agua
    FOR SELECT TO authenticated
    USING ((SELECT public.is_superadmin()));
  ```



## 4. Parte II: Hallazgos de Prioridad Media (P2)

Esta sección aborda code smells arquitectónicos, ineficiencias de estado reactivo, fricciones ergonómicas en flujos secundarios, anomalías en modelos de datos duales y oportunidades de optimización de consultas.

### 4.1 Desglose Detallado de Hallazgos de Prioridad Media

#### SEC-08: Seguridad por Oscuridad en Rutas Administrativas y de Nómina del Cliente
- **Severidad:** 🟡 **Medium**
- **Categoría:** Autorización & Guardias de Enrutamiento
- **Archivos Afectados:**
  - `lib/app/router.dart` (Líneas 102–138)
  - `lib/core/design_system/glass_action_hub_sheet.dart` (Líneas 142–165)
  - `lib/modules/finance_payroll/presentation/screens/finance_screen.dart` (Líneas 1–100)
  - `lib/modules/auth_tenant/presentation/screens/gestion_equipo_screen.dart` (Líneas 1–35)
- **Causa Raíz y Explicación Técnica:**
  Las restricciones de acceso por rol (`role == UserRole.admin || role == UserRole.creator`) solo están implementadas a nivel visual en `GlassActionHubSheet` ocultando los botones ("Nómina y Costos", "Gestión de Equipo"). En `router.dart`, las rutas `/finance`, `/team` y `/sales` no poseen ningún guardia de autorización. Cualquier operario de campo o técnico puede ingresar a estas rutas escribiendo la URL en el navegador (Flutter Web) o mediante deep-linking.
- **Evaluación de Impacto:**
  Visualización no autorizada de salarios, costos de mano de obra y directorios de empleados por parte de personal no administrativo.
- **Solución Concreta / Código Diff (Dart):**
  Incorporar validación estricta de roles en la función `redirect` de GoRouter:
  ```dart
  // En lib/app/router.dart
  final role = authState.user?.role;
  final isAdmin = role == UserRole.admin || role == UserRole.creator || role == UserRole.master;

  final adminOnlyRoutes = ['/finance', '/team', '/saas-console'];
  if (adminOnlyRoutes.contains(state.matchedLocation) && !isAdmin) {
    return '/'; // Redirección inmediata al dashboard operativo
  }
  ```

---

#### SEC-09: Almacenamiento de Tokens de Sesión en Texto Plano sin Cifrado
- **Severidad:** 🟡 **Medium**
- **Categoría:** Criptografía & Almacenamiento Seguro
- **Archivos Afectados:**
  - `lib/core/storage/local_storage_service.dart` (Líneas 45–59)
  - `lib/main.dart` (Líneas 43–47)
- **Causa Raíz y Explicación Técnica:**
  `LocalStorageService` define una instancia de `FlutterSecureStorage`, pero `Supabase.initialize` se invoca sin pasar un `authOptions` personalizado. Por defecto, `supabase_flutter` persiste los tokens de refresco y JWT en `SharedPreferences` no cifrado en Android (XML en `/data/data/...`) o `localStorage` en Web.
- **Evaluación de Impacto:**
  En dispositivos Android rooteados o mediante volcados de backup físico del terminal, un atacante o malware local puede extraer el refresh token permanente de Supabase y perpetuar el acceso sin autenticación.
- **Solución Concreta / Código Diff (Dart):**
  Implementar un adaptador de almacenamiento seguro para Supabase:
  ```dart
  // En lib/main.dart
  class SecureSupabaseStorage extends LocalStorage {
    final _secureStorage = const FlutterSecureStorage();
    @override
    Future<void> initialize() async {}
    @override
    Future<String?> accessToken() => _secureStorage.read(key: supabasePersistSessionKey);
    @override
    Future<void> persistSession(String session) => _secureStorage.write(key: supabasePersistSessionKey, value: session);
    @override
    Future<void> removePersistedSession() => _secureStorage.delete(key: supabasePersistSessionKey);
    @override
    Future<bool> hasAccessToken() => _secureStorage.containsKey(key: supabasePersistSessionKey);
  }

  // En la inicialización:
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthOptions(
      localStorage: SecureSupabaseStorage(),
      authFlowType: AuthFlowType.pkce,
    ),
  );
  ```

---

#### SEC-10: URL y Anon Key de Producción Cableadas como Valores por Defecto
- **Severidad:** 🟡 **Medium**
- **Categoría:** Gestión de Configuración & Separación de Entornos
- **Archivo Afectado:** `lib/main.dart` (Líneas 33–41)
- **Causa Raíz y Explicación Técnica:**
  En `main.dart`:
  ```dart
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oakovawlwjpnoydpwtam.supabase.co',
  );
  ```
  La URL y clave anónima del proyecto real de producción están incrustadas como valores fallback por defecto.
- **Evaluación de Impacto:**
  Cualquier desarrollador que ejecute `flutter run` sin especificar parámetros `--dart-define` se conecta y muta directamente la base de datos de producción, arriesgando la integridad de datos de clientes reales durante tareas de desarrollo o pruebas locales.
- **Solución Concreta / Código Diff (Dart):**
  Requerir obligatoriamente los flags y emitir aserción en compilación:
  ```dart
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  void main() {
    assert(supabaseUrl.isNotEmpty, 'Debe proveer SUPABASE_URL mediante --dart-define');
    assert(supabaseAnonKey.isNotEmpty, 'Debe proveer SUPABASE_ANON_KEY mediante --dart-define');
    ...
  }
  ```

---

#### ARCH-05: Anti-Patrón de Esquema Dividido (Dual-Schema Split Brain)
- **Severidad:** 🟡 **Medium**
- **Categoría:** Modelado de Datos & Coherencia de Esquema
- **Archivos Afectados:**
  - `supabase_schema_canonical_v10.sql`
  - `20260831_database_performance_and_rls_optimization.sql`
  - Múltiples repositorios en `lib/modules/`
- **Causa Raíz y Explicación Técnica:**
  La base de datos mantiene tablas duplicadas y desalineadas:
  - Nomenclatura en inglés legacy: `units`, `inventory`, `ventas`, `siembras`.
  - Nomenclatura en español canónica v10: `unidades_acuicolas`, `inventario_insumos`, `ventas_lotes`, `lotes`.
  Los repositorios ejecutan consultas con doble intento (si la primera tabla falla, intentan la segunda), duplicando los round-trips HTTP.
- **Evaluación de Impacto:**
  Complejidad innecesaria, ambigüedad en migraciones y riesgo de bifurcación de datos (datos guardados en una tabla pero leídos de la otra).
- **Solución Concreta / Código Diff (SQL & Dart):**
  Consolidar formalmente en el esquema v10 en español y eliminar los fallbacks legacy del cliente Flutter.

---

#### ARCH-06: Clases Dios Monolíticas en la Capa de Presentación
- **Severidad:** 🟡 **Medium**
- **Categoría:** Arquitectura Limpia & Mantenibilidad
- **Archivos Afectados:**
  - `lib/modules/bitacora/presentation/screens/bitacora_screen.dart` (1,860 líneas)
  - `lib/core/reports/ica_official_reports_engine.dart` (1,513 líneas)
- **Causa Raíz y Explicación Técnica:**
  `BitacoraScreen` concentra en un solo archivo de 1,860 líneas la lógica de renderizado de gráficos, modales, formularios y formateadores de 4 dominios zootécnicos distintos. `IcaOfficialReportsEngine` concentra 12 reportes normativos en 1,513 líneas continuas de manipulación de celdas.
- **Evaluación de Impacto:**
  Alta deuda técnica, propensión a conflictos de merge en Git y dificultad extrema para testing unitario.
- **Solución Concreta / Código Diff (Dart):**
  Descomponer `BitacoraScreen` en 4 módulos hijos dentro de una carpeta `widgets/tabs/` y crear una interfaz `IcaReportStrategy` para cada formato de exportación ICA.

---

#### ARCH-07: Código Muerto en Arquitectura de Almacenamiento Offline
- **Severidad:** 🟡 **Medium**
- **Categoría:** Calidad de Código & Higiene del Repositorio
- **Archivo Afectado:** `lib/core/storage/offline_sync_queue.dart` (Líneas 51–132)
- **Causa Raíz y Explicación Técnica:**
  La clase `OfflineSyncQueue` implementa un buffer de operaciones offline con SQLite/SharedPreferences, pero no está conectada ni referenciada en ninguna parte de `lib/`. Coexiste con soluciones ad-hoc en otros módulos (ej. caché JSON manual en ICA y arrays estáticos en memoria en `ponds_batches`).
- **Evaluación de Impacto:**
  Confusión para nuevos desarrolladores y ausencia de una política uniforme de sincronización offline en la plataforma.
- **Solución Concreta / Código Diff (Dart):**
  Centralizar la resiliencia offline conectando `OfflineSyncQueue` en los repositorios de nutrición, estanques y calidad de agua.

---

#### ARCH-08: Ruta de Navegación Rota en `RegisterCompanyScreen`
- **Severidad:** 🟡 **Medium**
- **Categoría:** Navegación & Control de Flujo
- **Archivo Afectado:** `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart` (Línea 104)
- **Causa Raíz y Explicación Técnica:**
  Al finalizar la creación de una empresa:
  ```dart
  context.go('/home');
  ```
  En `lib/app/router.dart`, la ruta registrada para el dashboard principal es `/` (`HomeDashboardScreen`). La ruta `/home` no existe en la tabla de rutas.
- **Evaluación de Impacto:**
  Al completar el registro de la granja, GoRouter arroja un error 404 o muestra la pantalla de ruta no encontrada, degradando la primera impresión del usuario en su proceso de onboarding.
- **Solución Concreta / Código Diff (Dart):**
  Corregir el destino de navegación a la raíz registrada:
  ```dart
  // En register_company_screen.dart:104
  context.go('/');
  ```

---

#### ARCH-09: Exportación de Archivos Excel Inoperativa en Dispositivos Móviles
- **Severidad:** 🟡 **Medium**
- **Categoría:** Compatibilidad Multiplataforma
- **Archivos Afectados:**
  - `lib/core/reports/ica_official_reports_engine.dart` (Líneas 53–58)
  - `lib/core/reports/web_download_helper_stub.dart` (Líneas 1–5)
- **Causa Raíz y Explicación Técnica:**
  El método `_downloadExcel` solo funciona en Flutter Web. Para plataformas móviles (Android e iOS), el archivo `web_download_helper_stub.dart` contiene una función vacía:
  ```dart
  void downloadFileWeb(List<int> bytes, String fileName) {
    // Stub vacío en móviles
  }
  ```
- **Evaluación de Impacto:**
  Los productores piscícolas que utilizan la app en teléfonos y tablets no pueden exportar ni compartir sus reportes oficiales ICA, impidiendo la presentación de cuadernos de campo a inspectores sanitarios.
- **Solución Concreta / Código Diff (Dart):**
  Implementar la persistencia nativa con `path_provider` y `share_plus`:
  ```dart
  // En lib/core/reports/mobile_download_helper.dart
  import 'dart:io';
  import 'package:path_provider/path_provider.dart';
  import 'package:share_plus/share_plus.dart';

  Future<void> saveAndShareFileMobile(List<int> bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte Oficial ICA - $fileName');
  }
  ```

---

#### UX-06: Desbordamiento del Action Hub Sheet por Relación de Aspecto Rígida
- **Severidad:** 🟡 **Medium**
- **Categoría:** Responsividad Visual & Escala de Fuentes
- **Archivo Afectado:** `lib/core/navigation/glass_action_hub_sheet.dart` (Líneas 123–130)
- **Causa Raíz y Explicación Técnica:**
  El selector rápido central utiliza una cuadrícula fija:
  ```dart
  GridView.count(
    crossAxisCount: 2,
    childAspectRatio: 1.45,
    children: [...],
  )
  ```
- **Evaluación de Impacto:**
  En teléfonos de 360 dp o con accesibilidad de texto ampliada (>1.2x), el contenido vertical de cada celda (icono de 38 dp + título negrita + descripción de 2 líneas) no cabe en la tarjeta y produce desbordamiento de píxeles (`RenderFlex`).
- **Solución Concreta / Código Diff (Dart):**
  Calcular el aspect ratio dinámicamente en base al factor de escala de texto del sistema:
  ```dart
  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
  final dynamicAspectRatio = (1.45 / textScale).clamp(1.1, 1.5);

  GridView.count(
    crossAxisCount: 2,
    childAspectRatio: dynamicAspectRatio,
    ...
  )
  ```

---

#### UX-07: Extensión Fija en la Grilla de Estanques Corta Banners de Retiro y Policultivo
- **Severidad:** 🟡 **Medium**
- **Categoría:** Layout & Flexibilidad de Contenido
- **Archivo Afectado:** `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Línea 297)
- **Causa Raíz y Explicación Técnica:**
  La grilla de estanques fija la altura de las tarjetas mediante `mainAxisExtent: 380`.
- **Evaluación de Impacto:**
  Cuando un estanque presenta policultivo (Tilapia + Cachama) o una alerta de periodo de retiro de medicamentos ICA (banner amarillo superior), la tarjeta requiere 420 dp de alto. Al estar fijada a 380 dp, los botones inferiores se cortan o quedan parcialmente fuera de la pantalla.
- **Solución Concreta / Código Diff (Dart):**
  Aumentar `mainAxisExtent` a 430 dp o emplear un sliver con altura intrínseca dinámica (`SliverCrossAxisGroup`).

---

#### UX-08: Estados Vacíos Mudos Sin Llamada a la Acción (CTA)
- **Severidad:** 🟡 **Medium**
- **Categoría:** Experiencia de Usuario & Flujo Guiado
- **Archivo Afectado:** `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Líneas 284–289)
- **Causa Raíz y Explicación Técnica:**
  Cuando no hay estanques en una categoría o la búsqueda no tiene resultados, se muestra un texto simple en gris (`Text('No hay estanques en esta categoría')`) sin icono, ilustración ni botón de acción.
- **Evaluación de Impacto:**
  Sensación de pantalla inerte o fallo en la carga, desorientando al usuario recién registrado.
- **Solución Concreta / Código Diff (Dart):**
  Implementar un componente reutilizable `FishBitEmptyState` con botón directo para crear el primer estanque o limpiar el filtro de búsqueda.

#### UX-09: Micro Blancos Táctiles en Date Pickers, Chips de Porcentaje y Filtros
- **Severidad:** 🟡 **Medium**
- **Categoría:** Ergonomía & Criterio WCAG 2.5.5 / 2.5.8
- **Archivos Afectados:**
  - `lib/core/design_system/glass_date_picker.dart` (Línea 318)
  - `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Línea 385)
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart` (Línea 608)
  - `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (Línea 175)
- **Causa Raíz y Explicación Técnica:**
  Diversos componentes táctiles clave disponen de áreas físicas muy por debajo de los estándares ergonómicos:
  - Celdas de días en el selector de fecha con altura de ~30 dp.
  - Chips de filtrado de estanques con padding vertical de 4 dp (altura total ~19 dp).
  - Chips de selección rápida de porcentaje de traslado (25%, 50%, 75%, 100%) con altura de ~16 dp.
  - Botón de giro 3D en la esquina de la tarjeta Bento con dimensiones de apenas 23×23 dp.
- **Evaluación de Impacto:**
  Frustración operativa en campo. Los operarios con dedos gruesos o guantes húmedos presionan repetidamente sin éxito o seleccionan porcentajes equivocados.
- **Solución Concreta / Código Diff (Dart):**
  Expandir los contenedores táctiles mediante `padding` intrínseco o `MaterialTapTargetSize.padded` garantizando un mínimo de 44×44 dp.

---

#### UX-10: Sobrecarga de Shaders Glassmorphism y Falta de Perfil de Alto Contraste Solar
- **Severidad:** 🟡 **Medium**
- **Categoría:** Ergonomía Outdoor & Rendimiento Térmico
- **Archivos Afectados:**
  - `lib/core/design_system/glass_card.dart` (Líneas 73–82)
  - `lib/core/design_system/glass_container.dart` (Líneas 67–75)
  - `lib/core/design_system/fishbit_header.dart` (Línea 62)
- **Causa Raíz y Explicación Técnica:**
  El diseño Glassmorphism depende de bordes con opacidades sutiles (`Colors.white.withValues(alpha: 0.12)`) y fondos translúcidos.
- **Evaluación de Impacto:**
  Bajo radiación solar directa a mediodía (>25.000 lux), el contraste percibido se desvanece por completo. Las tarjetas parecen fundirse con el fondo y los bordes son invisibles.
- **Solución Concreta / Código Diff (Dart):**
  Incorporar un selector de "Modo Exterior / Alto Contraste" en ajustes que desactive el desenfoque y aplique fondos oscuros sólidos con bordes cian de 1.5 dp (`#00E5FF`).

---

#### A11Y-03: Indicadores de Estado Dependientes Exclusivamente de Color (WCAG 1.4.1)
- **Severidad:** 🟡 **Medium**
- **Categoría:** Accesibilidad Visual & Daltonismo
- **Archivos Afectados:**
  - `lib/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart` (Línea 150)
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart` (Línea 312)
- **Causa Raíz y Explicación Técnica:**
  En `home_dashboard_screen.dart:150`, la salud sanitaria del estanque se representa únicamente mediante un punto circular de color (`Icon(Icons.circle, color: statusColor, size: 8)`). En `mortalidad_modal.dart:312`, el chip de severidad crítica muestra texto negro sobre fondo `#FF2D55` (ratio de contraste 4.2:1, fallando el estándar AA de 4.5:1).
- **Evaluación de Impacto:**
  Usuarios con daltonismo (deuteranopía o protanopía) no pueden distinguir entre un estanque en alerta sanitaria (amarillo/naranja) y uno óptimo (verde).
- **Solución Concreta / Código Diff (Dart):**
  Acompañar los colores con formas geométricas diferenciadas (círculo = óptimo, triángulo = alerta, octágono = crítico) y forzar texto blanco sobre fondos rojos intensos.

---

#### STATE-03: Sobresuscripción Masiva y Re-instanciación Redundante en `IcaCertificationScreen`
- **Severidad:** 🟡 **Medium**
- **Categoría:** Estado Reactivo & Garbage Collection
- **Archivos Afectados:**
  - `lib/modules/ica_compliance/presentation/screens/ica_certification_screen.dart` (Líneas 47–52)
  - `lib/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart` (Líneas 22–50)
- **Causa Raíz y Explicación Técnica:**
  La pantalla escucha 6 proveedores simultáneamente con `ref.watch()`. Entre ellos, `icaReportsEngineProvider` se invalida con cualquier mutación global del ERP y se reconstruye copiando 10 listas de memoria, a pesar de que el motor de reportes solo se necesita en los callbacks `onPressed` de los botones de descarga.
- **Evaluación de Impacto:**
  Múltiples ciclos de Garbage Collection y repintados redundantes de la pantalla de auditoría ICA.
- **Solución Concreta / Código Diff (Dart):**
  Eliminar `ref.watch(icaReportsEngineProvider)` del método `build()` y obtener la referencia en el evento mediante `ref.read(icaReportsEngineProvider)`.

---

#### STATE-04: Reconstrucciones Totales por Estado Efímero en `PondsDashboardScreen`
- **Severidad:** 🟡 **Medium**
- **Categoría:** Estado Local & Rendimiento de Widgets
- **Archivo Afectado:** `lib/modules/ponds_batches/presentation/screens/ponds_dashboard_screen.dart` (Líneas 27–28, 144, 381)
- **Causa Raíz y Explicación Técnica:**
  La variable booleana `_isSpeedDialOpen` (apertura del menú de botones flotantes) y el índice `_selectedFilterIndex` están declarados en el estado de la pantalla raíz. Al tocar el FAB, se ejecuta `setState(() => _isSpeedDialOpen = !_isSpeedDialOpen);`.
- **Evaluación de Impacto:**
  Reconstrucción completa de la cabecera, los KPIs globales de biomasa y las tarjetas Bento de toda la granja ante la simple animación de apertura de un menú flotante.
- **Solución Concreta / Código Diff (Dart):**
  Extraer el FAB animado a un widget independiente `PondsSpeedDialFab` con su propio estado interno encapsulado.

---

#### STATE-05: Doble Construcción Incondicional de Cara Frontal y Trasera en `PondBentoCard`
- **Severidad:** 🟡 **Medium**
- **Categoría:** Árbol de Renderizado & Optimización de Layout
- **Archivo Afectado:** `lib/modules/ponds_batches/presentation/widgets/pond_bento_card.dart` (Líneas 81–90)
- **Causa Raíz y Explicación Técnica:**
  En cada frame de renderizado de la tarjeta:
  ```dart
  final frontWidget = RepaintBoundary(child: _buildFrontCard(...));
  final backWidget = Transform(..., child: RepaintBoundary(child: _buildBackCard(...)));
  ```
  Aunque la tarjeta esté en reposo mostrando solo su cara frontal (ángulo 0°), el método `_buildBackCard` (con más de 250 líneas de widgets) se evalúa y construye incondicionalmente en memoria.
- **Evaluación de Impacto:**
  Duplica el costo de instanciación del árbol de widgets en el dashboard (una granja con 20 estanques procesa 40 tarjetas complejas simultáneas).
- **Solución Concreta / Código Diff (Dart):**
  Construir la cara trasera de forma diferida (*lazy rendering*) evaluando si el controlador de animación ha iniciado su giro (`_controller.value > 0.0`).

---

#### LEAK-03: Uso de `BuildContext` Desactivado Tras Navegación Asíncrona
- **Severidad:** 🟡 **Medium**
- **Categoría:** Ciclo de Vida de Contextos Flutter
- **Archivos Afectados:**
  - `lib/modules/auth_tenant/presentation/screens/register_company_screen.dart` (Líneas 103–105)
  - `lib/modules/auth_tenant/presentation/screens/onboarding_empresa_screen.dart` (Líneas 127–128)
- **Causa Raíz y Explicación Técnica:**
  Inmediatamente después de ordenar la navegación con `context.go('/home')` o `context.go('/')`, el código invoca `ScaffoldMessenger.of(context).showSnackBar(...)` utilizando el `BuildContext` del widget que acaba de ser desmontado del árbol.
- **Evaluación de Impacto:**
  Excepción de Flutter en modo desarrollo (`Looking up a deactivated widget's ancestor is unsafe`) y pérdida de la notificación de confirmación para el usuario.
- **Solución Concreta / Código Diff (Dart):**
  Capturar la referencia al `ScaffoldMessenger.of(context)` **antes** de disparar la navegación:
  ```dart
  if (success && mounted) {
    final messenger = ScaffoldMessenger.of(context);
    context.go('/');
    messenger.showSnackBar(
      const SnackBar(content: Text('Empresa registrada con éxito')),
    );
  }
  ```

---

#### DB-04: Doble Escritura HTTP Secuencial en el Flujo de Cosechas y Ventas
- **Severidad:** 🟡 **Medium**
- **Categoría:** Rendimiento de Red & Consistencia Eventual
- **Archivo Afectado:** `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart` (Líneas 90–97)
- **Causa Raíz y Explicación Técnica:**
  Al registrar una venta de pescado:
  ```dart
  try {
    await _supabase.from('ventas').insert(ventaPayload);
  } catch (_) {}

  try {
    await _supabase.from('ventas_lotes').insert(sale.toJson());
  } catch (_) {}
  ```
  La app emite dos peticiones POST consecutivas a través de internet para duplicar el registro en la tabla antigua (`ventas`) y en la nueva (`ventas_lotes`).
- **Evaluación de Impacto:**
  Duplica innecesariamente el tiempo de espera del usuario (sumando 400–800 ms de latencia) y arriesga inconsistencia si la primera inserción pasa pero la segunda falla por pérdida de señal.
- **Solución Concreta / Código Diff (SQL & Dart):**
  Eliminar la inserción en `ventas` desde el cliente móvil. Si se requiere sincronización con software contable legacy, delegarla a un trigger en PostgreSQL:
  ```sql
  CREATE OR REPLACE FUNCTION trg_sync_legacy_ventas()
  RETURNS TRIGGER AS $$
  BEGIN
    INSERT INTO public.ventas (id, empresa_id, lote_id, kilos, total)
    VALUES (NEW.id, NEW.empresa_id, NEW.lote_id, NEW.kilos_totales, NEW.total_venta);
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;
  ```

---

#### DB-05: Consultas Ineficientes de Traslados por Estanque en `traslados_lotes`
- **Severidad:** 🟡 **Medium**
- **Categoría:** Optimización de Índices & Disyunciones SQL
- **Archivos Afectados:**
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart` (Líneas 509–516)
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Líneas 117–128)
- **Causa Raíz y Explicación Técnica:**
  En `fetchTransfersByUnit`:
  ```dart
  if (pondId != null && pondId.isNotEmpty) {
    query = query.or('estanque_origen_id.eq.$pondId,estanque_destino_id.eq.$pondId');
  }
  ```
  Los índices existentes son simples (`estanque_origen_id` y `estanque_destino_id`), sin incluir `empresa_id` ni `fecha_operacion DESC`.
- **Evaluación de Impacto:**
  PostgreSQL realiza un `BitmapOr` disperso seguido de un reordenamiento completo en memoria de miles de registros de traslado.
- **Solución Concreta / Código Diff (SQL):**
  Crear índices compuestos con tenant y fecha:
  ```sql
  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_traslados_empresa_origen_fecha 
    ON public.traslados_lotes (empresa_id, estanque_origen_id, fecha_operacion DESC);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_traslados_empresa_destino_fecha 
    ON public.traslados_lotes (empresa_id, estanque_destino_id, fecha_operacion DESC);
  ```

---

#### DB-07: Consultas de Red Secuenciales en Serie Durante la Hidratación de Sesión
- **Severidad:** 🟡 **Medium**
- **Categoría:** Latencia de Red & Tiempo de Arranque
- **Archivo Afectado:** `lib/modules/auth_tenant/presentation/providers/auth_provider.dart` (Líneas 136–152)
- **Causa Raíz y Explicación Técnica:**
  Al iniciar sesión o hidratar el perfil de usuario:
  ```dart
  company = await _repository.fetchCompany(targetEmpresaId);
  units = await _repository.fetchUnits(targetEmpresaId);
  team = await _repository.fetchTeamMembers(targetEmpresaId);
  ```
  Las tres consultas se realizan una detrás de otra en serie.
- **Evaluación de Impacto:**
  Multiplica por 3 el tiempo de espera en el inicio de la app, añadiendo entre 600 ms y 1.5 segundos al arranque en conexiones celulares móviles.
- **Solución Concreta / Código Diff (Dart):**
  Ejecutar las tres consultas en paralelo mediante `Future.wait`:
  ```dart
  final results = await Future.wait([
    _repository.fetchCompany(targetEmpresaId),
    _repository.fetchUnits(targetEmpresaId),
    _repository.fetchTeamMembers(targetEmpresaId),
  ]);
  company = results[0] as Company?;
  units = results[1] as List<AquacultureUnit>;
  team = results[2] as List<UserMember>;
  ```

---

#### DB-08: Clave Foránea `registrado_por` Sin Índice en Calidad de Agua y Biometrías
- **Severidad:** 🟡 **Medium**
- **Categoría:** Bloqueos en Base de Datos & Integridad Referencial
- **Archivos Afectados:**
  - `supabase_schema_canonical_v10.sql` (Línea 193)
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql` (Líneas 149–180)
- **Causa Raíz y Explicación Técnica:**
  La columna `registrado_por UUID REFERENCES public.miembros_equipo(id) ON DELETE SET NULL` no cuenta con índice B-Tree en las tablas `parametros_calidad_agua` ni `biometrias`.
- **Evaluación de Impacto:**
  Al dar de baja o actualizar un colaborador en `miembros_equipo`, PostgreSQL debe realizar un escaneo secuencial (*Seq Scan*) completo de las tablas de parámetros y pesajes para validar la clave foránea, bloqueando inserciones concurrentes de los operarios de campo.
- **Solución Concreta / Código Diff (SQL):**
  Crear los índices B-Tree correspondientes:
  ```sql
  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_calidad_agua_registrado_por 
    ON public.parametros_calidad_agua (registrado_por);

  CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_biometrias_registrado_por 
    ON public.biometrias (registrado_por);
  ```



## 5. Parte III: Hallazgos de Baja Prioridad y Pulido (P3 / Polish)

Esta sección documenta detalles cosméticos, discrepancias leves de configuración y mejoras menores de experiencia de usuario que no impiden el funcionamiento crítico del sistema pero elevan el estándar de calidad del software para producción.

### 5.1 Desglose de Hallazgos de Baja Prioridad

#### SEC-11: Registro No Condicional de Stack Traces y Errores de Plataforma en Consola
- **Severidad:** 🟢 **Low**
- **Categoría:** Fugas de Información & Logs de Producción
- **Archivo Afectado:** `lib/main.dart` (Líneas 14–26)
- **Causa Raíz y Explicación Técnica:**
  En los manejadores globales de captura de errores de Flutter:
  ```dart
  FlutterError.onError = (details) {
    debugPrint('Uncaught Flutter Framework Error: ${details.exceptionAsString()}');
    debugPrint('Stack: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Asynchronous Platform Error: $error');
    debugPrint('Stack: $stack');
    return true;
  };
  ```
  Los volcados de excepciones se imprimen directamente sin verificar si la aplicación se está ejecutando en modo de depuración (`kDebugMode`).
- **Evaluación de Impacto:**
  En despliegues de Flutter Web o en terminales móviles conectados mediante depurador USB o logs de sistema de Android (Logcat), se pueden filtrar rutas de archivos internas, consultas SQL fallidas o nombres de tablas a usuarios curiosos.
- **Solución Concreta / Código Diff (Dart):**
  Encapsular los logs bajo `kDebugMode` o enviarlos a un servicio de telemetría como Sentry:
  ```dart
  // En lib/main.dart
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      // Enviar de forma sanitizada a servicio de monitoreo en producción
    }
  };
  ```

---

#### ARCH-10: Persistencia Divergente y Duplicada de Preferencias de Tema
- **Severidad:** 🟢 **Low**
- **Categoría:** Consistencia de Almacenamiento Local
- **Archivos Afectados:**
  - `lib/core/design_system/theme_provider.dart` (Líneas 7, 15)
  - `lib/core/storage/local_storage_service.dart` (Líneas 16, 38)
- **Causa Raíz y Explicación Técnica:**
  El notificador `ThemeModeNotifier` lee y escribe la clave `'fishbit_app_theme_mode'` como un valor booleano (`isDark`) directamente mediante `SharedPreferences.getInstance()`. Paralelamente, `LocalStorageService` define la clave `'fishbit_theme_mode'` almacenándola como una cadena de texto (`'dark'` / `'light'`).
- **Evaluación de Impacto:**
  Ruptura del principio de Única Fuente de Verdad (*Single Source of Truth*). Si un módulo guarda la preferencia a través de `LocalStorageService`, `ThemeModeNotifier` no se entera del cambio.
- **Solución Concreta / Código Diff (Dart):**
  Inyectar `LocalStorageService` en `ThemeModeNotifier` y unificar la clave bajo un único formato de persistencia:
  ```dart
  // En lib/core/design_system/theme_provider.dart
  class ThemeModeNotifier extends StateNotifier<ThemeMode> {
    final LocalStorageService _storage;
    ThemeModeNotifier(this._storage) : super(ThemeMode.dark) {
      _loadTheme();
    }

    void _loadTheme() {
      final saved = _storage.getThemeMode(); // Única fuente de verdad
      state = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    }
  }
  ```

---

#### ARCH-11: Selector "Recordarme" Decorativo No Conectado con la Sesión Real
- **Severidad:** 🟢 **Low**
- **Categoría:** Coherencia de Interfaz de Usuario
- **Archivo Afectado:** `lib/modules/auth_tenant/presentation/screens/login_screen.dart` (Líneas 27, 316–339)
- **Causa Raíz y Explicación Técnica:**
  En la pantalla de inicio de sesión existe un checkbox visual con la etiqueta "Recordarme":
  ```dart
  _RememberMeCheckbox(
    value: _rememberMe,
    onChanged: (val) => setState(() => _rememberMe = val),
  )
  ```
  Sin embargo, el valor de `_rememberMe` no es enviado al método `signInWithEmailPassword` del repositorio ni se almacena en `LocalStorageService`. Supabase persiste o no la sesión independientemente de lo que marque el usuario.
- **Evaluación de Impacto:**
  Fricción cognitiva leve. El usuario asume que desmarcar la casilla cerrará su sesión al salir de la aplicación, pero la app mantiene las credenciales guardadas en el dispositivo.
- **Solución Concreta / Código Diff (Dart):**
  Transferir el parámetro booleano al proveedor de autenticación y configurar la persistencia de Supabase en consecuencia:
  ```dart
  // En login_screen.dart al pulsar Entrar:
  ref.read(authProvider.notifier).signIn(
    email: _emailCtrl.text,
    password: _passwordCtrl.text,
    rememberMe: _rememberMe,
  );
  ```


## 6. Plan Estratégico de Remediación y Hoja de Ruta (Roadmap)

Para garantizar una transición controlada hacia la estabilidad y preparación para producción sin introducir regresiones en el entorno operativo de las piscícolas, se define un plan de implementación estructurado en cuatro fases secuenciales e independientes.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 1: P0 — Seguridad Crítica, Autenticación e Integridad de Datos (Semana 1)                 │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [SEC-01]  Crear trigger BEFORE UPDATE en public.profiles para blindar rol y superadmin.    │
│ 2. [SEC-02]  Eliminar bypass de contraseña incorrecta en signInWithEmailPassword.             │
│ 3. [SEC-03]  Eliminar fallback de sesión ficticia en registerWithInvitationToken.              │
│ 4. [SEC-05]  Purgar datos comerciales y NITs de clientes reales en saas_console_screen.dart.   │
│ 5. [SEC-06]  Añadir SET search_path = public, pg_temp en funciones SECURITY DEFINER de SQL.    │
│ 6. [SEC-07]  Incluir empresa_id obligatorio en creación de sedes acuícolas.                    │
│ 7. [UX-05]   Limpiar valores numéricos simulados en formulario de calidad de agua ICA.         │
│ 8. [DB-06]   Conectar OfflineSyncQueue con persistencia local antes de retornar en repositorios│
│ 9. [ARCH-03] Desplegar trigger de PostgreSQL para descuento atómico de stock de alimento.      │
│ 10.[ARCH-04] Crear y versionar migración SQL canónica para setup_company_for_user RPC.         │
│ 11.[STATE-06]Desacoplar GoRouter de ref.watch(authProvider) mediante refreshListenable.        │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 2: P1 — Ergonomía de Campo y Optimización de Consultas SQL (Semana 2)                     │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [UX-01]   Rediseñar botonera inferior de PondBentoCard en cuadrícula 2x2 táctil (≥48 dp).   │
│ 2. [UX-02]   Envolver dock de navegación en SafeArea y eliminar parches manuales bottom: 78.   │
│ 3. [UX-04]   Migrar modales de alimentación, biometría y bajas a showModalBottomSheet móvil.   │
│ 4. [DB-03]   Crear índices compuestos directos (empresa_id, fecha DESC) en tablas de bitácora. │
│ 5. [DB-09]   Dividir políticas RLS con cláusula OR en políticas PERMISSIVE duales.             │
│ 6. [DB-08]   Crear índices B-Tree en registrado_por (calidad agua y biometrías).               │
│ 7. [DB-01]   Implementar actualización optimista en PondsNotifier sin isLoading destructivo.   │
│ 8. [DB-02]   Aplicar filtros de estado activo y .limit(100) en fetchBatchesByUnit.             │
│ 9. [ARCH-01] Incorporar .eq('empresa_id', empresaId) en consultas de nómina, equipos y bodega. │
│ 10.[ARCH-02] Reemplazar catch (_) vacíos por tipos sellados AppFailure y reporte visual en UI. │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 3: P2 — Desacoplamiento de Estado, Ciclo de Vida y Shaders GPU (Semana 3)                 │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [PERF-01] Desactivar BackdropFilter por defecto en GlassContainer dentro de listas en scroll│
│ 2. [PERF-02] Mover compresión ZIP de reportes Excel ICA a isolate secundario con compute().    │
│ 3. [STATE-01]Desacoplar BitacoraScreen en 4 ConsumerWidgets independientes por pestaña.        │
│ 4. [STATE-02]Extraer cálculo de GDP zootécnico a un biometryAnalysisProvider memoizado.        │
│ 5. [STATE-04]Encapsular toggle de SpeedDial en widget local para evitar rebuild del dashboard. │
│ 6. [STATE-05]Implementar renderizado diferido (lazy) de cara posterior 3D en PondBentoCard.    │
│ 7. [LEAK-01] Asegurar dispose() de resetEmailCtrl en el modal de recuperación de contraseña.   │
│ 8. [LEAK-02] Blindar ciclo de vida asíncrono de VideoBackgroundWidget con guards if (!mounted). │
│ 9. [LEAK-03] Capturar ScaffoldMessenger antes de context.go() en auth y onboarding.            │
│ 10.[ARCH-06] Modularizar clases Dios de bitácora y generador de reportes ICA.                  │
│ 11.[ARCH-09] Implementar descarga y compartición nativa móvil de archivos Excel con share_plus.│
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ FASE 4: P3 — Accesibilidad WCAG 2.2, Blindaje de Rutas y Pulido Final (Semana 4)               │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. [A11Y-01] Migrar estilos de AppTypography a ThemeExtension dinámicos (contraste ≥ 4.5:1).   │
│ 2. [A11Y-02] Enlazar mensajes de error de formulario a nodos Semantics(liveRegion: true).      │
│ 3. [A11Y-03] Acompañar semáforos de estanque con iconos geométricos y alto contraste en bajas. │
│ 4. [UX-03]   Sustituir SizedBox de altura fija en PageViews por contenedores elásticos.        │
│ 5. [UX-06]   Hacer dinámico el childAspectRatio del action hub sheet ante fuentes grandes.     │
│ 6. [UX-07]   Ampliar mainAxisExtent de la grilla de estanques para soportar policultivo e ICA. │
│ 7. [UX-08]   Diseñar componentes interactivos para estados vacíos con llamada a la acción.     │
│ 8. [UX-09]   Agrandar celdas de fecha y chips de porcentaje a un mínimo de 44x44 dp.           │
│ 9. [UX-10]   Implementar selector de "Modo Exterior / Alto Contraste Solar" en configuración.  │
│ 10.[SEC-08]  Añadir guardias RBAC en router.dart para rutas /finance, /team y /saas-console.   │
│ 11.[SEC-09]  Configurar FlutterSecureStorage como backend de sesión en Supabase.initialize.    │
│ 12.[SEC-10]  Hacer obligatorios los parámetros --dart-define en compilación de producción.     │
│ 13.[SEC-11]  Sanitizar logs globales y suprimir volcados de stack en builds release.           │
│ 14.[ARCH-05] Deprecar tablas legacy en inglés y unificar acceso en esquema canónico v10.       │
│ 15.[ARCH-08] Corregir redirección post-registro a context.go('/').                             │
│ 16.[ARCH-10] Unificar persistencia de tema bajo LocalStorageService.                           │
│ 17.[ARCH-11] Conectar checkbox "Recordarme" con persistencia de credenciales de Supabase.      │
│ 18.[DB-04]   Eliminar inserción redundante en tabla legacy ventas desde el cliente.            │
│ 19.[DB-05]   Crear índices compuestos en traslados_lotes por estanque y fecha.                 │
│ 20.[DB-07]   Paralelizar carga de empresa, unidades y equipo con Future.wait en auth.          │
│ 21.[STATE-03]Consumir icaReportsEngineProvider únicamente con ref.read en eventos de botón.    │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Metodología de Verificación y Criterios de Aceptación Técnica

Para certificar formalmente la remediación de los hallazgos en fases posteriores, el equipo de ingeniería deberá validar el repositorio contra los siguientes criterios objetivos:

### 7.1 Criterios de Calidad Estática y Tipado
- Ejecución limpia de análisis de código en Flutter sin advertencias ni errores:
  ```powershell
  flutter analyze --no-fatal-infos
  ```
- Cobertura completa de pruebas unitarias sobre repositorios y notificadores:
  ```powershell
  flutter test --coverage
  ```

### 7.2 Validación de Base de Datos y Planes de Ejecución
- Comprobación de que las consultas principales utilizan Index Scan en lugar de Seq Scan:
  ```sql
  EXPLAIN ANALYZE
  SELECT * FROM public.parametros_calidad_agua
  WHERE empresa_id = 'c1000000-0000-0000-0000-000000000001'
  ORDER BY fecha DESC
  LIMIT 50;
  -- Criterio de éxito: "Index Scan using idx_calidad_agua_empresa_fecha_desc"
  -- Execution Time < 5.0 ms
  ```

### 7.3 Validación de Seguridad y RBAC
- Intento de mutación de privilegios desde sesión estándar debe ser rechazado por PostgreSQL:
  ```sql
  -- Debe arrojar error 42501 (insufficient_privilege)
  UPDATE public.profiles SET is_superadmin = true WHERE id = auth.uid();
  ```
- Intento de navegación manual a `/finance` con rol `operator` debe redirigir inmediatamente a `/`.

### 7.4 Rendimiento Gráfico en Dispositivos Reales
- Perfilado mediante Flutter DevTools (Performance View):
  - Tasa de cuadros sostenida $\ge 58$ FPS durante el scroll continuo en `PondsDashboardScreen` y `BitacoraScreen`.
  - Cero eventos de `Shader Compilation Jank` o `saveLayer` masivo en listas.
  - Ningún diálogo ANR durante la exportación de reportes ICA en Android.

---
*Informe generado y consolidado por el Master Audit Report Synthesis Worker (`worker_report_writer_1`). Todos los derechos reservados — FishBit Engineering 2026.*

