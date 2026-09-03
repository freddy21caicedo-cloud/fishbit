import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';
import 'package:fishbit_finance/core/design_system/app_typography.dart';
import 'package:fishbit_finance/core/design_system/glass_container.dart';
import 'package:fishbit_finance/core/design_system/glass_card.dart';
import 'package:fishbit_finance/core/design_system/glass_badge.dart';
import 'package:fishbit_finance/core/utils/currency_formatters.dart';
import 'package:fishbit_finance/modules/auth_tenant/presentation/providers/auth_provider.dart';

class SaasConsoleScreen extends ConsumerStatefulWidget {
  const SaasConsoleScreen({super.key});

  @override
  ConsumerState<SaasConsoleScreen> createState() => _SaasConsoleScreenState();
}

class _SaasConsoleScreenState extends ConsumerState<SaasConsoleScreen> {
  // Estado local para toggle de estado de licencias de las empresas cliente
  final Map<String, bool> _companyStatus = {
    '3500cc63-5477-4f83-b4a3-7758b7cd6509': true, // Los Compadres
    '54dedaac-9099-475a-8bfc-635ef8494c2a': true, // Aquarium II
  };

  @override
  Widget build(BuildContext context) {
    final totalActiveCompanies = _companyStatus.values.where((v) => v).length;
    final totalSuspendedCompanies = _companyStatus.values.where((v) => !v).length;
    final totalMRR = totalActiveCompanies * 400000.0;
    final totalARR = totalMRR * 12.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar Ejecutiva
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.amberWarning.withValues(alpha: 0.18),
                            border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.stars_rounded, color: AppColors.amberWarning, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consola SaaS Executive',
                              style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'especialistaacuicola@gmail.com • Control de Facturación',
                              style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppColors.coralAction, size: 22),
                      tooltip: 'Cerrar Sesión',
                      onPressed: () => ref.read(authProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
            ),

            // Contenido Principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bento Grid: Métricas Clave SaaS
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 580;
                        final itemWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildBentoMetric(
                              width: itemWidth,
                              title: 'ARR PROYECTADO (ANUAL)',
                              value: CurrencyFormatters.formatCOP(totalARR),
                              subtitle: '$totalActiveCompanies Sedes Licenciadas',
                              icon: Icons.payments_rounded,
                              accentColor: AppColors.greenBiomass,
                              growth: '+25% YoY',
                            ),
                            _buildBentoMetric(
                              width: itemWidth,
                              title: 'MRR RECURRENTE (MENSUAL)',
                              value: CurrencyFormatters.formatCOP(totalMRR),
                              subtitle: 'Canon Base \$400K COP / Sede',
                              icon: Icons.trending_up_rounded,
                              accentColor: AppColors.cyanWater,
                              growth: '+12.5% MoM',
                            ),
                            _buildBentoMetric(
                              width: itemWidth,
                              title: 'ESTADO DE CUENTAS',
                              value: '$totalActiveCompanies Activas / $totalSuspendedCompanies Bloq',
                              subtitle: 'Cartera 100% al día',
                              icon: Icons.domain_verification_rounded,
                              accentColor: AppColors.amberWarning,
                              growth: '0% Churn',
                            ),
                            _buildBentoMetric(
                              width: itemWidth,
                              title: 'LTV ESTIMADO / CLIENTE',
                              value: CurrencyFormatters.formatCOP(9600000),
                              subtitle: '24 meses retención media',
                              icon: Icons.handshake_rounded,
                              accentColor: Colors.purpleAccent,
                              growth: '3.2x LTV:CAC',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Gráfica Interactiva: Crecimiento de Recaudo SaaS
                    GlassCard(
                      title: 'CURVA DE RECAUDO RECURRENTE Y PROYECCIÓN (2026)',
                      glowColor: AppColors.cyanWater,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 180,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 42,
                                      getTitlesWidget: (val, meta) {
                                        if (val == 0) return const SizedBox.shrink();
                                        return Text(
                                          '${(val / 1000000).toStringAsFixed(1)}M',
                                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (val, meta) {
                                        const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
                                        final idx = val.toInt();
                                        if (idx >= 0 && idx < months.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              months[idx],
                                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10.5),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 7,
                                minY: 0,
                                maxY: 3500000,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 400000),
                                      FlSpot(1, 800000),
                                      FlSpot(2, 1200000),
                                      FlSpot(3, 1600000),
                                      FlSpot(4, 2000000),
                                      FlSpot(5, 2400000),
                                      FlSpot(6, 2800000),
                                      FlSpot(7, 3200000),
                                    ],
                                    isCurved: true,
                                    color: AppColors.cyanWater,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.cyanWater.withValues(alpha: 0.35),
                                          AppColors.cyanWater.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Directorio de Clientes & Control de Cobranza
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PISCÍCOLAS SUSCRITAS Y CONTROL DE ACCESO',
                          style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark, letterSpacing: 1.2),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.greenBiomass.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalActiveCompanies Activas',
                            style: const TextStyle(color: AppColors.greenBiomass, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cliente 1: Los Compadres
                    _buildCompanyControlCard(
                      companyId: '3500cc63-5477-4f83-b4a3-7758b7cd6509',
                      name: 'Piscícola Los Compadres',
                      nit: '901.530.907-1',
                      adminEmail: 'piscicolaloscompadres@gmail.com',
                      planPrice: '400.000 COP / año',
                      renewalDate: '15 Dic 2026',
                    ),

                    const SizedBox(height: 12),

                    // Cliente 2: Aquarium II
                    _buildCompanyControlCard(
                      companyId: '54dedaac-9099-475a-8bfc-635ef8494c2a',
                      name: 'Aquarium II',
                      nit: '109.215.401-2',
                      adminEmail: 'joyolgutierrojas83@gmail.com',
                      planPrice: '400.000 COP / año',
                      renewalDate: '20 Ene 2027',
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoMetric({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String growth,
  }) {
    return SizedBox(
      width: width,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        blur: 16,
        opacity: 0.10,
        borderColor: Colors.white.withValues(alpha: 0.10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: accentColor, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.displayMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: AppTypography.labelMicro.copyWith(color: AppColors.textSecondaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    growth,
                    style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyControlCard({
    required String companyId,
    required String name,
    required String nit,
    required String adminEmail,
    required String planPrice,
    required String renewalDate,
  }) {
    final isEnabled = _companyStatus[companyId] ?? true;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      blur: 16,
      opacity: 0.08,
      borderColor: isEnabled ? Colors.white.withValues(alpha: 0.12) : AppColors.coralAction.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIT: $nit • Admin: $adminEmail',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                activeThumbColor: AppColors.greenBiomass,
                activeTrackColor: AppColors.greenBiomass.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.coralAction,
                inactiveTrackColor: AppColors.coralAction.withValues(alpha: 0.3),
                onChanged: (val) {
                  setState(() => _companyStatus[companyId] = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        val ? 'Licencia de $name HABILITADA' : 'Licencia de $name SUSPENDIDA por cobro',
                      ),
                      backgroundColor: val ? AppColors.greenBiomass : AppColors.coralAction,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondaryDark),
                  const SizedBox(width: 4),
                  Text('Vence: $renewalDate', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                ],
              ),
              Row(
                children: [
                  GlassBadge(
                    text: isEnabled ? 'Al día' : 'En Mora',
                    color: isEnabled ? AppColors.greenBiomass : AppColors.coralAction,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    planPrice,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.cyanWater, fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

