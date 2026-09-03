import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_personal_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_vehiculo_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/models/ica_necropsia_record.dart';
import 'package:fishbit_finance/modules/ica_compliance/domain/repositories/ica_compliance_repository.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/providers/ica_compliance_provider.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/user_member.dart';
import 'package:fishbit_finance/modules/auth_tenant/domain/models/company.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import '../../helpers/test_auth_helper.dart';

class FakeIcaRepository implements IcaComplianceRepository {
  final List<IcaPersonalRecord> personalRecords;
  final List<IcaVehiculoRecord> vehiculoRecords;
  final List<IcaNecropsiaRecord> necropsiaRecords;
  final bool shouldFail;

  FakeIcaRepository({
    this.personalRecords = const [],
    this.vehiculoRecords = const [],
    this.necropsiaRecords = const [],
    this.shouldFail = false,
  });

  @override
  Future<List<IcaPersonalRecord>> getPersonalRecords({required String empresaId, required String unidadId}) async {
    if (shouldFail) throw Exception('ICA Personal DB Timeout');
    return personalRecords;
  }

  @override
  Future<List<IcaVehiculoRecord>> getVehiculoRecords({required String empresaId, required String unidadId}) async {
    if (shouldFail) throw Exception('ICA Vehiculos DB Timeout');
    return vehiculoRecords;
  }

  @override
  Future<List<IcaNecropsiaRecord>> getNecropsiaRecords({required String empresaId, required String unidadId}) async {
    if (shouldFail) throw Exception('ICA Necropsias DB Timeout');
    return necropsiaRecords;
  }

  @override
  Future<bool> savePersonalRecord(IcaPersonalRecord record) async {
    if (shouldFail) return false;
    return true;
  }

  @override
  Future<bool> saveVehiculoRecord(IcaVehiculoRecord record) async => !shouldFail;

  @override
  Future<bool> saveNecropsiaRecord(IcaNecropsiaRecord record) async => !shouldFail;
}

void main() {
  group('ICA Personal Biosecurity Record Tests', () {
    test('TipoPersonaIca string conversion parses correctly', () {
      expect(TipoPersonaIcaExt.fromString('OPERARIO'), TipoPersonaIca.operarioGranja);
      expect(TipoPersonaIcaExt.fromString('MEDICO VETERINARIO'), TipoPersonaIca.medicoVeterinario);
      expect(TipoPersonaIcaExt.fromString('AUDITOR ICA'), TipoPersonaIca.auditorIca);
      expect(TipoPersonaIcaExt.fromString('PROVEEDOR'), TipoPersonaIca.proveedorInsumos);
      expect(TipoPersonaIcaExt.fromString('TRANSPORTADOR'), TipoPersonaIca.transportador);
      expect(TipoPersonaIcaExt.fromString('VISITANTE TECNICO'), TipoPersonaIca.visitanteTecnico);
    });

    test('Serializes to JSON and deserializes maintaining biosecurity checklist flags', () {
      final record = IcaPersonalRecord(
        id: 'ica-per-01',
        empresaId: 'emp-ica-1',
        unidadAcuicolaId: 'unit-ica-1',
        fecha: DateTime(2026, 8, 25),
        horaIngreso: '07:30',
        horaSalida: '16:00',
        nombreCompleto: 'Andrés Bioseguridad',
        documentoIdentidad: '80123456',
        telefono: '3109876543',
        tipoPersona: TipoPersonaIca.medicoVeterinario,
        entidadProcedencia: 'Consultoría Acuícola del Huila',
        motivoVisita: 'Auditoría Sanitaria BAP/ICA',
        haVisitadoOtrasGranjas: true,
        detalleOtrasGranjas: 'Finca La Esperanza (hace 7 días)',
        presentaSintomas: false,
        lavadoManos: true,
        desinfeccionCalzado: true,
        indumentariaLimpia: true,
        autorizaIngreso: 'Director Sanitario',
        createdAt: DateTime(2026, 8, 25, 7, 30),
      );

      final json = record.toJson();
      expect(json['id'], 'ica-per-01');
      expect(json['tipo_persona'], 'MÉDICO VETERINARIO / TÉCNICO');
      expect(json['ha_visitado_otras_granjas'], true);
      expect(json['lavado_manos'], true);
      expect(json['desinfeccion_calzado'], true);

      final parsed = IcaPersonalRecord.fromJson(json);
      expect(parsed.id, 'ica-per-01');
      expect(parsed.tipoPersona, TipoPersonaIca.medicoVeterinario);
      expect(parsed.haVisitadoOtrasGranjas, isTrue);
      expect(parsed.lavadoManos, isTrue);
      expect(parsed.desinfeccionCalzado, isTrue);
      expect(parsed.indumentariaLimpia, isTrue);
    });
  });

  group('ICA Vehiculo Record Tests', () {
    test('TipoVehiculoIca identifies truck and tanker types properly', () {
      expect(TipoVehiculoIcaExt.fromString('CAMIÓN ALIMENTO'), TipoVehiculoIca.camionAlimento);
      expect(TipoVehiculoIcaExt.fromString('TRANSPORTE ALEVINOS'), TipoVehiculoIca.transporteAlevinos);
      expect(TipoVehiculoIcaExt.fromString('CAMION TERMO COSECHA'), TipoVehiculoIca.camionCosecha);
      expect(TipoVehiculoIcaExt.fromString('INSUMOS'), TipoVehiculoIca.insumosCombustible);
    });

    test('Serializes vehicle entry record with rodiluvio and disinfection contact time', () {
      final vehiculo = IcaVehiculoRecord(
        id: 'veh-01',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        fecha: DateTime(2026, 8, 26),
        horaIngreso: '09:15',
        placa: 'ABC123D',
        tipoVehiculo: TipoVehiculoIca.camionAlimento,
        conductor: 'Pedro Camionero',
        documentoConductor: '79888999',
        empresaTransportadora: 'Transportes Acuícolas SAS',
        procedencia: 'Itagüí Planta Concentrados',
        desinfeccionRodiluvio: true,
        desinfeccionArcoAspersion: true,
        desinfectanteUtilizado: 'Glutaraldehído 20% + Amonio Cuaternario',
        concentracionPpm: '250 ppm',
        tiempoContactoMinutos: 10,
        responsableDesinfeccion: 'Operario Puerta 1',
      );

      final json = vehiculo.toJson();
      expect(json['placa'], 'ABC123D');
      expect(json['tiempo_contacto_minutos'], 10);
      expect(json['desinfeccion_rodiluvio'], true);

      final parsed = IcaVehiculoRecord.fromJson(json);
      expect(parsed.placa, 'ABC123D');
      expect(parsed.tipoVehiculo, TipoVehiculoIca.camionAlimento);
      expect(parsed.tiempoContactoMinutos, 10);
    });
  });

  group('ICA Necropsia Record Tests', () {
    test('Correctly captures internal and external pathology signology', () {
      final necro = IcaNecropsiaRecord(
        id: 'nec-01',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'unit-1',
        estanqueNombre: 'Estanque 3',
        loteCodigo: 'L-2026-T3',
        fecha: DateTime(2026, 8, 27),
        especie: 'Tilapia Roja',
        numeroEjemplares: 5,
        pesoPromedioGramos: 450.0,
        tallaPromedioCm: 28.5,
        hallazgosPielAletas: 'Hemorragias petequiales en base de aletas',
        hallazgosOjos: 'Ligera exoftalmia unilateral',
        hallazgosBranquias: 'Palidez branquial moderada',
        presenciaEctoparasitos: false,
        hallazgosHigado: 'Hepatomegalia y coloración amarillenta friable',
        hallazgosBazo: 'Esplenomegalia grado II',
        hallazgosCavidadCelomica: 'Líquido ascítico serosanguinolento',
        diagnosticoPresuntivo: 'Sospecha de Streptococcus agalactiae',
        envioMuestrasLaboratorio: true,
        tipoMuestraEnviada: 'Hisopado de bazo y cerebro en medio Stuart',
        conductaTratamiento: 'Aislamiento de estanque, oxigenación continua y dieta medicada aprobada ICA',
        profesionalResponsable: 'Dra. Sandra Mora M.V.Z.',
        tarjetaProfesional: '12345-COMVEZCOL',
      );

      final json = necro.toJson();
      expect(json['numero_ejemplares'], 5);
      expect(json['diagnostico_presuntivo'], contains('Streptococcus'));
      expect(json['envio_muestras_laboratorio'], true);

      final parsed = IcaNecropsiaRecord.fromJson(json);
      expect(parsed.numeroEjemplares, 5);
      expect(parsed.diagnosticoPresuntivo, contains('Streptococcus'));
      expect(parsed.envioMuestrasLaboratorio, isTrue);
      expect(parsed.tarjetaProfesional, '12345-COMVEZCOL');
    });
  });

  group('IcaComplianceNotifier State Integration Tests', () {
    test('loadAllRecords aggregates all 3 registries cleanly via Future.wait parallelization', () async {
      final pRec = IcaPersonalRecord(
        empresaId: 'emp-test',
        unidadAcuicolaId: 'unit-test',
        fecha: DateTime.now(),
        horaIngreso: '08:00',
        nombreCompleto: 'Juan Test',
        documentoIdentidad: '123',
        tipoPersona: TipoPersonaIca.operarioGranja,
        motivoVisita: 'Trabajo diario',
      );

      final vRec = IcaVehiculoRecord(
        empresaId: 'emp-test',
        unidadAcuicolaId: 'unit-test',
        fecha: DateTime.now(),
        horaIngreso: '08:30',
        placa: 'XYZ987',
        tipoVehiculo: TipoVehiculoIca.insumosCombustible,
        conductor: 'Carlos Conductor',
        procedencia: 'Ciudad',
      );

      final nRec = IcaNecropsiaRecord(
        empresaId: 'emp-test',
        unidadAcuicolaId: 'unit-test',
        fecha: DateTime.now(),
        especie: 'Tilapia',
        diagnosticoPresuntivo: 'Sin hallazgos',
        conductaTratamiento: 'Seguimiento',
        profesionalResponsable: 'MVZ Pedro',
      );

      final repo = FakeIcaRepository(
        personalRecords: [pRec],
        vehiculoRecords: [vRec],
        necropsiaRecords: [nRec],
      );

      final container = ProviderContainer(
        overrides: [
          icaComplianceRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u-1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp-test',
                unidadAcuicolaId: 'unit-test',
                creadoEn: DateTime.now(),
              ),
              currentCompany: const Company(
                id: 'emp-test',
                nombreComercial: 'Empresa Test',
                razonSocial: 'Empresa Test SAS',
                nit: '900000000-1',
              ),
              activeUnitId: 'unit-test',
            ),
          )),
        ],
      );

      final notifier = container.read(icaComplianceProvider.notifier);
      await notifier.loadAllRecords();

      final state = container.read(icaComplianceProvider);
      expect(state.isLoading, isFalse);
      expect(state.personalRecords.length, 1);
      expect(state.vehiculoRecords.length, 1);
      expect(state.necropsiaRecords.length, 1);
    });

    test('Handles repository failure gracefully setting errorMessage', () async {
      final repo = FakeIcaRepository(shouldFail: true);
      final container = ProviderContainer(
        overrides: [
          icaComplianceRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith((ref) => AuthNotifierMock(
            AuthState(
              currentUser: UserMember(
                id: 'u-1',
                email: 'test@fishbit.com',
                nombre: 'Tester',
                role: UserRole.admin,
                empresaId: 'emp-err',
                unidadAcuicolaId: 'unit-err',
                creadoEn: DateTime.now(),
              ),
              currentCompany: const Company(
                id: 'emp-err',
                nombreComercial: 'Empresa Error',
                razonSocial: 'Empresa Error SAS',
                nit: '900000000-2',
              ),
              activeUnitId: 'unit-err',
            ),
          )),
        ],
      );

      final notifier = container.read(icaComplianceProvider.notifier);
      await notifier.loadAllRecords();

      final state = container.read(icaComplianceProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });
}
