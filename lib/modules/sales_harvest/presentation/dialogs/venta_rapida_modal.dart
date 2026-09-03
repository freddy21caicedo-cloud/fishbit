import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_form_field.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/design_system/glass_date_picker.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/providers/ponds_provider.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';
import 'package:fishbit_finance/modules/sales_harvest/presentation/providers/sales_provider.dart';

class VentaRapidaModal extends ConsumerStatefulWidget {
  final FishBatch? initialBatch;

  const VentaRapidaModal({super.key, this.initialBatch});

  static Future<void> show(BuildContext context, {FishBatch? batch}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VentaRapidaModal(initialBatch: batch),
    );
  }

  @override
  ConsumerState<VentaRapidaModal> createState() => _VentaRapidaModalState();
}

class _VentaRapidaModalState extends ConsumerState<VentaRapidaModal> {
  final _formKey = GlobalKey<FormState>();
  final _clienteNombreCtrl = TextEditingController(text: 'Distribuidora del Mar S.A.S.');
  final _kgCtrl = TextEditingController(text: '500.0');
  final _precioKgCtrl = TextEditingController(text: '9200');
  CivilDate _fechaVenta = CivilDate.today();

  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    _selectedBatchId = widget.initialBatch?.id;
  }

  @override
  void dispose() {
    _clienteNombreCtrl.dispose();
    _kgCtrl.dispose();
    _precioKgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pondsState = ref.watch(pondsProvider);
    final salesState = ref.watch(salesProvider);
    final activeBatches = pondsState.batches.where((b) => b.estado == BatchStatus.active).toList();

    if (_selectedBatchId == null && activeBatches.isNotEmpty) {
      _selectedBatchId = activeBatches.first.id;
    }

    final selectedBatch = activeBatches.where((b) => b.id == _selectedBatchId).firstOrNull;
    final pond = pondsState.ponds.where((p) => p.id == selectedBatch?.estanqueId).firstOrNull;

    final kg = double.tryParse(_kgCtrl.text) ?? 500.0;
    final precioKg = double.tryParse(_precioKgCtrl.text) ?? 9200.0;
    final ingresoBruto = kg * precioKg;

    final cpk = selectedBatch?.cpk ?? 4500.0;
    final cogs = kg * cpk;
    final utilidadNeta = ingresoBruto - cogs;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          blur: 24,
          opacity: 0.14,
          borderColor: Colors.white.withValues(alpha: 0.18),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('💰 Venta Rápida de Biomasa', style: AppTypography.titleLarge.copyWith(color: AppColors.greenBiomass)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('LOTE A COSECHAR / VENDER', style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBatchId,
                        dropdownColor: AppColors.surfaceDark,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greenBiomass),
                        items: activeBatches.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text(
                              '${b.codigoLote} (${b.especie}) - Stock: ${b.biomasaActualKg.toInt()} kg',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedBatchId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  GlassFormField(
                    label: 'CLIENTE COMPRADOR',
                    controller: _clienteNombreCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: GlassFormField(
                          label: 'BIOMASA VENDIDA (kg)',
                          controller: _kgCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.scale_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassFormField(
                          label: 'PRECIO / KG (\$ COP)',
                          controller: _precioKgCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.monetization_on_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GlassDatePickerField(
                    label: 'FECHA DE COSECHA / VENTA',
                    accentColor: AppColors.greenBiomass,
                    initialDate: _fechaVenta,
                    onDateChanged: (d) => setState(() => _fechaVenta = d),
                  ),
                  const SizedBox(height: 16),

                  // Liquidación en Vivo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ingreso Bruto:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                            Text(CurrencyFormatters.formatCOP(ingresoBruto), style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Costo Producción (COGS):', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                            Text('- ${CurrencyFormatters.formatCOP(cogs)}', style: AppTypography.bodyMedium.copyWith(color: AppColors.coralAction, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('UTILIDAD NETA:', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                            Text(
                              CurrencyFormatters.formatCOP(utilidadNeta),
                              style: AppTypography.titleMedium.copyWith(color: AppColors.greenBiomass, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GlassButton(
                    label: 'Registrar Cosecha y Venta',
                    isLoading: salesState.isLoading,
                    backgroundColor: AppColors.greenBiomass,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate() || selectedBatch == null) return;

                      final authState = ref.read(authProvider);
                      final empresaId = authState.currentUser?.empresaId ?? 'c1000000-0000-0000-0000-000000000001';
                      final unidadId = authState.activeUnitId ?? 'u1000000-0000-0000-0000-000000000001';

                      final sale = BatchSale(
                        id: const Uuid().v4(),
                        empresaId: empresaId,
                        unidadAcuicolaId: unidadId,
                        loteId: selectedBatch.id,
                        codigoLote: selectedBatch.codigoLote,
                        estanqueNombre: pond?.nombre ?? 'Estanque',
                        clienteId: null,
                        clienteNombre: _clienteNombreCtrl.text.trim(),
                        especie: selectedBatch.especie,
                        biomasaVendidaKg: kg,
                        precioUnitarioKg: precioKg,
                        ingresoBruto: ingresoBruto,
                        cogs: cogs,
                        utilidadNeta: utilidadNeta,
                        estadoPago: 'Pagado',
                        creadoEn: _fechaVenta.toDateTime(),
                      );

                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      final success = await ref.read(salesProvider.notifier).recordSale(sale);
                      if (success && mounted) {
                        await ref.read(pondsProvider.notifier).loadPondsAndBatches();
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('¡Venta de ${CurrencyFormatters.formatKg(kg)} registrada con éxito!'),
                            backgroundColor: AppColors.greenBiomass,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
