import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_config.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/jornal_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/energy_bill.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/maintenance_record.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/repositories/finance_repository.dart';


class SupabaseFinanceRepository implements FinanceRepository {
  final SupabaseClient _supabase;

  SupabaseFinanceRepository(this._supabase);

  static final List<PayrollRecord> _demoPayroll = [];

  static final List<EnergyBill> _demoEnergy = [];

  static final List<MaintenanceRecord> _demoMaintenances = [];


  @override
  Future<List<PayrollRecord>> fetchPayroll(String empresaId, String unidadAcuicolaId) async {
    try {
      var query = _supabase.from('registros_nomina').select('*');
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
      }
      final res = await query.order('fecha_pago', ascending: false).limit(100);

      final list = (res as List).map((row) => PayrollRecord.fromJson(row as Map<String, dynamic>)).toList();
      return list;
    } catch (_) {
      return _demoPayroll;
    }
  }

  @override
  Future<PayrollRecord> createPayrollRecord(PayrollRecord record) async {
    if (record.empresaId.startsWith('c1000000-')) {
      _demoPayroll.insert(0, record);
      return record;
    }
    try {
      final res = await _supabase
          .from('registros_nomina')
          .insert(record.toJson())
          .select()
          .single();

      return PayrollRecord.fromJson(res);
    } catch (_) {
      _demoPayroll.insert(0, record);
      return record;
    }
  }

  @override
  Future<void> deletePayrollRecord(String recordId) async {
    _demoPayroll.removeWhere((r) => r.id == recordId);
    try {
      await _supabase.from('registros_nomina').delete().eq('id', recordId);
    } catch (_) {}
  }


  @override
  Future<List<EnergyBill>> fetchEnergyBills(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoEnergy;
    }
    try {
      var query = _supabase.from('recibos_energia').select('*');
      if (empresaId.isNotEmpty) {
        query = query.eq('empresa_id', empresaId);
      }
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
      }
      final res = await query.order('fecha_emision', ascending: false).limit(100);

      final list = (res as List).map((row) => EnergyBill.fromJson(row as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _demoEnergy;
    } catch (_) {
      return _demoEnergy;
    }
  }

  @override
  Future<EnergyBill> recordEnergyBill(EnergyBill bill) async {
    if (bill.empresaId.startsWith('c1000000-')) {
      _demoEnergy.insert(0, bill);
      return bill;
    }
    try {
      final res = await _supabase
          .from('recibos_energia')
          .insert(bill.toJson())
          .select()
          .single();

      return EnergyBill.fromJson(res);
    } catch (_) {
      _demoEnergy.insert(0, bill);
      return bill;
    }
  }

  @override
  Future<List<MaintenanceRecord>> fetchMaintenances(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoMaintenances;
    }
    try {
      var query = _supabase.from('mantenimientos').select('*');
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unidad_acuicola_sigla', unidadAcuicolaId);
      }
      final res = await query.order('fecha', ascending: false).limit(100);

      final list = (res as List).map((row) => MaintenanceRecord.fromJson(row as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _demoMaintenances;
    } catch (_) {
      return _demoMaintenances;
    }
  }

  @override
  Future<MaintenanceRecord> recordMaintenance(MaintenanceRecord record) async {
    if (record.empresaId.startsWith('c1000000-')) {
      _demoMaintenances.insert(0, record);
      return record;
    }
    try {
      final res = await _supabase
          .from('mantenimientos')
          .insert(record.toJson())
          .select()
          .single();

      return MaintenanceRecord.fromJson(res);
    } catch (_) {
      _demoMaintenances.insert(0, record);
      return record;
    }
  }

  static PayrollConfig _demoConfig = const PayrollConfig();
  static final List<JornalRecord> _demoJornales = [];


  @override
  Future<PayrollConfig> fetchPayrollConfig(String empresaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoConfig;
    }
    try {
      final res = await _supabase
          .from('empresas')
          .select('configuraciones_nomina')
          .eq('id', empresaId)
          .maybeSingle();

      if (res != null && res['configuraciones_nomina'] != null) {
        return PayrollConfig.fromJson(res['configuraciones_nomina'] as Map<String, dynamic>);
      }
      return _demoConfig;
    } catch (_) {
      return _demoConfig;
    }
  }

  @override
  Future<void> savePayrollConfig(String empresaId, PayrollConfig config) async {
    _demoConfig = config;
    if (empresaId.startsWith('c1000000-')) return;
    try {
      await _supabase
          .from('empresas')
          .update({'configuraciones_nomina': config.toJson()})
          .eq('id', empresaId);
    } catch (_) {}
  }

  @override
  Future<List<JornalRecord>> fetchJornales(String empresaId, String unidadAcuicolaId) async {
    if (empresaId.startsWith('c1000000-')) {
      return _demoJornales;
    }
    try {
      var query = _supabase.from('jornales').select('*');
      if (unidadAcuicolaId.isNotEmpty) {
        query = query.eq('unit_id', unidadAcuicolaId);
      }
      final res = await query.order('fecha', ascending: false).limit(100);

      final list = (res as List).map((row) => JornalRecord.fromJson(row as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _demoJornales;
    } catch (_) {
      return _demoJornales;
    }
  }

  @override
  Future<JornalRecord> createJornalRecord(JornalRecord record) async {
    if (record.empresaId.startsWith('c1000000-')) {
      _demoJornales.insert(0, record);
      return record;
    }
    try {
      final res = await _supabase
          .from('jornales')
          .insert(record.toJson())
          .select()
          .single();

      return JornalRecord.fromJson(res);
    } catch (_) {
      _demoJornales.insert(0, record);
      return record;
    }
  }

  @override
  Future<void> deleteJornalRecord(String recordId) async {
    _demoJornales.removeWhere((j) => j.id == recordId);
    try {
      await _supabase.from('jornales').delete().eq('id', recordId);
    } catch (_) {}
  }
}


