# Informe de Exploración R4: Resiliencia de Datos Offline, Manejo de Errores y Línea Base de Pruebas

**Identidad:** Survey Explorer 3 - Offline & Infra  
**Fecha:** 2026-09-13T23:44:00Z  
**Alcance:** Requerimiento R4 (DATA-02, PERF-01) y Línea Base de Pruebas/Compilación  
**Archivo de Salida:** `c:\Users\Freddy\Desktop\Desarrollo de app\FishBit\.agents\survey_explorer_3\handoff.md`

---

## 1. Observation (Observaciones Directas y Evidencia de Código)

### 1.1 Estado y Definición de `OfflineSyncQueue`
- **Ubicación:** `lib/core/storage/offline_sync_queue.dart` (Líneas 1–133).
- **Consumo en la Base de Código:** Búsqueda recursiva de `OfflineSyncQueue` en todo el directorio `lib/` arrojó **exactamente 1 resultado**: la propia declaración de clase en `lib/core/storage/offline_sync_queue.dart:51`. Ningún repositorio, servicio o widget importa ni utiliza `OfflineSyncQueue`.
- **Estructura y Tipos:**
  ```dart
  // lib/core/storage/offline_sync_queue.dart:6-11
  enum OfflineActionType {
    feeding,
    biometry,
    mortality,
    waterQuality,
  }
  ```
  La clase `OfflineSyncItem` (líneas 14–48) contiene `id` (`String`), `type` (`OfflineActionType`), `table` (`String`), `payload` (`Map<String, dynamic>`), `createdAt` (`DateTime`) y `retryCount` (`int`, default 0).
- **Mecanismo de Almacenamiento:**
  Utiliza `SharedPreferences` como motor de almacenamiento persistente (`static const _storageKey = 'fishbit_offline_sync_queue_v1';`). La cola se almacena serializada en una cadena JSON (`jsonEncode(currentQueue.map((e) => e.toJson()).toList())`). No utiliza Hive ni SQLite.
- **Lógica de Sincronización en `flushQueue`:**
  ```dart
  // lib/core/storage/offline_sync_queue.dart:97-121
  static Future<int> flushQueue(SupabaseClient supabase) async {
    final items = await getPendingItems();
    if (items.isEmpty) return 0;

    int syncedCount = 0;
    final failedItems = <OfflineSyncItem>[];

    for (final item in items) {
      try {
        await supabase.from(item.table).insert(item.payload);
        syncedCount++;
      } catch (e) {
        debugPrint('[OfflineSync] Error sincronizando elemento ${item.id} en ${item.table}: $e');
        if (item.retryCount < 5) {
          failedItems.add(OfflineSyncItem(
            id: item.id,
            type: item.type,
            table: item.table,
            payload: item.payload,
            createdAt: item.createdAt,
            retryCount: item.retryCount + 1,
          ));
        }
      }
    }
  ```
  - **Deficiencia Operativa:** Se usa `supabase.from(item.table).insert(item.payload)`. Si un registro ya existe en el servidor debido a desconexión previa durante el ack de red, `.insert` provoca violación de clave primaria (error PostgreSQL `23505`) y falla repetidamente hasta agotar los 5 reintentos. Debe ser `.upsert(item.payload)`.
  - **Falta de Disparador Reactivo:** No existe ningún servicio, listener de ciclo de vida (`WidgetsBindingObserver`), timer periódico ni listener de conectividad que ejecute `flushQueue` automáticamente.

---

### 1.2 Inspección de Repositorios Supabase Afectados

#### A. `SupabasePondsRepository` (`lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`)
- **Tamaño:** 830 líneas.
- **Mortalidad (`registerMortality`, líneas 598–709):**
  - Genera `record` en memoria (líneas 641–656).
  - Intenta inserción en tabla `'mortalidad'` (líneas 663–702).
  - Bloque de captura de error (líneas 705–708):
    ```dart
    } catch (_) {
      _demoMortalities.insert(0, record);
      return record;
    }
    ```
    *Observación directa:* No se invoca `OfflineSyncQueue.enqueue`. La acción fallida se inserta en la lista estática en memoria RAM `_demoMortalities`. Al cerrarse la app, se destruye el dato zootécnico.
- **Biometría (`registerBiometry`, líneas 712–828):**
  - Intenta inserción en tabla `'biometrias'` (líneas 781–821).
  - Bloque de captura de error (líneas 824–827):
    ```dart
    } catch (_) {
      _demoBiometries.insert(0, record);
      return record;
    }
    ```
    *Observación directa:* Misma conducta que mortalidad; el fallo se silencia y el registro queda atrapado exclusivamente en memoria volátil `_demoBiometries`.
- **Mutaciones Estanque y Lote con Fallo Silenciado (`catch (_) {}`):**
  - `updatePond` (línea 238): `catch (_) {}`
  - `deletePond` (línea 250): `catch (_) {}`
  - `updateBatch` (línea 353): `catch (_) {}`
  - `transferOrSplitBatch` (línea 486): `catch (_) {}`
- **Consultas con Retorno Vacío Silenciado:**
  - `fetchPondsByUnit` (líneas 202–204): `catch (_) { return []; }`
  - `fetchBatchesByUnit` (líneas 284–286): `catch (_) { return []; }`
  - `fetchTransfersByUnit` (líneas 522–524): `catch (_) { return _demoTransfers; }`
  - `fetchBiometriesByUnit` (líneas 557–559): `catch (_) { return []; }`
  - `fetchMortalityByUnit` (líneas 592–594): `catch (_) { return []; }`

#### B. `SupabaseWaterQualityRepository` (`lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart`)
- **Tamaño:** 131 líneas.
- **Registro de Parámetros (`recordParameters`, líneas 91–129):**
  - Inserta preventivamente en la lista volátil `_demoParameters` (línea 93).
  - Intenta inserción en tabla `'parametros_calidad_agua'` (líneas 97–125).
  - Bloque de captura de error (líneas 126–128):
    ```dart
    } catch (_) {
      return parameter;
    }
    ```
    *Observación directa:* No existe encolamiento offline ni propagación de fallo. La UI asume éxito absoluto mientras que la base de datos remota no tiene constancia de la medición.
- **Consultas Silenciadas:**
  - `fetchParametersByEstanque` (líneas 65–67): `catch (_) { return []; }`
  - `fetchRecentParametersByUnit` (líneas 86–88): `catch (_) { return []; }`

#### C. `SupabaseNutritionRepository` (`lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart`)
- **Tamaño:** 192 líneas.
- **Registro de Alimentación (`recordFeeding`, líneas 51–147):**
  - Intenta inserción en `'alimentacion_diaria'` y descuento en `'inventory'` (líneas 86–128).
  - Bloque de captura de error exterior (líneas 137–146):
    ```dart
    } catch (_) {
      _demoRecords.insert(0, record);
      _eventBus.fire(DailyFeedingRecordedEvent(
        estanqueId: estanqueId,
        loteId: loteId,
        kgConsumidos: kgConsumidos,
        costoTotal: costoTotal,
      ));
      return record;
    }
    ```
    *Observación directa:* El fallo se oculta completamente al usuario; la lista `_demoRecords` retiene el registro en RAM pero se pierde al destruir el proceso móvil. No se utiliza `OfflineSyncQueue`.
- **Otras Mutaciones y Consultas:**
  - `fetchFeedingRecords` (línea 45): `catch (_) { return []; }`
  - `fetchNutritionTables` (línea 163): `catch (_) { return _demoTables; }`
  - `saveNutritionTable` (línea 181): `catch (_) {}`
  - `deleteNutritionTable` (línea 189): `catch (_) {}`

---

### 1.3 Estado del Manejo de Errores y Tipado `AppFailure`
- **Definición en `lib/core/errors/app_failure.dart` (Líneas 1–27):**
  ```dart
  abstract class AppFailure {
    final String message;
    final String? code;
    const AppFailure(this.message, [this.code]);
    @override
    String toString() => 'AppFailure($code): $message';
  }

  class ServerFailure extends AppFailure { const ServerFailure(super.message, [super.code]); }
  class AuthFailure extends AppFailure { const AuthFailure(super.message, [super.code]); }
  class ValidationFailure extends AppFailure { const ValidationFailure(super.message, [super.code]); }
  class NotFoundFailure extends AppFailure { const NotFoundFailure(super.message, [super.code]); }
  ```
  - **Deficiencias Estructurales de `AppFailure`:**
    1. No implementa `Exception` (`abstract class AppFailure implements Exception`), lo que dificulta el uso idiomático de `throw` / `catch (AppFailure e)`.
    2. No existe `NetworkFailure` ni `OfflineFailure` para tipar específicamente desconexiones de socket o fallos de resolución DNS.
    3. No existe `StorageFailure` para tipar fallas de I/O local (SharedPreferences / SQLite).
- **Presencia de Bloques Silenciosos `catch (_)`:**
  Se detectaron más de 94 instancias de `catch (_)` en todo el proyecto:
  - Repositorios: 11 en `supabase_ponds_repository.dart`, 3 en `supabase_water_quality_repository.dart`, 7 en `supabase_nutrition_repository.dart`, 12 en `supabase_finance_repository.dart`, 3 en `supabase_equipment_repository.dart`, 5 en `supabase_sales_repository.dart`.
  - Notificadores y Modales: Los notificadores (`PondsNotifier`, `WaterQualityNotifier`, `NutritionNotifier`) disponen de la propiedad `errorMessage` en su estado, pero al tragar las excepciones los repositorios, `errorMessage` nunca se establece y los modales (`alimentar_modal.dart`, `biometria_modal.dart`, `mortalidad_modal.dart`, `parametro_modal.dart`) cierran el formulario mostrando snackbars de éxito engañosos.

---

### 1.4 Estado de Infraestructura de Pruebas y Compilación

#### A. Dependencias (`pubspec.yaml` y `analysis_options.yaml`)
- **SDK Dart/Flutter:** Dart `>=3.0.0 <4.0.0`, Flutter `>=3.10.0`.
- **Linter:** `package:flutter_lints/flutter.yaml` con reglas estrictas activadas (`strict-casts`, `strict-inference`, `strict-raw-types`, `empty_catches: true`).
- **Librerías de Conectividad:** No existe `connectivity_plus` ni `internet_connection_checker` en `pubspec.yaml`. Solo `shared_preferences` y `supabase_flutter`.

#### B. Resultado del Análisis Estático:
- **Comando Ejecutado:** `flutter analyze --no-fatal-infos`
- **Resultado:** **EXIT CODE 0**
  ```
  Analyzing FishBit...
  No issues found! (ran in 9.4s)
  ```

#### C. Resultado de la Suite de Pruebas:
- **Comando Ejecutado:** `flutter test`
- **Resultado:** **EXIT CODE 1** (`88 passed, 5 failed`).
- **Detalle de las 5 Pruebas Fallidas:**
  1. `test/modules/bitacora/bitacora_screen_test.dart:518`
     - *Error:* `Expected: exactly one matching candidate. Actual: _TextWidgetFinder:<Found 0 widgets with text "OXÍGENO ÓPTIMO": []>`.
     - *Causa:* Desalineación del texto de la etiqueta en el widget vs la expectativa del test.
  2. `test/modules/bitacora/bitacora_screen_test.dart:596`
     - *Error:* `Expected: exactly one matching candidate. Actual: _TextContainingWidgetFinder:<Found 3 widgets with text containing Estanque 02>`.
     - *Causa:* El texto "Estanque 02" aparece en el selector y en dos mensajes de estado vacío simultáneamente.
  3. `test/modules/warehouse_inventory/warehouse_inventory_test.dart:111`
     - *Error:* `Expected: 'Concentrado'. Actual: 'concentrado'`.
     - *Causa:* Discrepancia de mayúsculas/minúsculas en el enum/string de tipo de ítem de inventario.
  4. `test/modules/warehouse_inventory/warehouse_inventory_test.dart:293`
     - *Error:* `Bad state: No element` al invocar `firstWhere` en `warehouseState.items`.
  5. `test/modules/warehouse_inventory/warehouse_inventory_test.dart:344`
     - *Error:* `Bad state: No element` al invocar `firstWhere` en `warehouseState.items`.

---

## 2. Logic Chain (Cadena Lógica de Causa a Efecto)

1. **De la Observación 1.1 y 1.2 a la Pérdida de Datos en Campo:**
   - La clase `OfflineSyncQueue` está completamente desacoplada de los repositorios de producción (`SupabasePondsRepository`, `SupabaseWaterQualityRepository`, `SupabaseNutritionRepository`).
   - Cuando un operario en campo realiza un registro zootécnico (alimentación, muestreo biométrico, mortalidad o calidad de agua) sin señal celular, las peticiones HTTP/REST a Supabase fallan irremediablemente con `ClientException` o `SocketException`.
   - Dado que los repositorios capturan estas excepciones con `catch (_)`, guardan el registro únicamente en listas estáticas de memoria RAM (`_demoRecords`, `_demoMortalities`, etc.) y retornan el objeto exitosamente a la UI.
   - **Consecuencia Ineludible:** Si el operario cierra la app o el sistema operativo libera la aplicación en segundo plano por falta de memoria RAM, la totalidad de los datos zootécnicos ingresados en campo se destruyen sin posibilidad de recuperación.

2. **De la Observación 1.1 a la Vulnerabilidad de `flushQueue`:**
   - `flushQueue` utiliza `supabase.from(item.table).insert(item.payload)`.
   - Si la petición original llegó al servidor Supabase pero la respuesta HTTP se cortó por señal deficiente, el registro ya existe en PostgreSQL con su UUID.
   - Al reconectar y reintentar con `.insert()`, PostgreSQL arroja una violación de unicidad (`duplicate key value violates unique constraint`).
   - **Consecuencia Ineludible:** El elemento fallará en cada intento de vaciado hasta ser descartado tras 5 reintentos, perdiéndose el ack local. El uso de `.upsert(item.payload)` es técnicamente obligatorio para garantizar la idempotencia de la sincronización.

3. **De la Observación 1.3 a la Ilusión de Éxito en la UI:**
   - Debido a los bloques `catch (_)` que retornan objetos válidos o arrays vacíos, los notificadores Riverpod (`PondsNotifier`, `WaterQualityNotifier`, `NutritionNotifier`) nunca registran un estado de error en `errorMessage`.
   - Los modales de presentación asumen que toda operación completada sin excepción fue exitosa y presentan un SnackBar verde ("¡Medición registrada con éxito!").
   - **Consecuencia Ineludible:** Los usuarios de la app son engañados creyendo que sus transacciones están salvadas en la nube, cuando en realidad fallaron o solo existen en la memoria volátil del dispositivo.

4. **De la Observación 1.4 a la Estrategia de Entrega en Producción:**
   - El código pasa `flutter analyze --no-fatal-infos` con 0 errores y 0 advertencias, lo que demuestra estricta conformidad sintáctica y tipado de linter.
   - Sin embargo, `flutter test` arroja 5 fallos preexistentes (2 de UI en `bitacora_screen_test.dart` y 3 de modelo en `warehouse_inventory_test.dart`).
   - **Consecuencia Ineludible:** Para cumplir el criterio de aceptación del proyecto de pruebas al 100%, estas 5 desalineaciones deben ser resueltas de forma paralela a la implementación de R4.

---

## 3. Caveats (Límites, Suposiciones y Casos Borde)

1. **Sin dependencia `connectivity_plus` instalada:**
   - El proyecto no incluye actualmente `connectivity_plus` en `pubspec.yaml`.
   - *Alternativa no invasiva:* Para no requerir descargas de paquetes externos ni alterar `pubspec.yaml`, la reconexión y vaciado de cola (`flushQueue`) se puede articular mediante:
     - Detección de éxito en cualquier llamada de red subsecuente (trigger oportunista).
     - Un timer periódico ligero (e.g. cada 30 o 45 segundos mientras la app esté en primer plano).
     - Hook al reanudar la aplicación desde segundo plano (`AppLifecycleListener`).
     - Botón manual "Sincronizar ahora" expuesto en la interfaz cuando hay ítems pendientes.
2. **Tablas con lógica compuesta (Actualización de Lotes/Estanques):**
   - Al registrar mortalidad o biometría de forma offline, se encola la inserción en `'mortalidad'` o `'biometrias'`. Sin embargo, `registerMortality` y `registerBiometry` también actualizan campos derivados en `'lotes'` y `'estanques'` (`biomasa_actual_kg`, `cantidad_actual_peces`).
   - *Consideración:* Se debe asegurar que las migraciones de PostgreSQL (`supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql`) o triggers en la base de datos recalculen la biomasa automáticamente a partir del histórico de biometrías y mortalidades, o bien encolar también la actualización correspondiente del lote.
3. **Restricción de Solo Lectura durante esta Fase:**
   - Como agente de exploración, no se ha modificado ningún archivo fuente de `lib/` ni de `test/`. Todas las soluciones propuestas se entregan como especificaciones exactas para los agentes de implementación.

---

## 4. Conclusion (Estrategia de Implementación Recomendada)

Para satisfacer integralmente el requerimiento R4 (DATA-02, PERF-01) y asegurar el estándar de producción, se debe seguir la siguiente arquitectura de implementación:

### 4.1 Fortalecimiento de `OfflineSyncQueue` (`lib/core/storage/offline_sync_queue.dart`)
1. **Actualizar `flushQueue` para usar `.upsert()`:**
   Cambiar `await supabase.from(item.table).insert(item.payload);` por `await supabase.from(item.table).upsert(item.payload);` garantizando sincronización idempotente libre de colisiones por UUID repetido.
2. **Incorporar notificador reactivo o Stream de Pendientes:**
   Añadir un `ValueNotifier<int>` o `StreamController<int>` con `pendingCount` para que la UI pueda renderizar un indicador de conectividad y badge de registros pendientes.

### 4.2 Extensión de `AppFailure` (`lib/core/errors/app_failure.dart`)
1. Declarar `abstract class AppFailure implements Exception`.
2. Añadir:
   - `class NetworkFailure extends AppFailure { const NetworkFailure(super.message, [super.code]); }`
   - `class StorageFailure extends AppFailure { const StorageFailure(super.message, [super.code]); }`

### 4.3 Cableado de `OfflineSyncQueue` en los 3 Repositorios
1. **En `SupabaseNutritionRepository.recordFeeding`:**
   Al capturar una falla de red (`SocketException`, `ClientException`, `TimeoutException`, o error genérico no de validación):
   ```dart
   await OfflineSyncQueue.enqueue(
     type: OfflineActionType.feeding,
     table: 'alimentacion_diaria',
     payload: insertData,
   );
   _demoRecords.insert(0, record);
   _eventBus.fire(DailyFeedingRecordedEvent(...));
   return record; // O retornar con flag local / notificar al usuario
   ```
2. **En `SupabaseWaterQualityRepository.recordParameters`:**
   Al fallar la conexión:
   ```dart
   await OfflineSyncQueue.enqueue(
     type: OfflineActionType.waterQuality,
     table: 'parametros_calidad_agua',
     payload: insertData,
   );
   return parameter;
   ```
3. **En `SupabasePondsRepository.registerMortality` y `registerBiometry`:**
   Al fallar la conexión remota:
   - Encolar en `OfflineSyncQueue.enqueue(type: OfflineActionType.mortality, table: 'mortalidad', payload: insertData)` y `OfflineSyncQueue.enqueue(type: OfflineActionType.biometry, table: 'biometrias', payload: insertData)`.
   - Mantener el objeto en `_demoMortalities` / `_demoBiometries` para que el estado local de Riverpod lo muestre de inmediato sin perderlo.

### 4.4 Disparador Automático de Sincronización en Reanudación y Red
Implementar un `OfflineSyncService` o extender `OfflineSyncQueue` con un método estático `startAutoSync(SupabaseClient supabase)` que:
- Ejecute `flushQueue` en el arranque de la app (`main.dart`).
- Se ejecute tras cada mutación remota exitosa en cualquier repositorio.
- Programe una comprobación periódica (cada 30s) si hay elementos encolados.

### 4.5 Sustitución de `catch (_)` y Feedback al Usuario
- Reemplazar los `catch (_)` de fallas críticas de servidor o permisos por `catch (e) { throw ServerFailure(e.toString()); }`.
- En los notificadores (`PondsNotifier`, `WaterQualityNotifier`, `NutritionNotifier`), capturar `AppFailure`, asignar a `errorMessage` y permitir que los modales presenten mensajes descriptivos:
  - Fallo de Red Encolado: Banner informativo `"Sin conexión: Registro guardado en el dispositivo. Se sincronizará automáticamente."`
  - Fallo Fatal / Validación: Banner rojo de advertencia con el mensaje del `AppFailure`.

---

## 5. Verification Method (Método de Verificación Independiente)

Para que el equipo de implementación y QA valide de manera concluyente la resolución de R4 y la estabilidad del build:

### 5.1 Comandos de Terminal
1. **Linter y Análisis Estático:**
   ```powershell
   flutter analyze --no-fatal-infos
   ```
   *Criterio de Aprobación:* Retornar `No issues found!` con código de salida 0.
2. **Suite Completa de Pruebas:**
   ```powershell
   flutter test
   ```
   *Criterio de Aprobación:* 100% de las pruebas pasando (`0 failures`).
3. **Pruebas Específicas de Resiliencia y Dominio:**
   ```powershell
   flutter test test/modules/ponds_batches/ponds_notifier_test.dart
   flutter test test/modules/feeding_nutrition/feeding_record_test.dart
   flutter test test/modules/water_quality/water_parameter_test.dart
   ```

### 5.2 Verificación de Resiliencia Offline en Pruebas Unitarias
Crear un nuevo archivo de prueba `test/core/storage/offline_sync_queue_test.dart` que verifique:
- Encolamiento de un ítem con `OfflineSyncQueue.enqueue`.
- Persistencia y recuperación a través de `OfflineSyncQueue.getPendingItems()`.
- Sincronización e idempotencia de `OfflineSyncQueue.flushQueue` simulando desconexión inicial y reconexión con cliente mock.
- Comprobación de que tras un vaciado exitoso, la cola en `SharedPreferences` queda vacía.

### 5.3 Condiciones de Invalidación
El requerimiento se considerará inválido o incompleto si:
- Un fallo de red durante el registro de alimentación, biometría, mortalidad o calidad de agua no genera un ítem persistido en `SharedPreferences` bajo `'fishbit_offline_sync_queue_v1'`.
- La llamada a `flushQueue` continúa utilizando `.insert()` en lugar de `.upsert()`.
- Persisten bloques `catch (_) {}` vacíos que oculten errores fatales de autenticación o validación de tenant.
- La ejecución de `flutter analyze --no-fatal-infos` produce advertencias o errores.
