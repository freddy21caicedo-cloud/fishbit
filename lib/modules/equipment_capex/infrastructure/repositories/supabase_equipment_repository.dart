import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/modules/equipment_capex/domain/models/equipment_asset.dart';
import 'package:fishbit_finance/modules/equipment_capex/domain/repositories/equipment_repository.dart';

class SupabaseEquipmentRepository implements EquipmentRepository {
  final SupabaseClient _supabase;

  SupabaseEquipmentRepository(this._supabase);

  static final List<EquipmentAsset> _demoEquipment = [
    EquipmentAsset(
      id: 'eq100000-0000-0000-0000-000000000001',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      estanqueAsignadoId: 'p1000000-0000-0000-0000-000000000001',
      nombre: 'Aireador Splash 2.0 HP Monofásico',
      sigla: 'AIR-01',
      tipo: EquipmentType.aireacion,
      estadoSalud: EquipmentHealth.operativo,
      costoAdquisicion: 3200000.0,
      vidaUtilDias: 1095,
      hpPotencia: '2 HP',
      faseElectrica: 'Monofasico',
      horasUsoDiario: 12.0,
      creadoEn: DateTime.now().subtract(const Duration(days: 60)),
    ),
    EquipmentAsset(
      id: 'eq100000-0000-0000-0000-000000000002',
      empresaId: 'c1000000-0000-0000-0000-000000000001',
      unidadAcuicolaId: 'u1000000-0000-0000-0000-000000000001',
      nombre: 'Oxímetro Digital Óptico YSI ProDSS',
      sigla: 'OXI-01',
      tipo: EquipmentType.medicion,
      estadoSalud: EquipmentHealth.operativo,
      costoAdquisicion: 5800000.0,
      vidaUtilDias: 1825,
      categoriaMedicion: 'Medidor de oxigeno',
      creadoEn: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  @override
  Future<List<EquipmentAsset>> fetchEquipment(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoEquipment;
    }
    try {
      var query = _supabase.from('equipos').select('*');
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
      }
      final res = await query.order('creado_en', ascending: true).limit(100);

      final list = (res as List).map((row) => EquipmentAsset.fromJson(row as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _demoEquipment;
    } catch (_) {
      return _demoEquipment;
    }
  }

  @override
  Future<EquipmentAsset> createEquipment(EquipmentAsset equipment) async {
    if (equipment.empresaId.startsWith('c1000000-')) {
      _demoEquipment.add(equipment);
      return equipment;
    }
    try {
      final res = await _supabase
          .from('equipos')
          .insert(equipment.toJson())
          .select()
          .single();

      return EquipmentAsset.fromJson(res);
    } catch (_) {
      _demoEquipment.add(equipment);
      return equipment;
    }
  }

  @override
  Future<void> updateEquipment(EquipmentAsset equipment) async {
    final idx = _demoEquipment.indexWhere((e) => e.id == equipment.id);
    if (idx != -1) _demoEquipment[idx] = equipment;

    if (!equipment.empresaId.startsWith('c1000000-')) {
      try {
        await _supabase
            .from('equipos')
            .update(equipment.toJson())
            .eq('id', equipment.id);
      } catch (_) {}
    }
  }
}
