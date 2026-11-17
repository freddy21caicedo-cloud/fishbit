import 'package:flutter/material.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/sales_harvest/domain/models/batch_sale.dart';

class ConfirmarVentaDialog extends StatelessWidget {
  final BatchSale sale;
  final VoidCallback onConfirm;
  final bool isLoading;

  const ConfirmarVentaDialog({
    super.key,
    required this.sale,
    required this.onConfirm,
    this.isLoading = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BatchSale sale,
    required VoidCallback onConfirm,
    bool isLoading = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isLoading,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => ConfirmarVentaDialog(
        sale: sale,
        onConfirm: onConfirm,
        isLoading: isLoading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: GlassContainer(
              borderRadius: 26,
              padding: const EdgeInsets.all(22),
              blur: 24,
              opacity: isDark ? 0.18 : 0.96,
              borderColor: AppColors.greenBiomass.withValues(alpha: 0.4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera Resumen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.greenBiomass.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: AppColors.greenBiomass,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirmar Venta y Cosecha',
                                style: AppTypography.titleMedium.copyWith(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Comprobante previo de despacho acuícola',
                                style: AppTypography.labelMicro.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isLoading)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta Recibo / Remisión
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comprador y Cédula
                        _RowDetail(
                          label: 'Comprador:',
                          value: sale.clienteNombre,
                          bold: true,
                        ),
                        if (sale.clienteCedulaNit != null && sale.clienteCedulaNit!.isNotEmpty)
                          _RowDetail(
                            label: 'Cédula / NIT:',
                            value: sale.clienteCedulaNit!,
                          ),
                        _RowDetail(
                          label: 'Fecha despacho:',
                          value: '${sale.creadoEn.day}/${sale.creadoEn.month}/${sale.creadoEn.year}',
                        ),
                        const Divider(color: Colors.white12, height: 18),

                        // Estanque, Lote y Especie
                        _RowDetail(
                          label: 'Estanque origen:',
                          value: sale.estanqueNombre,
                        ),
                        _RowDetail(
                          label: 'Lote / Especie:',
                          value: '${sale.codigoLote} (${sale.especie})',
                        ),
                        _RowDetail(
                          label: 'Presentación:',
                          value: sale.tipoVenta.label,
                          valueColor: AppColors.cyanWater,
                          bold: true,
                        ),
                        const Divider(color: Colors.white12, height: 18),

                        // Métricas de Merma y Biometría
                        if (sale.cantidadPeces > 0)
                          _RowDetail(
                            label: 'Cantidad peces:',
                            value: '${sale.cantidadPeces} unidades',
                          ),
                        _RowDetail(
                          label: 'Peso Vivo Cosechado:',
                          value: '${sale.pesoVivoKg.toStringAsFixed(1)} kg',
                          bold: true,
                        ),
                        if (sale.tipoVenta != SalePresentation.vivo) ...[
                          _RowDetail(
                            label: 'Merma de proceso:',
                            value: '- ${sale.mermaKg.toStringAsFixed(1)} kg (${sale.mermaPct.toStringAsFixed(1)}%)',
                            valueColor: AppColors.amberWarning,
                            bold: true,
                          ),
                          if (sale.mermaGPpe > 0)
                            _RowDetail(
                              label: 'Merma por pez:',
                              value: '~${sale.mermaGPpe.toStringAsFixed(0)} g/pez',
                            ),
                          _RowDetail(
                            label: 'Peso Arreglado Final:',
                            value: '${sale.pesoArregladoKg.toStringAsFixed(1)} kg',
                            valueColor: AppColors.greenBiomass,
                            bold: true,
                          ),
                        ],
                        const Divider(color: Colors.white12, height: 18),

                        // Liquidación Financiera
                        _RowDetail(
                          label: 'Precio por kilo pactado:',
                          value: '${CurrencyFormatters.formatCOP(sale.precioUnitarioKg)} (${sale.baseCobro == 'peso_vivo' ? 's/peso vivo' : 's/peso arreglado'})',
                        ),
                        _RowDetail(
                          label: 'Costo Lote (COGS est.):',
                          value: '- ${CurrencyFormatters.formatCOP(sale.cogs)}',
                          valueColor: AppColors.coralAction,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.greenBiomass.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL A FACTURAR:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                                  Text(
                                    CurrencyFormatters.formatCOP(sale.ingresoBruto),
                                    style: const TextStyle(color: AppColors.greenBiomass, fontSize: 17, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Utilidad Neta Proyectada:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                  Text(
                                    '${CurrencyFormatters.formatCOP(sale.utilidadNeta)} (${sale.margenNetoPct.toStringAsFixed(1)}% mg)',
                                    style: const TextStyle(color: AppColors.purpleAnalytics, fontSize: 11.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botones de Confirmación
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                          child: const Text('Corregir', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GlassButton(
                          label: 'Confirmar y Despachar',
                          backgroundColor: AppColors.greenBiomass,
                          isLoading: isLoading,
                          onPressed: onConfirm,
                        ),
                      ),
                    ],
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

class _RowDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _RowDetail({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
