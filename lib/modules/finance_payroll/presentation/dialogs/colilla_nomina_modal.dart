import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_button.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/finance_payroll/domain/models/payroll_record.dart';

/// Modal / Diálogo visual para ver y exportar la Colilla de Pago del trabajador
class ColillaNominaModal extends StatelessWidget {
  final PayrollRecord record;
  final String? companyName;
  final String? companyNit;

  const ColillaNominaModal({
    super.key,
    required this.record,
    this.companyName,
    this.companyNit,
  });

  static Future<void> show(
    BuildContext context, {
    required PayrollRecord record,
    String? companyName,
    String? companyNit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ColillaNominaModal(
        record: record,
        companyName: companyName,
        companyNit: companyNit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDevengado = record.salarioBase + record.auxilioTransporte + record.recargosExtras;
    final deduccionSalud = record.salarioBase * 0.04;
    final deduccionPension = record.salarioBase * 0.04;
    final totalDeducciones = deduccionSalud + deduccionPension;
    final netoPagar = (totalDevengado - totalDeducciones).clamp(0.0, double.infinity);

    final fechaStr = '${record.fechaPago.day.toString().padLeft(2, '0')}/${record.fechaPago.month.toString().padLeft(2, '0')}/${record.fechaPago.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          blur: 24,
          opacity: 0.16,
          borderColor: AppColors.purpleAnalytics.withValues(alpha: 0.35),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.purpleAnalytics.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColors.purpleAnalytics, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COMPROBANTE DE PAGO', style: AppTypography.labelMicro.copyWith(color: AppColors.purpleAnalytics, letterSpacing: 1.2)),
                            Text('Colilla de Liquidación', style: AppTypography.titleOf(context, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Datos Empresa y Colaborador
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.glassBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('EMPRESA:', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          Text(companyName ?? 'Piscícola Principal', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                      if (companyNit != null && companyNit!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NIT:', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            Text(companyNit!, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontSize: 11)),
                          ],
                        ),
                      ],
                      const Divider(height: 12, color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('COLABORADOR:', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          Text(record.empleadoNombre, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w800, fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PERIODO Y FECHA:', style: AppTypography.labelMicro.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          Text('${record.periodo.toUpperCase()} • $fechaStr', style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w700, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Devengados
                Text('1. CONCEPTOS DEVENGADOS', style: AppTypography.labelMicro.copyWith(color: AppColors.cyanWater, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                _buildRow('Sueldo Básico (${record.periodo}):', record.salarioBase, isDark),
                if (record.auxilioTransporte > 0)
                  _buildRow('Auxilio de Transporte:', record.auxilioTransporte, isDark),
                if (record.recargosExtras > 0)
                  _buildRow('Horas Extras / Recargos:', record.recargosExtras, isDark),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL DEVENGADO:', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(CurrencyFormatters.formatCOP(totalDevengado), style: const TextStyle(color: AppColors.cyanWater, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 12),

                // Deducciones
                Text('2. DEDUCCIONES AL TRABAJADOR', style: AppTypography.labelMicro.copyWith(color: AppColors.coralAction, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                _buildRow('Aporte Salud Empleado (4%):', -deduccionSalud, isDark, isDeduction: true),
                _buildRow('Aporte Pensión Empleado (4%):', -deduccionPension, isDark, isDeduction: true),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL DEDUCCIONES:', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 12)),
                    Text('-${CurrencyFormatters.formatCOP(totalDeducciones)}', style: const TextStyle(color: AppColors.coralAction, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 14),

                // Resumen Neto
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.greenBiomass.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.greenBiomass.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NETO A TRANSFERIR', style: AppTypography.labelMicro.copyWith(color: AppColors.greenBiomass)),
                          const Text('Efectivo / Transferencia', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10)),
                        ],
                      ),
                      Text(
                        CurrencyFormatters.formatCOP(netoPagar),
                        style: const TextStyle(color: AppColors.greenBiomass, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Botón Copiar para WhatsApp
                GlassButton(
                  label: '📲 Copiar Resumen para WhatsApp',
                  backgroundColor: AppColors.greenBiomass,
                  onPressed: () {
                    final summary = '''
📄 *COMPROBANTE DE PAGO DE NÓMINA*
🏢 ${companyName ?? 'Piscícola FishBit'}
👤 *Colaborador:* ${record.empleadoNombre}
📅 *Periodo:* ${record.periodo} ($fechaStr)

➕ *Devengado:*
• Salario Base: ${CurrencyFormatters.formatCOP(record.salarioBase)}
• Auxilio Transporte: ${CurrencyFormatters.formatCOP(record.auxilioTransporte)}
• Total Devengado: ${CurrencyFormatters.formatCOP(totalDevengado)}

➖ *Deducciones Empleado (8%):*
• Salud (4%): -${CurrencyFormatters.formatCOP(deduccionSalud)}
• Pensión (4%): -${CurrencyFormatters.formatCOP(deduccionPension)}
• Total Deducciones: -${CurrencyFormatters.formatCOP(totalDeducciones)}

💵 *NETO A TRANSFERIR: ${CurrencyFormatters.formatCOP(netoPagar)}*
_Generado por FishBit Finance_
''';
                    Clipboard.setData(ClipboardData(text: summary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Resumen de nómina copiado al portapapeles!'),
                        backgroundColor: AppColors.greenBiomass,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, double value, bool isDark, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11.5)),
          Text(
            (isDeduction && value < 0) ? '-${CurrencyFormatters.formatCOP(value.abs())}' : CurrencyFormatters.formatCOP(value),
            style: TextStyle(
              color: isDeduction ? AppColors.coralAction : (isDark ? Colors.white : AppColors.textPrimaryLight),
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
