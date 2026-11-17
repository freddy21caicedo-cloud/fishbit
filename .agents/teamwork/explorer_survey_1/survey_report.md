# INFORME DE AUDITORÍA Y TRAZABILIDAD R1: CICLO DE VIDA BIOLÓGICO-ECONÓMICO, INTEGRIDAD REGULATORIA (ICA/AUNAP) Y ARQUITECTURA SUPABASE POSTGRESQL

**Fecha:** 2026-10-27  
**Rol:** Explorer Subagent 1 (Especialista en Trazabilidad de Datos, Modelado Biológico/Económico y Base de Datos)  
**Proyecto:** FishBit Finance 2.0 (Flutter Web/Mobile + Supabase PostgreSQL Multi-Tenant)  
**Alcance de Investigación:** R1 — Trazabilidad de Datos Acuícolas Punta a Punta, Fórmulas Biológicas/Económicas, Diálogos de Laboratorio/Campo y Esquemas Supabase/RLS.  
**Estado:** Inspección de solo lectura completada al 100%.

---

## RESUMEN EJECUTIVO

Se ha conducido una auditoría exhaustiva, a nivel de código fuente y DDL de base de datos, sobre los módulos de siembra, alimentación, calidad de agua, mortalidad, biometrías, traslados/desdobles, cosechas y generación de libros oficiales para el ICA y AUNAP. Asimismo, se inspeccionaron los cálculos de FCR (Factor de Conversión Alimenticia), biomasa, deducción de inventario, acumulación de costos por lote (CPK/COGS), las políticas RLS y los índices compuestos en PostgreSQL.

### Principales Hallazgos Críticos:
1. **Falta de Atomicidad Transaccional en Campo (Client-Side Multi-Hop Mutations):** Operaciones críticas como traslados/desdobles (`SupabasePondsRepository.transferOrSplitBatch`), siembra y alimentación ejecutan de 2 a 5 mutaciones HTTP REST secuenciales desacopladas desde el cliente Flutter sin envoltura transaccional (`BEGIN...COMMIT`) ni funciones RPC en Supabase. Si la red oscila en campo, los datos quedan huérfanos o con saldo de inventario inconsistente.
2. **Corrupción de Biomasa en Estanques con Policultivo:** Al registrar biometría o mortalidad en un lote individual, `SupabasePondsRepository` sobreescribe directamente `estanques.biomasa_kg = newBiomass` (la biomasa de ese único lote), destruyendo la biomasa de otros lotes activos coexistentes en el mismo estanque.
3. **Distorsión Matemática del FCR tras Desdobles (Splits):** Al realizar un desdoble parcial de lote, los costos se dividen proporcionalmente, pero el historial de alimentación acumulada permanece 100% asignado al lote padre. Esto provoca que el FCR calculado del lote padre se duplique artificialmente (ej. de 1.35 a 2.70+) al conservar el alimento total con solo la mitad de la biomasa, mientras el lote hijo queda con FCR nulo.
4. **Vulnerabilidades de Fuga Multi-Tenant en Políticas RLS (`20260831_database_performance_and_rls_optimization.sql`):** Múltiples tablas (`compras_mat_biologico`, `equipos`, `mantenimientos`, `facturas`, `inventario_insumos`) aplican RLS basándose en subconsultas de coincidencia de texto sobre `unidad_acuicola_sigla` o columnas obsoletas como `cliente_id`, omitiendo `empresa_id = public.get_auth_empresa_id()`. Dado que la sigla solo es única a nivel de empresa (`UNIQUE (empresa_id, sigla)`), dos empresas distintas que compartan la misma sigla (ej. `'SEDE1'` o `'PISC'`) pueden leer registros entre inquilinos.
5. **Generación de Libros ICA con Datos Simulados y Falla Silenciosa en Móvil:** El motor de reportes Excel (`IcaOfficialReportsEngine`):
   - Exporta registros de muestra hardcodeados (falsificados) en los formatos oficiales F-06 (Limpieza) y F-12 (Monitoreo de Patógenos TiLV/IPN), así como un proveedor y registro ICA quemado en F-11.
   - En plataformas móviles (Android / iOS) y escritorio Windows, el método de descarga `_downloadExcel` valida estrictamente `kIsWeb`, ejecutando un stub vacío que desecha los bytes generados sin guardar ni compartir el archivo.
6. **Controles de Entrada con Valores Pre-cargados Mock:** Si bien `parametro_modal.dart` ya fue saneado (inicia vacío), otros diálogos críticos (`siembra_modal.dart`, `biometria_modal.dart`, `mortalidad_modal.dart`, `venta_rapida_modal.dart` y los modales de necropsias ICA) continúan inicializando controladores con valores simulados quemados (ej. 5.000 peces, 35 peces muestreados, 5 muertos, $9.500 COP, y descripciones completas de necropsias "normales").
7. **Cola Offline Dormida (`OfflineSyncQueue`):** La cola local en SQLite/SharedPreferences implementada para contingencias de red solo está conectada en `SupabaseWaterQualityRepository`. Además, el método `flushQueue` no es invocado en ningún punto del ciclo de vida de la aplicación, dejando los registros encolados sin sincronizar jamás.
8. **Credenciales Hardcodeadas en `lib/main.dart`:** La URL canónica de Supabase y la `anonKey` (JWT) continúan presentes como valores literales por defecto en `lib/main.dart:33-41`.

---

## 1. AUDITORÍA DE LA CADENA BIOLÓGICA PUNTA A PUNTA

```
[Proveedor Alevinos / Compra F-11] 
       │
       ▼
 [Almacén / Bodega Alevinos] 
       │
       ▼
 [Siembra Lote] ──► [Alimentación Diaria F-05] ──► [Calidad de Agua F-09]
       │                        │
       ▼                        ▼
 [Biometría / Muestreo]    [Deducción Bodega Pienso]
       │
       ▼
 [Mortalidad F-04] 
       │
       ▼
 [Traslado / Desdoble] ──► [Cosecha / Ventas F-10] ──► [Libro Maestro ICA/AUNAP]
```

### 1.1 Siembra / Sowing
- **Archivos analizados:**
  - `lib/modules/ponds_batches/presentation/dialogs/siembra_modal.dart:40-44, 202-205, 248-268`
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:380-430`
  - `lib/modules/ponds_batches/domain/models/fish_batch.dart:30-55`
- **Observaciones:**
  - En `siembra_modal.dart:40-43`, los controladores numéricos inicializan con datos mock precargados:
    ```dart
    final _pecesCtrl = TextEditingController(text: CurrencyFormatters.formatInt(5000));
    final _pesoCtrl = TextEditingController(text: '1.5');
    final _metaCosechaCtrl = TextEditingController(text: '650');
    ```
  - En `siembra_modal.dart:203-204`, existe un fallback quemado a IDs demo:
    ```dart
    final empresaId = authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
    final unidadId = authState.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';
    ```
    Si el estado de autenticación se desincroniza, el lote se asigna silenciosamente a la empresa demo de testing.
  - En `siembra_modal.dart:249-256`, la siembra se procesa en dos pasos desarticulados:
    1. `ref.read(pondsProvider.notifier).plantBatch(batch)`
    2. `ref.read(warehouseProvider.notifier).discountAlevinosSiembra(...)`
    Si el primer llamado tiene éxito en Supabase y la conexión falla antes del segundo, se crea el lote en el estanque pero el inventario de alevinos en almacén no se descuenta, duplicando el inventario disponible.
  - En `supabase_ponds_repository.dart:381-393`, cualquier empresa con prefijo `c1000000-` intercepta la llamada y escribe en memoria estática `_demoBatches`, sin validar contra PostgreSQL.

### 1.2 Alimentación / Feeding
- **Archivos analizados:**
  - `lib/modules/ponds_batches/presentation/dialogs/alimentar_modal.dart:37-39, 447-465`
  - `lib/modules/feeding_nutrition/infrastructure/repositories/supabase_nutrition_repository.dart:51-140`
  - `lib/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart:423-444`
  - `lib/modules/warehouse_inventory/infrastructure/repositories/supabase_warehouse_repository.dart:107-123`
- **Observaciones:**
  - En `alimentar_modal.dart:447-464`, el registro de alimentación descuenta primero el inventario en almacén y luego registra el consumo:
    ```dart
    // 1. Descontar inventario en Bodega
    await ref.read(warehouseProvider.notifier).discountStock(...);
    // 2. Registrar en módulo de nutrición
    await ref.read(nutritionProvider.notifier).recordDailyFeeding(...);
    // 3. Recargar estanques para actualizar FCR y costo
    await ref.read(pondsProvider.notifier).loadPondsAndBatches();
    ```
    No existe una transacción atómica que agrupe ambas tablas.
  - **Falla Crítica de Supresión de Excepciones:** En `supabase_nutrition_repository.dart:130-139`:
    ```dart
    } catch (_) {
      _demoRecords.insert(0, record);
      _eventBus.fire(DailyFeedingRecordedEvent(...));
      return record;
    }
    ```
    Si Supabase rechaza la inserción en `alimentacion_diaria` (por error de red, violación de foreign key o RLS), el bloque `catch (_)` captura silenciosamente el fallo, inserta el registro en la lista local temporal `_demoRecords`, dispara el evento en el bus y retorna éxito a la UI. Al recargar la app, ese registro desaparece sin dejar rastro en auditoría contable ni en base de datos.
  - **Doble Esquema de Inventario (Desincronización de Tablas):**
    En `supabase_schema_canonical_v10.sql:158-169`, la tabla canónica `alimentacion_diaria` tiene:
    `insumo_id UUID REFERENCES public.inventario_insumos(id) ON DELETE SET NULL`.
    Sin embargo, `supabase_warehouse_repository.dart:114` actualiza la tabla `inventory` (en inglés):
    `await _supabase.from('inventory').update(...).eq('id', item.id)`.
    Esto genera una bifurcación donde el frontend actualiza `inventory`, pero las relaciones foráneas de alimentación apuntan a `inventario_insumos`.

### 1.3 Calidad de Agua / Water Quality
- **Archivos analizados:**
  - `lib/modules/water_quality/presentation/dialogs/parametro_modal.dart:35-48, 550-599`
  - `lib/modules/water_quality/infrastructure/repositories/supabase_water_quality_repository.dart:70-160`
  - `supabase/migrations/20260829_milestone1_bitacora_schema_alignment.sql:15-70`
- **Observaciones:**
  - En `parametro_modal.dart:35-48`, los controladores numéricos inician vacíos y se implementó validación obligatoria para Oxígeno, Temperatura y pH, en cumplimiento del requerimiento DATA-01.
  - En `supabase_water_quality_repository.dart:127-158`, ante una caída de red se invoca `OfflineSyncQueue.enqueue(...)`. Sin embargo, los demás repositorios del sistema no tienen esta protección.
  - La tabla `parametros_calidad_agua` cuenta con índices compuestos correctos en `(empresa_id, fecha DESC)` y `(empresa_id, estanque_id, fecha DESC)` implementados en `20260831_database_performance_and_rls_optimization.sql:63-69`.

### 1.4 Mortalidad / Mortality
- **Archivos analizados:**
  - `lib/modules/ponds_batches/presentation/dialogs/mortalidad_modal.dart:34, 58-60, 410-440`
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:799-944`
  - `lib/modules/ponds_batches/domain/models/mortality_record.dart`
- **Observaciones:**
  - En `mortalidad_modal.dart:34, 59`, los campos inicializan con datos ficticios:
    ```dart
    final _muertosCtrl = TextEditingController(text: '5');
    _pesoCtrl = TextEditingController(text: (widget.batch?.pesoActualGramos ?? 250.0).toStringAsFixed(1));
    ```
  - **Falla Crítica de Sobreescritura de Biomasa en Estanques:**
    En `supabase_ponds_repository.dart:927-937`:
    ```dart
    // Actualizar conteo y biomasa en lotes y estanques
    if (newCount >= 0) {
      await _supabase.from('lotes').update({
        'cantidad_actual_peces': newCount,
        'biomasa_actual_kg': newBiomass,
      }).eq('id', loteId);

      await _supabase.from('estanques').update({
        'biomasa_kg': newBiomass,
      }).eq('id', estanqueId);
    }
    ```
    `newBiomass` corresponde únicamente a la biomasa remanente del lote específico sobre el que se reportó la mortalidad. En estanques con policultivo (ej. Tilapia + Cachama) o múltiples etapas, asignar `estanques.biomasa_kg = newBiomass` elimina de golpe la biomasa de los otros lotes activos del estanque.
  - En PostgreSQL no existe trigger que mantenga sincronizado `lotes.cantidad_actual_peces` cuando se inserta un registro en `mortalidad`. Todo depende de llamadas REST subsecuentes del cliente móvil.

### 1.5 Biometría / Biometry
- **Archivos analizados:**
  - `lib/modules/ponds_batches/presentation/dialogs/biometria_modal.dart:33-35, 48-54`
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:947-1107`
  - `lib/modules/ponds_batches/domain/models/biometria_record.dart`
- **Observaciones:**
  - En `biometria_modal.dart:33, 51-53`, el modal precarga 35 ejemplares y un peso de captura estimado:
    ```dart
    final _pecesCapturadosCtrl = TextEditingController(text: '35');
    final defaultCapturaKg = (defaultPeces * defaultPesoG) / 1000.0;
    _pesoTotalCapturaKgCtrl = TextEditingController(text: defaultCapturaKg.toStringAsFixed(2));
    ```
    Si el técnico abre el modal y presiona guardar sin modificar, se genera un muestreo biométrico falso con peso idéntico al anterior.
  - Al igual que en mortalidad, en `supabase_ponds_repository.dart:1096-1100`:
    ```dart
    if (newBiomass > 0.0) {
      await _supabase.from('estanques').update({
        'biomasa_kg': newBiomass,
      }).eq('id', estanqueId);
    }
    ```
    Se sobreescribe la biomasa del estanque con la de un solo lote, corrompiendo la suma de policultivos.

### 1.6 Traslados y Desdobles / Transfer & Split
- **Archivos analizados:**
  - `lib/modules/ponds_batches/presentation/dialogs/traslado_modal.dart:38-53, 580-645`
  - `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart:448-687`
  - `lib/modules/ponds_batches/domain/models/transfer_record.dart:1-120`
  - `supabase/migrations/20260831_database_performance_and_rls_optimization.sql:117-129, 383-417`
- **Observaciones:**
  - **DDL Inexistente de `traslados_lotes`:** La tabla `public.traslados_lotes` es indexada y asegurada con RLS en `20260831_database_performance_and_rls_optimization.sql`, y el repositorio ejecuta inserciones en ella (`_supabase.from('traslados_lotes').insert(...)`). Sin embargo, **ningún archivo de migración ni `supabase_schema_canonical_v10.sql` contiene la sentencia `CREATE TABLE public.traslados_lotes`**. Si la base de datos se recrea desde los esquemas versionados, cualquier traslado fallará con código PostgreSQL `42P01 (undefined_table)`.
  - **Falta de Atomicidad (5 mutaciones en cadena):**
    En `supabase_ponds_repository.dart:577-683`, un desdoble parcial ejecuta:
    1. `_supabase.from('lotes').update(...)` sobre lote origen.
    2. `_supabase.from('estanques').update(...)` sobre estanque origen.
    3. `_supabase.from('lotes').insert(...)` creando lote destino.
    4. `_supabase.from('estanques').update(...)` sobre estanque destino.
    5. `_supabase.from('traslados_lotes').insert(...)` para auditoría.
    Si se interrumpe la red en el paso 3 o 4, los peces se descontaron del origen pero no existen en el destino, causando pérdida de datos biológicos irrecuperable.

### 1.7 Cosecha y Ventas / Harvest & Sales
- **Archivos analizados:**
  - `lib/modules/sales_harvest/presentation/dialogs/venta_rapida_modal.dart:55-63, 178-198, 800-845`
  - `lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart:89-136`
  - `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:189-225`
- **Observaciones:**
  - En `venta_rapida_modal.dart:59`, el precio de venta inicializa en `TextEditingController(text: '\$ 9.500')`.
  - En `venta_rapida_modal.dart:192`:
    `final cpk = selectedBatch?.cpk ?? 4500.0;`
    Si `selectedBatch.cpk` es `0.0` (porque el lote no tiene costos registrados aún), la expresión no aplica el fallback (0.0 no es null), resultando en `cogs = 0.0` y utilidad neta igual al 100% del ingreso bruto.
  - **Peces Huérfanos tras Cosecha:** En `ponds_provider.dart:189-203`:
    ```dart
    final remanenteBiomasa = (oldBatch.biomasaActualKg - event.biomasaVendidaKg).clamp(0.0, double.infinity);
    final isTotalHarvest = remanenteBiomasa <= 5.0;
    final updatedBatch = oldBatch.copyWith(
      biomasaActualKg: remanenteBiomasa,
      estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
    );
    ```
    **`cantidadActualPeces` nunca se descuenta al vender.** Si se realiza una cosecha parcial de 2.000 peces (1.000 kg), la biomasa baja pero el contador de peces permanece idéntico. En la siguiente consulta, el peso promedio recalculado (`biomasaActualKg * 1000 / cantidadActualPeces`) cae abruptamente a valores biológicamente imposibles.
  - En `ponds_provider.dart:220-222`, las llamadas `_repository.updateBatch` y `_repository.updatePond` dentro de `_handleHarvestSaleRecorded` **no son esperadas con `await`**, exponiendo la mutación a cancelaciones por garbage collection si el provider se desmonta.

### 1.8 Generación de Libros Oficiales ICA / AUNAP
- **Archivos analizados:**
  - `lib/core/reports/ica_official_reports_engine.dart:53-58, 63-159, 746-751, 881-883, 928-932`
  - `lib/core/reports/web_download_helper.dart`
  - `lib/core/reports/web_download_helper_stub.dart:1-5`
- **Observaciones:**
  - **Falla de Descarga en Móvil y Escritorio (Plataforma Ciega):**
    En `ica_official_reports_engine.dart:53-58`:
    ```dart
    void _downloadExcel(Excel excel, String filename) {
      final bytes = excel.save();
      if (bytes != null && kIsWeb) {
        downloadFileWeb(bytes, filename);
      }
    }
    ```
    Y en `web_download_helper_stub.dart:2-4`:
    ```dart
    void downloadFileWeb(List<int> bytes, String fileName) {
      // En plataformas móviles/escritorio se maneja a través de file_picker o share_plus
    }
    ```
    El método solo opera si `kIsWeb == true`. En Android, iOS o Windows desktop, al pulsar el botón de exportación de cualquier libro oficial ICA o del Cuaderno de Campo Maestro, el código no realiza ninguna acción (el stub está completamente vacío).
  - **Exportación de Datos Médicos / Biológicos Falsificados:**
    - En el reporte **F-06 (Limpieza y Desinfección)** (`ica_official_reports_engine.dart:746-751`), se exportan 4 filas quemadas en el código (`sampleRows` con fechas de hoy, pediluvios con Amonio 400 ppm, etc.) en lugar de consultar la tabla `public.bioseguridad_limpieza`.
    - En el reporte **F-11 (Material Genético)** (`ica_official_reports_engine.dart:881-882`), se inyecta para todos los lotes el texto quemado `'Alevinera Certificada del Huila'` y resolución `'REG-ICA-ALV-9941'`.
    - En el reporte **F-12 (Monitoreo de Patógenos TiLV/IPN)** (`ica_official_reports_engine.dart:928-932`), se exportan resultados hardcodeados de `'NEGATIVO'` para virus del lago de la tilapia y necrosis pancreática en lugar de consultar la tabla `public.sanidad_monitoreo_patogenos`. Presentar este archivo ante una auditoría del ICA constituye una falsedad en documento público técnico.

---

## 2. FÓRMULAS ECONÓMICAS Y BIOLÓGICAS (FCR, BIOMASA, INVENTARIO Y COSTOS)

### 2.1 Factor de Conversión Alimenticia (FCR / FCA)
- **Ubicación:** `lib/modules/ponds_batches/domain/models/fish_batch.dart:62-75`
- **Código actual:**
  ```dart
  double? get fcrOrNull {
    final gananciaBiomasa = biomasaActualKg - biomasaInicialKg;
    if (alimentoAcumuladoKg > 0 && gananciaBiomasa > 0) {
      return alimentoAcumuladoKg / gananciaBiomasa;
    }
    return null;
  }
  ```
- **Deficiencias encontradas:**
  1. **Confusión entre FCR Económico (eFCR) y FCR Biológico (bFCR):** La fórmula actual calcula un FCR económico aparente sin considerar la biomasa de peces extraídos por cosecha parcial ni la biomasa perdida por mortalidad.
     - *FCR Económico Real:* $\text{eFCR} = \frac{\text{Kg Alimento Consumido}}{\text{Biomasa Actual} + \text{Biomasa Cosechada} - \text{Biomasa Inicial}}$
     - *FCR Biológico Real:* $\text{bFCR} = \frac{\text{Kg Alimento Consumido}}{\text{Biomasa Actual} + \text{Biomasa Cosechada} + \text{Biomasa Mortalidad} - \text{Biomasa Inicial}}$
  2. **Ruptura de FCR en Desdobles:** Cuando un lote se divide en dos estanques, el lote hijo inicia con `alimentoAcumuladoKg = 0.0` (FCR nulo), y el lote padre mantiene el 100% del alimento consumido con solo el 50% de la biomasa. El FCR del lote padre pasa instantáneamente de 1.35 a más de 2.70, distorsionando los reportes técnicos.

### 2.2 Deducción de Inventario y Valuación FIFO / Costo Promedio Ponderado (CPP)
- **Ubicación:** `lib/modules/warehouse_inventory/presentation/providers/warehouse_provider.dart:423-444, 463-470`
- **Código actual:**
  ```dart
  final remanente = (item.cantidadActualKg - cantidadKg).clamp(0.0, 999999.0);
  final updated = item.copyWith(
    cantidadActualKg: remanente,
    costoTotal: remanente * item.costoUnitarioHistorico,
  );
  ```
- **Deficiencias:**
  - El costo unitario utilizado es un promedio histórico general que no discrimina por número de lote de fabricante o factura específica de concentrado.
  - No existe bloqueo en base de datos si el stock cae por debajo de cero (`CHECK (cantidad_actual_kg >= 0)` sí está en la tabla, pero la UI captura el error y lo suprime con `catch (_)`, dejando la memoria local con saldo negativo mientras la BD rechaza la transacción).

### 2.3 Acumulación de Costos por Lote (ProductionCostEngine)
- **Ubicación:** `lib/modules/finance_payroll/domain/services/production_cost_engine.dart:38-42, 89-105`
- **Código actual:**
  ```dart
  // 3. Costo Directo de Alimento (si no hay facturas registradas aún, estimar basado en biomasa y FCR típico 1.35)
  final alimentoReal = totalAlimentoInsumos > 0
      ? totalAlimentoInsumos
      : (totalBiomasaKg * 1.35 * 4500.0);
  ...
  // Asignar alimento proporcionalmente a la biomasa
  final alimentoEstanque = alimentoReal * pesoPonderadoBiomasa;
  ```
- **Deficiencias:**
  - Si no existen facturas de alimento ingresadas en el mes, el motor inventa un costo multiplicando biomasa por 1.35 y $4.500 COP/kg.
  - El costo de alimento se distribuye entre los estanques según su biomasa actual ponderada (`pesoPonderadoBiomasa`), en lugar de sumar el consumo real registrado en `alimentacion_diaria` para cada lote/estanque. Si un estanque de pre-cría consumió alimento de alto costo (45% PB a $7.000/kg) y un estanque de engorde consumió alimento económico (28% PB a $4.200/kg), el sistema promedia y deforma el CPK de ambos.

---

## 3. INVENTARIO EXHAUSTIVO DE VALORES POR DEFECTO MOCK EN DIÁLOGOS DE ENTRADA

A continuación se detalla cada diálogo y pantalla donde se identificaron valores iniciales fijos quemados:

| Archivo | Línea | Campo / Variable | Valor Hardcodeado | Riesgo / Impacto |
|---|---|---|---|---|
| `siembra_modal.dart` | 40 | `_pecesCtrl` | `5000` | Siembra inadvertida de 5.000 alevinos al presionar guardar. |
| `siembra_modal.dart` | 41 | `_pesoCtrl` | `1.5` | Peso inicial ficticio de 1.5 gramos. |
| `siembra_modal.dart` | 42 | `_metaCosechaCtrl` | `650` | Meta de cosecha fija de 650 gramos. |
| `siembra_modal.dart` | 203 | `empresaId` fallback | `'c1000000-0000-0000-0000-000000000001'` | Asignación silenciosa de datos productivos a tenant demo. |
| `mortalidad_modal.dart` | 34 | `_muertosCtrl` | `'5'` | Registro automático de 5 peces muertos sin confirmación. |
| `mortalidad_modal.dart` | 59 | `_pesoCtrl` fallback | `250.0` | Peso promedio predefinido en 250 g. |
| `biometria_modal.dart` | 33 | `_pecesCapturadosCtrl` | `'35'` | Muestreo fijo de 35 peces. |
| `biometria_modal.dart` | 51-53 | `_pesoTotalCapturaKgCtrl` | `(35 * pesoActual) / 1000` | Peso de muestra pre-calculado que simula pesaje real. |
| `traslado_modal.dart` | 50-51 | `_pesoCtrl` / `_pecesCtrl` | `100.0` g / `1000` peces | Valores por defecto si el batch es nulo. |
| `venta_rapida_modal.dart` | 59 | `_precioKgCtrl` | `'\$ 9.500'` | Precio comercial de venta quemado. |
| `venta_rapida_modal.dart` | 192 | `cpk` fallback | `4500.0` | Costo por kilo estimado artificial de $4.500 COP. |
| `crear_colaborador_modal.dart`| 57 | `_salarioCtrl` | `'2000000'` | Salario base fijado en $2.000.000 COP. |
| `crear_colaborador_modal.dart`| 59 | `_passCtrl` | `'FishBit.2026'` | Contraseña provisional en texto claro insegura. |
| `registro_jornal_modal.dart` | 44 | `_cantidadCtrl` | `'3'` | 3 jornales pre-cargados por defecto. |
| `nuevo_item_modal.dart` | 56 | `_pesoPromedioCtrl` | `'1.5'` | Peso alevino en bodega por defecto 1.5 g. |
| `app_config_modal.dart` | 30 | `_fcrCtrl` | `'1.25'` | FCR objetivo quemado en 1.25. |
| `ica_biosecurity_modals.dart` | 42-43 | `_horaIngresoCtrl` / `Salida`| `'08:00'` / `'17:00'` | Horas de ingreso de personal pre-llenadas. |
| `ica_biosecurity_modals.dart` | 424-425| `_desinfectanteCtrl` | `'Amonio Cuaternario...'` / `'200 ppm'` | Registro de rodiluvios de vehículos pre-llenado. |
| `ica_biosecurity_modals.dart` | 765-777| Necropsia Órganos Clínicos | Textos descriptivos completos pre-cargados (ojos claros, branquias rojo cereza, etc.) | Generación de necropsias veterinarias ficticias sin examen patológico real. |

---

## 4. AUDITORÍA DE ESQUEMAS SUPABASE POSTGRESQL, ÍNDICES Y POLÍTICAS RLS

### 4.1 Brechas de Aislamiento Multi-Tenant en RLS (`20260831_database_performance_and_rls_optimization.sql`)

En la migración `20260831_database_performance_and_rls_optimization.sql`, se optimizaron las funciones helper utilizando subconsultas escalares `(SELECT public.get_auth_empresa_id())` para habilitar el caché `InitPlan` de PostgreSQL. Sin embargo, se identificaron vulnerabilidades severas en los predicados de aislamiento:

#### Vulnerabilidad 1: Aislamiento por `unidad_acuicola_sigla` en lugar de `empresa_id`
- **Líneas afectadas:** 519, 607, 881-884, 999
- **Código observado en `compras_mat_biologico` (Línea 519):**
  ```sql
  CREATE POLICY compras_mat_biologico_tenant_select ON public.compras_mat_biologico
    FOR SELECT TO authenticated
    USING (
      unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
      OR (SELECT public.is_superadmin())
    );
  ```
- **Falla de Seguridad:**
  En la tabla `public.unidades_acuicolas`, la restricción de unicidad es:
  `CONSTRAINT uq_empresa_sigla UNIQUE (empresa_id, sigla);`
  Esto significa que **la sigla no es única globalmente**. Dos empresas piscícolas independientes pueden tener una sede con la sigla `'SEDE1'` o `'PRIN'`. Si la Empresa A consulta `compras_mat_biologico`, el predicado `unidad_acuicola_sigla IN ('PRIN')` retornará las compras de alevinos de la Empresa A **y también las compras de la Empresa B**. La tabla posee la columna `empresa_id`, por lo que la comprobación debe ser estrictamente `empresa_id = (SELECT public.get_auth_empresa_id())`.

#### Vulnerabilidad 2: Comprobación de Columna Obsoleta `cliente_id` en `inventario_insumos` y `equipos`
- **Líneas afectadas:** 563, 998
- **Código observado en `inventario_insumos` (Línea 998):**
  ```sql
  CREATE POLICY inventario_insumos_tenant_select ON public.inventario_insumos
    FOR SELECT TO authenticated
    USING (
      cliente_id = (SELECT public.get_auth_empresa_id()) 
      OR unidad_acuicola_sigla IN (SELECT u.sigla FROM public.units u WHERE u.empresa_id = (SELECT public.get_auth_empresa_id())) 
      OR (SELECT public.is_superadmin())
    );
  ```
- **Falla de Seguridad:**
  La tabla `inventario_insumos` en el esquema canónico v10 define `empresa_id UUID NOT NULL REFERENCES public.empresas(id)`. La columna `cliente_id` es un remanente legacy. La política omite totalmente `empresa_id = (SELECT public.get_auth_empresa_id())`. Si `cliente_id` es NULL, la política depende exclusivamente de `unidad_acuicola_sigla`, reproduciendo la fuga de datos cross-tenant de la Vulnerabilidad 1.

### 4.2 Desalineación entre Esquema Canónico (`supabase_schema_canonical_v10.sql`) y Migraciones
1. **Omisión de `traslados_lotes`:** La tabla no existe en `supabase_schema_canonical_v10.sql` ni en ninguna migración previa.
2. **Omisión de `biometrias` y `mortalidad`:** En `supabase_schema_canonical_v10.sql`, estas tablas no figuran (fueron omitidas en favor de un genérico `registro_actividades`). Sin embargo, los repositorios de Flutter y la migración `20260829_milestone1_bitacora_schema_alignment.sql` las utilizan como tablas canónicas de primer orden.
3. **Duplicidad de Tablas de Inventario:** Existen simultáneamente `public.inventory` y `public.inventario_insumos`. Los módulos de Flutter escriben en `inventory` mientras las claves foráneas de SQL apuntan a `inventario_insumos`.

### 4.3 Auditoría de Índices Compuestos para Series Temporales

| Tabla | Índice Existente | Columnas | Estado / Evaluación |
|---|---|---|---|
| `parametros_calidad_agua` | `idx_calidad_agua_empresa_estanque_fecha` | `(empresa_id, estanque_id, fecha DESC)` | ✅ Óptimo para filtros de estanque y orden cronológico. |
| `parametros_calidad_agua` | `idx_calidad_agua_empresa_fecha` | `(empresa_id, fecha DESC)` | ✅ Óptimo para series temporales generales. |
| `alimentacion_diaria` | `idx_alimentacion_empresa_lote_fecha` | `(empresa_id, lote_id, fecha DESC)` | ✅ Óptimo para consumo por lote. |
| `alimentacion_diaria` | `idx_alimentacion_empresa_estanque_fecha` | `(empresa_id, estanque_id, fecha DESC)` | ✅ Óptimo para bitácora por estanque. |
| `biometrias` | `idx_biometrias_empresa_lote_date` | `(empresa_id, lote_id, date DESC)` | ✅ Óptimo para curvas de crecimiento. |
| `mortalidad` | `idx_mortalidad_empresa_lote_date` | `(empresa_id, lote_id, date DESC)` | ✅ Óptimo para cálculo de bajas por lote. |
| `traslados_lotes` | `idx_traslados_empresa_lote_origen` | `(empresa_id, lote_origen_id, fecha_operacion DESC)` | ⚠️ Parcial. Cubre lote, pero la UI consulta por estanque con `.or('estanque_origen_id.eq.$id,estanque_destino_id.eq.$id')`. |
| `traslados_lotes` | **FALTANTE** | `(empresa_id, estanque_origen_id, fecha_operacion DESC)` | ❌ Requiere creación para evitar scans secuenciales en Bitácora. |
| `traslados_lotes` | **FALTANTE** | `(empresa_id, estanque_destino_id, fecha_operacion DESC)` | ❌ Requiere creación para evitar scans secuenciales en Bitácora. |

---

## 5. PLAN DE ACCIÓN Y ESPECIFICACIÓN DE CORRECCIONES PROPUESTAS

### Propuesta 1: DDL Canónico de `traslados_lotes` e Índices Faltantes
```sql
-- Crear tabla de traslados y desdobles si no existe
CREATE TABLE IF NOT EXISTS public.traslados_lotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    unidad_acuicola_id UUID REFERENCES public.unidades_acuicolas(id) ON DELETE SET NULL,
    lote_origen_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
    lote_destino_id UUID REFERENCES public.lotes(id) ON DELETE SET NULL,
    estanque_origen_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE RESTRICT,
    estanque_destino_id UUID NOT NULL REFERENCES public.estanques(id) ON DELETE RESTRICT,
    tipo_operacion TEXT NOT NULL CHECK (tipo_operacion IN ('TRASLADO_TOTAL', 'DESDOBLE_PARCIAL')),
    peces_trasladados INTEGER NOT NULL CHECK (peces_trasladados > 0),
    peso_promedio_gramos NUMERIC NOT NULL CHECK (peso_promedio_gramos > 0),
    biomasa_trasladada_kg NUMERIC NOT NULL CHECK (biomasa_trasladada_kg > 0),
    proporcion_costos NUMERIC NOT NULL DEFAULT 0.0,
    costo_alevinos_transferido NUMERIC NOT NULL DEFAULT 0.0,
    costo_insumos_transferido NUMERIC NOT NULL DEFAULT 0.0,
    costo_fijo_transferido NUMERIC NOT NULL DEFAULT 0.0,
    costo_total_transferido NUMERIC NOT NULL DEFAULT 0.0,
    nuevo_codigo_lote TEXT,
    registrado_por TEXT,
    fecha_operacion TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Índices compuestos para traslados por estanque
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_estanque_origen 
  ON public.traslados_lotes (empresa_id, estanque_origen_id, fecha_operacion DESC);
CREATE INDEX IF NOT EXISTS idx_traslados_empresa_estanque_destino 
  ON public.traslados_lotes (empresa_id, estanque_destino_id, fecha_operacion DESC);
```

### Propuesta 2: Corrección Estricta de Políticas RLS Multi-Tenant
Reemplazar las condiciones vulnerables basadas en `unidad_acuicola_sigla` y `cliente_id` por la validación directa del tenant:
```sql
-- 1. compras_mat_biologico
DROP POLICY IF EXISTS compras_mat_biologico_tenant_select ON public.compras_mat_biologico;
CREATE POLICY compras_mat_biologico_tenant_select ON public.compras_mat_biologico
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

-- 2. inventario_insumos
DROP POLICY IF EXISTS inventario_insumos_tenant_select ON public.inventario_insumos;
CREATE POLICY inventario_insumos_tenant_select ON public.inventario_insumos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

-- 3. equipos
DROP POLICY IF EXISTS equipos_tenant_select ON public.equipos;
CREATE POLICY equipos_tenant_select ON public.equipos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

-- 4. mantenimientos
DROP POLICY IF EXISTS mantenimientos_tenant_select ON public.mantenimientos;
CREATE POLICY mantenimientos_tenant_select ON public.mantenimientos
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));

-- 5. facturas
DROP POLICY IF EXISTS facturas_tenant_select ON public.facturas;
CREATE POLICY facturas_tenant_select ON public.facturas
  FOR SELECT TO authenticated
  USING (empresa_id = (SELECT public.get_auth_empresa_id()) OR (SELECT public.is_superadmin()));
```

### Propuesta 3: Función Transaccional RPC para Desdoble Atómico (`execute_transfer_split`)
Para resolver la falta de atomicidad en los traslados y proteger la integridad del FCR y biomasa:
```sql
CREATE OR REPLACE FUNCTION public.execute_transfer_split(
    p_empresa_id UUID,
    p_unidad_id UUID,
    p_lote_origen_id UUID,
    p_estanque_origen_id UUID,
    p_estanque_destino_id UUID,
    p_peces_trasladados INT,
    p_biomasa_trasladada_kg NUMERIC,
    p_es_desdoble BOOLEAN,
    p_nuevo_codigo_lote TEXT,
    p_registrado_por TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_origen public.lotes%ROWTYPE;
    v_proporcion NUMERIC;
    v_nuevo_lote_id UUID;
    v_costo_alevinos NUMERIC;
    v_costo_insumos NUMERIC;
    v_costo_fijo NUMERIC;
    v_alimento_proporcional NUMERIC;
    v_tot_bio_origen NUMERIC;
    v_tot_bio_destino NUMERIC;
BEGIN
    SELECT * INTO v_origen FROM public.lotes WHERE id = p_lote_origen_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lote origen no encontrado';
    END IF;

    IF p_peces_trasladados > v_origen.cantidad_actual_peces THEN
        RAISE EXCEPTION 'Peces a trasladar superan la población actual del lote';
    END IF;

    v_proporcion := p_peces_trasladados::NUMERIC / v_origen.cantidad_actual_peces::NUMERIC;
    v_costo_alevinos := v_origen.costo_inicial_alevinos * v_proporcion;
    v_costo_insumos := v_origen.costo_acumulado_insumos * v_proporcion;
    v_costo_fijo := v_origen.costo_acumulado_fijo * v_proporcion;

    IF p_es_desdoble THEN
        v_nuevo_lote_id := uuid_generate_v4();

        -- Actualizar lote origen
        UPDATE public.lotes SET
            cantidad_actual_peces = cantidad_actual_peces - p_peces_trasladados,
            biomasa_actual_kg = GREATEST(0.0, biomasa_actual_kg - p_biomasa_trasladada_kg),
            costo_inicial_alevinos = costo_inicial_alevinos - v_costo_alevinos,
            costo_acumulado_insumos = costo_acumulado_insumos - v_costo_insumos,
            costo_acumulado_fijo = costo_acumulado_fijo - v_costo_fijo
        WHERE id = p_lote_origen_id;

        -- Insertar nuevo lote
        INSERT INTO public.lotes (
            id, empresa_id, unidad_acuicola_id, estanque_id, lote_padre_id,
            codigo_lote, especie, cantidad_inicial_peces, cantidad_actual_peces,
            peso_inicial_gramos, peso_actual_gramos, biomasa_inicial_kg, biomasa_actual_kg,
            costo_inicial_alevinos, costo_acumulado_insumos, costo_acumulado_fijo,
            estado, fecha_siembra
        ) VALUES (
            v_nuevo_lote_id, p_empresa_id, p_unidad_id, p_estanque_destino_id, p_lote_origen_id,
            p_nuevo_codigo_lote, v_origen.especie, p_peces_trasladados, p_peces_trasladados,
            v_origen.peso_actual_gramos, v_origen.peso_actual_gramos, p_biomasa_trasladada_kg, p_biomasa_trasladada_kg,
            v_costo_alevinos, v_costo_insumos, v_costo_fijo,
            'Activo', CURRENT_DATE
        );
    ELSE
        -- Traslado total
        v_nuevo_lote_id := p_lote_origen_id;
        UPDATE public.lotes SET estanque_id = p_estanque_destino_id WHERE id = p_lote_origen_id;
    END IF;

    -- Registrar auditoría inmutable
    INSERT INTO public.traslados_lotes (
        empresa_id, unidad_acuicola_id, lote_origen_id, lote_destino_id,
        estanque_origen_id, estanque_destino_id, tipo_operacion,
        peces_trasladados, peso_promedio_gramos, biomasa_trasladada_kg,
        proporcion_costos, costo_alevinos_transferido, costo_insumos_transferido,
        costo_fijo_transferido, costo_total_transferido, nuevo_codigo_lote, registrado_por
    ) VALUES (
        p_empresa_id, p_unidad_id, p_lote_origen_id, v_nuevo_lote_id,
        p_estanque_origen_id, p_estanque_destino_id,
        CASE WHEN p_es_desdoble THEN 'DESDOBLE_PARCIAL' ELSE 'TRASLADO_TOTAL' END,
        p_peces_trasladados, v_origen.peso_actual_gramos, p_biomasa_trasladada_kg,
        v_proporcion, v_costo_alevinos, v_costo_insumos, v_costo_fijo,
        (v_costo_alevinos + v_costo_insumos + v_costo_fijo), p_nuevo_codigo_lote, p_registrado_por
    );

    -- Recalcular biomasa de ambos estanques como SUM(lotes.biomasa_actual_kg)
    SELECT COALESCE(SUM(biomasa_actual_kg), 0.0) INTO v_tot_bio_origen FROM public.lotes WHERE estanque_id = p_estanque_origen_id AND estado = 'Activo';
    UPDATE public.estanques SET 
        biomasa_kg = v_tot_bio_origen,
        estado = CASE WHEN v_tot_bio_origen <= 0.0 THEN 'Disponible' ELSE 'Activo' END,
        especie_actual = CASE WHEN v_tot_bio_origen <= 0.0 THEN '' ELSE especie_actual END
    WHERE id = p_estanque_origen_id;

    SELECT COALESCE(SUM(biomasa_actual_kg), 0.0) INTO v_tot_bio_destino FROM public.lotes WHERE estanque_id = p_estanque_destino_id AND estado = 'Activo';
    UPDATE public.estanques SET 
        biomasa_kg = v_tot_bio_destino,
        estado = 'Activo',
        especie_actual = v_origen.especie
    WHERE id = p_estanque_destino_id;

    RETURN jsonb_build_object('success', true, 'nuevo_lote_id', v_nuevo_lote_id);
END;
$$;
```

### Propuesta 4: Descontar `cantidadActualPeces` en Ventas y Cosechas
En `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`:
```dart
  void _handleHarvestSaleRecorded(HarvestSaleRecordedEvent event) async {
    final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
    if (bIndex != -1) {
      final oldBatch = state.batches[bIndex];
      final remanenteBiomasa = (oldBatch.biomasaActualKg - event.biomasaVendidaKg).clamp(0.0, double.infinity);
      final isTotalHarvest = remanenteBiomasa <= 5.0;

      // Calcular peces cosechados con base en el peso promedio actual
      final pesoPromG = oldBatch.pesoActualGramos > 0 ? oldBatch.pesoActualGramos : 1.0;
      final pecesVendidosEstimados = ((event.biomasaVendidaKg * 1000.0) / pesoPromG).round();
      final remanentePeces = isTotalHarvest
          ? 0
          : (oldBatch.cantidadActualPeces - pecesVendidosEstimados).clamp(0, oldBatch.cantidadActualPeces);

      final updatedBatch = oldBatch.copyWith(
        biomasaActualKg: remanenteBiomasa,
        cantidadActualPeces: remanentePeces,
        estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      Pond? targetPondUpdated;
      final updatedPonds = state.ponds.map((p) {
        if (p.id == oldBatch.estanqueId) {
          final up = p.copyWith(
            biomasaKg: remanenteBiomasa,
            estado: isTotalHarvest ? PondStatus.available : p.estado,
            especieActual: isTotalHarvest ? '' : p.especieActual,
            costoAcumuladoBiologico: isTotalHarvest ? 0.0 : (p.costoAcumuladoBiologico - event.cogs).clamp(0.0, double.infinity),
          );
          targetPondUpdated = up;
          return up;
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);
      await _repository.updateBatch(updatedBatch);
      if (targetPondUpdated != null) {
        await _repository.updatePond(targetPondUpdated!);
      }
    }
  }
```

### Propuesta 5: Adaptador Multiplataforma para Descarga de Archivos Excel ICA
En `lib/core/reports/web_download_helper.dart` y `web_download_helper_stub.dart`:
Incorporar soporte nativo con `path_provider` y `share_plus` / `open_filex` para que en Android, iOS y Windows el archivo se guarde físicamente en la carpeta de descargas del usuario y se abra el selector nativo de compartir, eliminando la condición restrictiva `if (bytes != null && kIsWeb)`.
