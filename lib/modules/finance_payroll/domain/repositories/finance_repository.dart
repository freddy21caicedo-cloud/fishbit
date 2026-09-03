import '../models/payroll_record.dart';
import '../models/payroll_config.dart';
import '../models/jornal_record.dart';
import '../models/energy_bill.dart';
import '../models/maintenance_record.dart';

abstract class FinanceRepository {
  Future<List<PayrollRecord>> fetchPayroll(String empresaId, String unidadAcuicolaId);
  Future<PayrollRecord> createPayrollRecord(PayrollRecord record);
  Future<void> deletePayrollRecord(String recordId);

  Future<PayrollConfig> fetchPayrollConfig(String empresaId);
  Future<void> savePayrollConfig(String empresaId, PayrollConfig config);

  Future<List<JornalRecord>> fetchJornales(String empresaId, String unidadAcuicolaId);
  Future<JornalRecord> createJornalRecord(JornalRecord record);
  Future<void> deleteJornalRecord(String recordId);

  Future<List<EnergyBill>> fetchEnergyBills(String empresaId, String unidadAcuicolaId);
  Future<EnergyBill> recordEnergyBill(EnergyBill bill);

  Future<List<MaintenanceRecord>> fetchMaintenances(String empresaId, String unidadAcuicolaId);
  Future<MaintenanceRecord> recordMaintenance(MaintenanceRecord record);
}


