# HANDOFF REPORT — EXPLORER M1_2

**Fecha:** 2026-10-27  
**De:** `explorer_m1_2`  
**Para:** `orchestrator_2` / `worker`  
**Misión:** Investigación y recomendaciones verificadas para Milestone 1: Lógica de Repositorios, Preservación de Biomasa en Policultivos, Deducción de Peces en Cosecha y Exportación de Reportes Oficiales ICA en Plataformas Nativas.

---

## 1. OBSERVATION

### A. Repositorio de Estanques y Lotes (`supabase_ponds_repository.dart`)

1. **Traslados y Desdobles No Atómicos y Corrupción de Biomasa (`lines 577-683`):**
   En `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
   ```dart
   598:         await _supabase.from('lotes').update({
   599:           'cantidad_actual_peces': remanentePeces,
   600:           'biomasa_actual_kg': remanenteBiomasa,
   601:           'costo_acumulado_insumos': origenBatch.costoAcumuladoInsumos - costoInsumosProporcional,
   602:           'costo_acumulado_fijo': origenBatch.costoAcumuladoFijo - costoFijoProporcional,
   603:           'costo_inicial_alevinos': origenBatch.costoInicialAlevinos - costoAlevinesProporcional,
   604:         }).eq('id', batchOrigenId);
   605: 
   606:         await _supabase.from('estanques').update({
   607:           'biomasa_kg': remanenteBiomasa,
   608:         }).eq('id', estanqueOrigenId);
   ...
   635:         await _supabase.from('estanques').update({
   636:           'estado': 'Activo',
   637:           'especie': origenBatch.especie,
   638:           'biomasa_kg': biomasaTrasladadaKg,
   639:         }).eq('id', estanqueDestinoId);
   ```
   - Se ejecutan 5 llamadas REST secuenciales (`lotes.update`, `estanques.update`, `lotes.insert`, `estanques.update`, `traslados_lotes.insert`).
   - La actualización de `estanques` en la línea 607 asigna `biomasa_kg: remanenteBiomasa` directamente al estanque origen, ignorando la biomasa de cualquier otro lote activo que comparta el estanque (policultivo).
   - En la línea 638, asigna `biomasa_kg: biomasaTrasladadaKg` al estanque destino, sobrescribiendo cualquier biomasa previa en ese estanque.
   - En traslados totales (líneas 646-656), la línea 649 fuerza `'biomasa_kg': 0.0` y `'estado': 'Disponible'` en el estanque origen, aun si existiera otro lote activo en el mismo estanque.

2. **Sobreescritura de Biomasa en Mortalidad (`lines 928-937`):**
   En `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
   ```dart
   928:       if (newCount >= 0) {
   929:         await _supabase.from('lotes').update({
   930:           'cantidad_actual_peces': newCount,
   931:           'biomasa_actual_kg': newBiomass,
   932:         }).eq('id', loteId);
   933: 
   934:         await _supabase.from('estanques').update({
   935:           'biomasa_kg': newBiomass,
   936:         }).eq('id', estanqueId);
   937:       }
   ```
   - `newBiomass` (línea 880) se calcula como:
     ```dart
     newBiomass = (newCount * effectivePeso) / 1000.0;
     ```
   - Esto corresponde **únicamente** a la biomasa remanente del lote intervenido (`loteId`). Al actualizar `estanques.biomasa_kg = newBiomass` (línea 935), la biomasa del estanque queda reducida a un único lote, borrando la biomasa de las demás especies presentes en el policultivo.
   - En modo Demo (líneas 838-841), ocurre la misma sobreescritura:
     ```dart
     _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: newBiomass);
     ```

3. **Sobreescritura de Biomasa en Biometría (`lines 1096-1100`):**
   En `lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`:
   ```dart
   1096:       if (newBiomass > 0.0) {
   1097:         await _supabase.from('estanques').update({
   1098:           'biomasa_kg': newBiomass,
   1099:         }).eq('id', estanqueId);
   1100:       }
   ```
   - `newBiomass` es el producto del pesaje de muestra del lote específico (`(currentPeces * nuevoPesoPromedioGramos) / 1000.0`). Asignarlo a `estanques.biomasa_kg` destruye la biomasa del estanque para cualquier otro lote activo.
   - En modo Demo (líneas 990-993), ocurre lo mismo:
     ```dart
     _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: newBiomass);
     ```

4. **Sobreescritura de Biomasa en Siembra de Nuevos Lotes (`lines 418-423`):**
   ```dart
   418:       await _supabase.from('estanques').update({
   419:         'estado': 'Activo',
   420:         'especie': batch.especie,
   421:         'biomasa_kg': batch.biomasaActualKg,
   422:         'costo_acumulado_biologico': batch.costoTotal,
   423:       }).eq('id', batch.estanqueId);
   ```
   - Al sembrar una segunda especie (policultivo), la biomasa del estanque se reescribe como `batch.biomasaActualKg` en vez de sumarse a la biomasa preexistente.

---

### B. Deducción de Peces y Biomasa en Ventas de Cosecha

1. **Evento de Dominio Incompleto (`lib/core/events/app_event_bus.dart:26-38`):**
   ```dart
   26: class HarvestSaleRecordedEvent extends AppDomainEvent {
   27:   final String loteId;
   28:   final double biomasaVendidaKg;
   29:   final double ingresoBruto;
   30:   final double cogs;
   31: 
   32:   HarvestSaleRecordedEvent({
   33:     required this.loteId,
   34:     required this.biomasaVendidaKg,
   35:     required this.ingresoBruto,
   36:     required this.cogs,
   37:   });
   38: }
   ```
   - `HarvestSaleRecordedEvent` carece del atributo de conteo de peces vendidos (`pecesVendidos`).

2. **Omisión de Transmisión de Peces en el Repositorio de Ventas (`lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart:117-122`):**
   ```dart
   117:       _eventBus.fire(HarvestSaleRecordedEvent(
   118:         loteId: sale.loteId,
   119:         biomasaVendidaKg: sale.biomasaVendidaKg,
   120:         ingresoBruto: sale.ingresoBruto,
   121:         cogs: sale.cogs,
   122:       ));
   ```
   - La entidad `BatchSale` cuenta con `final int cantidadPeces;` (línea 62 de `batch_sale.dart`), y el modal `venta_rapida_modal.dart` la calcula e instancia correctamente (línea 807). No obstante, el repositorio no la incluye al disparar el evento.

3. **Omisión de Descuento de Peces en `PondsNotifier` ("Peces Fantasma", `lib/modules/ponds_batches/presentation/providers/ponds_provider.dart:189-220`):**
   ```dart
   189:   void _handleHarvestSaleRecorded(HarvestSaleRecordedEvent event) {
   190:     final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
   191:     if (bIndex != -1) {
   192:       final oldBatch = state.batches[bIndex];
   193:       final remanenteBiomasa = (oldBatch.biomasaActualKg - event.biomasaVendidaKg).clamp(0.0, double.infinity);
   194:       final isTotalHarvest = remanenteBiomasa <= 5.0; // margen técnico de cierre
   195: 
   196:       final updatedBatch = oldBatch.copyWith(
   197:         biomasaActualKg: remanenteBiomasa,
   198:         estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
   199:       );
   ...
   207:           final up = p.copyWith(
   208:             biomasaKg: remanenteBiomasa,
   209:             estado: isTotalHarvest ? PondStatus.available : p.estado,
   210:             especieActual: isTotalHarvest ? '' : p.especieActual,
   ```
   - `updatedBatch` descuenta `biomasaActualKg`, pero **mantiene intacto `cantidadActualPeces`**. En cosechas parciales, los peces permanecen en el registro virtual. Al realizar una biometría posterior ($W = \text{Biomasa} / N$), el peso promedio se desploma de forma errónea.
   - En `updatedPonds`, se asigna `biomasaKg: remanenteBiomasa` del lote individual directamente al estanque, destruyendo cualquier biomasa de otros lotes en el estanque. Si `isTotalHarvest` se cumple para este lote, el estanque se marca como `PondStatus.available` aunque contenga otro lote en cultivo activo.

---

### C. Exportación de Reportes Oficiales ICA en Plataformas Nativas

1. **Bloqueo Incondicional en la Validación Web (`lib/core/reports/ica_official_reports_engine.dart:53-58`):**
   ```dart
   53:   void _downloadExcel(Excel excel, String filename) {
   54:     final bytes = excel.save();
   55:     if (bytes != null && kIsWeb) {
   56:       downloadFileWeb(bytes, filename);
   57:     }
   58:   }
   ```
   - La condición `&& kIsWeb` impide que cualquier plataforma móvil o escritorio (Android, iOS, Windows, macOS, Linux) intente descargar o compartir el archivo generado. En dichas plataformas, el método es un no-op que descarta los bytes del archivo Excel en memoria.

2. **Stub Vacío para Plataformas No-Web (`lib/core/reports/web_download_helper_stub.dart:1-5`):**
   ```dart
   1: /// Stub for non-web platforms
   2: void downloadFileWeb(List<int> bytes, String fileName) {
   3:   // En plataformas móviles/escritorio se maneja a través de file_picker o share_plus
   4: }
   ```
   - El archivo stub no tiene código ejecutable.

3. **Arquitectura de Exportación Condicional Existente (`lib/core/reports/web_download_helper.dart:1-3`):**
   ```dart
   1: export 'web_download_helper_stub.dart'
   2:     if (dart.library.html) 'web_download_helper_web.dart';
   ```
   - La arquitectura de exportación condicional ya está correctamente estructurada. Si se compila para Web (`dart.library.html`), el compilador carga `web_download_helper_web.dart` (que utiliza `dart:html`). Si se compila para plataformas nativas, carga `web_download_helper_stub.dart`.
   - `path_provider` ya se encuentra resuelto en `pubspec.lock` (versión 2.1.6).

---

## 2. LOGIC CHAIN

### Paso 1: Preservación de Biomasa en Policultivos en `SupabasePondsRepository`
- **Fundamento (Obs. A.1, A.2, A.3, A.4):** En acuicultura moderna, un estanque físico puede alojar múltiples lotes biológicos (policultivo: ej. Tilapia Roja como especie principal y Cachama Blanca como especie secundaria, o lotes de tallas escalonadas).
- **Causa Raíz:** Cada operación (`registerMortality`, `registerBiometry`, `createBatch`, `transferOrSplitBatch`) calcula la nueva biomasa del lote específico e inmediatamente ejecuta:
  ```dart
  await _supabase.from('estanques').update({'biomasa_kg': newBiomass}).eq('id', estanqueId);
  ```
- **Inferencia:** Para mantener la coherencia biológica y regulatoria, la biomasa total de un estanque debe ser invariablemente la suma agregada ($\sum$) de las biomasas de todos los lotes cuyo estado sea `Activo` en dicho estanque.
- **Solución Técnica:**
  1. Para transferencias y desdobles: Reemplazar las 5 llamadas REST del cliente con la llamada al RPC atómico `public.split_or_transfer_batch` que ejecuta `UPDATE public.estanques SET biomasa_kg = COALESCE((SELECT SUM(biomasa_actual_kg) FROM public.lotes WHERE estanque_id = e.id AND estado ILIKE 'activ%'), 0.0)`.
  2. Para operaciones directas en `SupabasePondsRepository` (`registerMortality`, `registerBiometry`, `createBatch`): Implementar una función auxiliar reutilizable `_syncPondBiomassAndCount(String estanqueId)` que consulte todos los lotes activos del estanque en Supabase y actualice `biomasa_kg` y `cantidad_peces` con la suma real.
  3. En memoria demo (`_demoPonds`): Agregar la suma sobre `_demoBatches.where((b) => b.estanqueId == estanqueId && b.estado == BatchStatus.active)`.

### Paso 2: Eliminación de Peces Fantasma en Cosecha
- **Fundamento (Obs. B.1, B.2, B.3):** Una cosecha parcial retira individuos físicos del estanque junto con sus kilogramos. Si solo se descuenta la biomasa en `PondsNotifier`, el número de peces permanece inalterado.
- **Consecuencia Matemática:** Si un lote tiene 5.000 peces y 2.500 kg ($500\text{ g/pez}$), y se cosechan 1.250 kg (aproximadamente 2.500 peces), la biomasa se reduce a 1.250 kg. Si `cantidadActualPeces` permanece en 5.000, el peso promedio implícito pasa a ser $1.250\text{ kg} / 5.000 = 250\text{ g/pez}$, provocando una distorsión crítica en las curvas de crecimiento y en el Factor de Conversión Alimenticia (FCR).
- **Solución Técnica:**
  1. Incorporar `final int pecesVendidos;` a `HarvestSaleRecordedEvent`.
  2. En `SupabaseSalesRepository.recordSale`, transmitir `pecesVendidos: sale.cantidadPeces`.
  3. En `PondsNotifier._handleHarvestSaleRecorded`:
     - Calcular `pecesVendidos`: Si `event.pecesVendidos > 0`, usarlo directamente; si no, calcular la proporción `(oldBatch.cantidadActualPeces * (event.biomasaVendidaKg / oldBatch.biomasaActualKg)).round()`.
     - Actualizar `cantidadActualPeces = isTotalHarvest ? 0 : (oldBatch.cantidadActualPeces - pecesVendidos).clamp(0, oldBatch.cantidadActualPeces)`.
     - Para el estanque: recalcular la biomasa total sumando todos los lotes activos restantes en dicho estanque. Si aún quedan otros lotes activos, el estanque se mantiene `PondStatus.active` y conserva su especie; solo si no quedan lotes activos pasa a `PondStatus.available`.

### Paso 3: Activación de Descarga Oficial de Libros ICA en Móvil y Escritorio
- **Fundamento (Obs. C.1, C.2, C.3):** Los operarios y directores técnicos en campo utilizan dispositivos móviles (Android/iOS) y estaciones de escritorio para la administración de la granja. El botón de exportación oficial no debe fallar silenciosamente en ninguna plataforma.
- **Causa Raíz:** En `ica_official_reports_engine.dart:55`, el guard `&& kIsWeb` aborta la operación en plataformas nativas, y `web_download_helper_stub.dart` es un método vacío.
- **Compatibilidad con Flutter Web:**
  - Debido a la exportación condicional `export 'web_download_helper_stub.dart' if (dart.library.html) 'web_download_helper_web.dart'`, Flutter Web **nunca** compila `web_download_helper_stub.dart`.
  - En consecuencia, en `web_download_helper_stub.dart` se puede importar con total seguridad `dart:io`, `package:path_provider/path_provider.dart` y `package:share_plus/share_plus.dart`.
  - La función escribe los bytes en el directorio temporal (`getTemporaryDirectory()`) y abre la hoja nativa de compartir del sistema (`Share.shareXFiles`), permitiendo al usuario enviar el libro oficial por correo, WhatsApp, guardarlo en Google Drive, o archivarlo localmente.
  - Al remover `&& kIsWeb` en `ica_official_reports_engine.dart:55`, la llamada `downloadFileWeb(bytes, filename)` se ejecuta en todas las plataformas sin alterar la descarga web vía Blob.

---

## 3. CAVEATS

1. **Dependencia `share_plus` en `pubspec.yaml`:**
   `path_provider` ya está resuelto en `pubspec.lock` (v2.1.6). Sin embargo, `share_plus` debe añadirse explícitamente a `pubspec.yaml` (ej. `share_plus: ^10.0.0` o `^9.0.0`). Si no se añade al manifest, `flutter analyze` reportará paquete no encontrado.
2. **Permisos de Almacenamiento en Android/iOS:**
   Al escribir en `getTemporaryDirectory()` o `getApplicationDocumentsDirectory()`, no se requieren permisos en tiempo de ejecución en Android (scoped storage moderno) ni en iOS (sandbox de la aplicación). El uso de `Share.shareXFiles` delega la persistencia final o transferencia al usuario a través del sistema operativo.
3. **RPC `public.split_or_transfer_batch`:**
   Esta función debe estar creada en la base de datos de Supabase (tarea investigada por `explorer_m1_1` para la migración SQL `20261027_master_traceability_and_rls_hardening.sql`). En el repositorio Dart, es prudente mantener un bloque `try/catch` con fallback controlado si la RPC aún no ha sido aplicada en la base de datos de destino.

---

## 4. CONCLUSION & CONCRETE RECOMMENDATIONS FOR THE WORKER

A continuación se presentan los cambios exactos (drop-in) que el Worker debe aplicar para resolver integralmente los requerimientos asignados a este frente.

### Recomendación 1: Actualización de `HarvestSaleRecordedEvent` (`lib/core/events/app_event_bus.dart`)

```dart
// En lib/core/events/app_event_bus.dart
class HarvestSaleRecordedEvent extends AppDomainEvent {
  final String loteId;
  final double biomasaVendidaKg;
  final double ingresoBruto;
  final double cogs;
  final int pecesVendidos;

  HarvestSaleRecordedEvent({
    required this.loteId,
    required this.biomasaVendidaKg,
    required this.ingresoBruto,
    required this.cogs,
    this.pecesVendidos = 0,
  });
}
```

### Recomendación 2: Disparo de Conteo de Peces en Repositorio de Ventas (`lib/modules/sales_harvest/infrastructure/repositories/supabase_sales_repository.dart`)

En las líneas 117-122 y 128-133 de `supabase_sales_repository.dart`:
```dart
      _eventBus.fire(HarvestSaleRecordedEvent(
        loteId: sale.loteId,
        biomasaVendidaKg: sale.biomasaVendidaKg,
        ingresoBruto: sale.ingresoBruto,
        cogs: sale.cogs,
        pecesVendidos: sale.cantidadPeces,
      ));
```

### Recomendación 3: Deducción Proporcional de Peces y Agregación de Policultivo en Cosecha (`lib/modules/ponds_batches/presentation/providers/ponds_provider.dart`)

Reemplazar `_handleHarvestSaleRecorded` (líneas 189-225) con:
```dart
  void _handleHarvestSaleRecorded(HarvestSaleRecordedEvent event) {
    final bIndex = state.batches.indexWhere((b) => b.id == event.loteId);
    if (bIndex != -1) {
      final oldBatch = state.batches[bIndex];
      final remanenteBiomasa = (oldBatch.biomasaActualKg - event.biomasaVendidaKg).clamp(0.0, double.infinity);

      // Deducción exacta o proporcional de peces para prevenir peces fantasma
      final int pecesVendidos = event.pecesVendidos > 0
          ? event.pecesVendidos
          : (oldBatch.biomasaActualKg > 0
              ? (oldBatch.cantidadActualPeces * (event.biomasaVendidaKg / oldBatch.biomasaActualKg)).round()
              : 0);
      final int remanentePeces = (oldBatch.cantidadActualPeces - pecesVendidos).clamp(0, oldBatch.cantidadActualPeces);
      final isTotalHarvest = remanenteBiomasa <= 5.0 || remanentePeces <= 0;

      final updatedBatch = oldBatch.copyWith(
        biomasaActualKg: isTotalHarvest ? 0.0 : remanenteBiomasa,
        cantidadActualPeces: isTotalHarvest ? 0 : remanentePeces,
        estado: isTotalHarvest ? BatchStatus.harvested : oldBatch.estado,
      );

      final updatedBatches = List<FishBatch>.from(state.batches);
      updatedBatches[bIndex] = updatedBatch;

      // Soporte de policultivo: calcular la biomasa remanente total del estanque
      // sumando todos los lotes que permanezcan ACTIVOS en dicho estanque
      final activeBatchesInPond = updatedBatches.where(
        (b) => b.estanqueId == oldBatch.estanqueId && b.estado == BatchStatus.active,
      ).toList();

      final totalBiomasaEstanque = activeBatchesInPond.fold<double>(
        0.0, (acc, b) => acc + b.biomasaActualKg,
      );
      final bool pondHasActiveBatches = activeBatchesInPond.isNotEmpty;

      Pond? targetPondUpdated;
      final updatedPonds = state.ponds.map((p) {
        if (p.id == oldBatch.estanqueId) {
          final up = p.copyWith(
            biomasaKg: totalBiomasaEstanque,
            estado: pondHasActiveBatches ? PondStatus.active : PondStatus.available,
            especieActual: pondHasActiveBatches ? p.especieActual : '',
            costoAcumuladoBiologico: pondHasActiveBatches
                ? (p.costoAcumuladoBiologico - event.cogs).clamp(0.0, double.infinity)
                : 0.0,
          );
          targetPondUpdated = up;
          return up;
        }
        return p;
      }).toList();

      state = state.copyWith(batches: updatedBatches, ponds: updatedPonds);

      // Persistir en base de datos
      _repository.updateBatch(updatedBatch);
      if (targetPondUpdated != null) {
        _repository.updatePond(targetPondUpdated!);
      }
    }
  }
```

### Recomendación 4: Preservación de Biomasa en Policultivos en `SupabasePondsRepository` (`lib/modules/ponds_batches/infrastructure/repositories/supabase_ponds_repository.dart`)

1. **Añadir método auxiliar de sincronización en `SupabasePondsRepository`:**
```dart
  /// Recalcula y sincroniza la biomasa total y conteo de peces de un estanque
  /// mediante agregación (SUM) sobre todos los lotes activos (soporte policultivo).
  Future<void> _syncPondBiomassAndCount(String estanqueId) async {
    try {
      final activeLotsRes = await _supabase
          .from('lotes')
          .select('biomasa_actual_kg, cantidad_actual_peces')
          .eq('estanque_id', estanqueId)
          .inFilter('estado', ['Activo', 'activo', 'ACTIVO']);

      double totalBiomasa = 0.0;
      int totalPeces = 0;
      if (activeLotsRes is List) {
        for (final row in activeLotsRes) {
          totalBiomasa += (row['biomasa_actual_kg'] as num?)?.toDouble() ?? 0.0;
          totalPeces += (row['cantidad_actual_peces'] as num?)?.toInt() ?? 0;
        }
      }

      await _supabase.from('estanques').update({
        'biomasa_kg': totalBiomasa,
        'cantidad_peces': totalPeces,
        'estado': totalBiomasa > 0.0 ? 'Activo' : 'Disponible',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', estanqueId);
    } catch (e) {
      debugPrint('[PondsRepository] Error sincronizando biomasa del estanque $estanqueId: $e');
    }
  }
```

2. **Reemplazar la sobreescritura de biomasa en `registerMortality` (líneas 928-937):**
```dart
      // Actualizar conteo y biomasa en lotes y sincronizar estanque considerando policultivo
      if (newCount >= 0) {
        await _supabase.from('lotes').update({
          'cantidad_actual_peces': newCount,
          'biomasa_actual_kg': newBiomass,
        }).eq('id', loteId);

        await _syncPondBiomassAndCount(estanqueId);
      }
```
Y en modo demo de `registerMortality` (líneas 838-842):
```dart
        final pondIdx = _demoPonds.indexWhere((p) => p.id == estanqueId);
        if (pondIdx != -1) {
          final totalBiomasa = _demoBatches
              .where((b) => b.estanqueId == estanqueId && b.estado == BatchStatus.active)
              .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: totalBiomasa);
        }
```

3. **Reemplazar la sobreescritura de biomasa en `registerBiometry` (líneas 1096-1100):**
```dart
      if (newBiomass > 0.0) {
        await _syncPondBiomassAndCount(estanqueId);
      }
```
Y en modo demo de `registerBiometry` (líneas 990-994):
```dart
        final pondIdx = _demoPonds.indexWhere((p) => p.id == estanqueId);
        if (pondIdx != -1) {
          final totalBiomasa = _demoBatches
              .where((b) => b.estanqueId == estanqueId && b.estado == BatchStatus.active)
              .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
          _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(biomasaKg: totalBiomasa);
        }
```

4. **Reemplazar la sobreescritura de biomasa en `createBatch` (líneas 418-423):**
```dart
      await _supabase.from('estanques').update({
        'estado': 'Activo',
        'especie': batch.especie,
        'costo_acumulado_biologico': batch.costoTotal,
      }).eq('id', batch.estanqueId);

      await _syncPondBiomassAndCount(batch.estanqueId);
```
Y en modo demo de `createBatch` (líneas 383-391):
```dart
      final pondIdx = _demoPonds.indexWhere((p) => p.id == batch.estanqueId);
      if (pondIdx != -1) {
        final totalBiomasa = _demoBatches
            .where((b) => b.estanqueId == batch.estanqueId && b.estado == BatchStatus.active)
            .fold<double>(0.0, (acc, b) => acc + b.biomasaActualKg);
        final totalCosto = _demoBatches
            .where((b) => b.estanqueId == batch.estanqueId && b.estado == BatchStatus.active)
            .fold<double>(0.0, (acc, b) => acc + b.costoTotal);
        _demoPonds[pondIdx] = _demoPonds[pondIdx].copyWith(
          estado: PondStatus.active,
          especieActual: batch.especie,
          biomasaKg: totalBiomasa,
          costoAcumuladoBiologico: totalCosto,
        );
      }
```

5. **Llamada atómica RPC en `transferOrSplitBatch` (líneas 576-685):**
```dart
    // Flujo para Empresas Reales en Supabase mediante RPC Atómica
    try {
      final loteOrigenRes = await _supabase
          .from('lotes')
          .select('peso_actual_gramos')
          .eq('id', batchOrigenId)
          .single();

      final pesoPromedio = (loteOrigenRes['peso_actual_gramos'] as num?)?.toDouble() ??
          (pecesTrasladados > 0 ? (biomasaTrasladadaKg * 1000.0 / pecesTrasladados) : 100.0);

      await _supabase.rpc('split_or_transfer_batch', params: {
        'p_lote_origen_id': batchOrigenId,
        'p_estanque_destino_id': estanqueDestinoId,
        'p_tipo_operacion': esDesdoble ? 'DESDOBLE_PARCIAL' : 'TRASLADO_TOTAL',
        'p_peces_trasladar': pecesTrasladados,
        'p_peso_promedio': pesoPromedio,
        'p_nuevo_codigo_lote': nuevoCodigoLote,
        'p_motivo': 'Operación de ${esDesdoble ? 'desdoble parcial' : 'traslado total'}',
        'p_registrado_por': registradoPor ?? 'Admin Acuícola',
      });
    } catch (e) {
      debugPrint('[PondsRepository] Error en transferOrSplitBatch (RPC): $e');
      rethrow;
    }
```

### Recomendación 5: Exportación de Reportes en Móvil/Escritorio (`web_download_helper_stub.dart` & `ica_official_reports_engine.dart`)

1. **Añadir dependencias en `pubspec.yaml`:**
```yaml
  path_provider: ^2.1.2
  share_plus: ^10.0.0
```

2. **Implementar `lib/core/reports/web_download_helper_stub.dart`:**
```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Helper para plataformas no-web (Android, iOS, Windows, macOS, Linux):
/// Guarda el archivo en el directorio temporal y abre el diálogo nativo de compartir
Future<void> downloadFileWeb(List<int> bytes, String fileName) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Libro Oficial ICA / AUNAP: $fileName',
      subject: fileName,
    );
  } catch (e) {
    debugPrint('[ReportExport] Error al exportar archivo $fileName en plataforma nativa: $e');
  }
}
```

3. **Habilitar descarga universal en `lib/core/reports/ica_official_reports_engine.dart:53-58`:**
```dart
  void _downloadExcel(Excel excel, String filename) {
    final bytes = excel.save();
    if (bytes != null) {
      downloadFileWeb(bytes, filename);
    }
  }
```

---

## 5. VERIFICATION METHOD

1. **Verificación de Análisis Estático:**
   ```powershell
   flutter analyze --no-fatal-infos
   ```
   *Criterio de Aceptación:* 0 errores y 0 advertencias en todos los archivos modificados.

2. **Verificación de Deducción de Peces en Cosecha:**
   - Crear o seleccionar un lote con $10.000$ peces y $5.000\text{ kg}$ ($500\text{ g/pez}$).
   - Registrar una venta parcial de cosecha de $2.500\text{ kg}$ ($5.000$ peces).
   - Inspeccionar el lote resultante:
     - `biomasaActualKg` debe ser $2.500\text{ kg}$.
     - `cantidadActualPeces` debe ser $5.000$ peces (no $10.000$).
     - Peso promedio calculado: $2.500\text{ kg} / 5.000 = 500\text{ g/pez}$ (preservado).

3. **Verificación de Preservación de Biomasa en Policultivos:**
   - Asignar al Estanque 1 dos lotes activos: Lote A ($1.000\text{ kg}$ Tilapia) y Lote B ($800\text{ kg}$ Cachama).
   - Biomasa total inicial del estanque: $1.800\text{ kg}$.
   - Registrar biometría en el Lote A ajustando su biomasa a $1.100\text{ kg}$.
   - Inspeccionar el Estanque 1:
     - `biomasa_kg` debe ser $1.100 + 800 = 1.900\text{ kg}$ (no $1.100\text{ kg}$).
   - Registrar mortalidad en el Lote B (baja de $10\text{ kg}$).
   - Inspeccionar el Estanque 1:
     - `biomasa_kg` debe ser $1.100 + 790 = 1.890\text{ kg}$.

4. **Verificación de Exportación de Libros ICA en No-Web:**
   - En Android/iOS/Windows, ingresar a la pantalla de Certificación ICA (`IcaCertificationScreen`).
   - Tocar "Exportar F-05" o cualquier libro oficial.
   - En Android/iOS: debe desplegarse el modal nativo `ShareSheet` con el archivo `.xlsx` adjunto.
   - En Web: debe iniciarse la descarga directa vía navegador.

5. **Condiciones de Invalidación:**
   - Si `_handleHarvestSaleRecorded` asigna `biomasaKg` sin filtrar por lotes activos del estanque, la prueba de policultivo se invalida.
   - Si `web_download_helper_stub.dart` importa `dart:html`, la compilación en plataformas móviles fallará.
   - Si `web_download_helper_web.dart` importa `dart:io`, la compilación web fallará.
