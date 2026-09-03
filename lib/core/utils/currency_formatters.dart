import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formateadores de moneda y cantidades acuícolas
class CurrencyFormatters {
  CurrencyFormatters._();

  static final NumberFormat _copFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _kgFormat = NumberFormat('#,##0.0', 'es_CO');
  static final NumberFormat _intFormat = NumberFormat('#,##0', 'es_CO');

  /// Formatea un valor a pesos colombianos (ej. $ 8.500)
  static String formatCOP(num amount) {
    return _copFormat.format(amount);
  }

  /// Formatea kilogramos (ej. 1.250,5 kg)
  static String formatKg(num kg) {
    return '${_kgFormat.format(kg)} kg';
  }

  /// Formatea cantidades enteras (ej. 5.000 peces)
  static String formatInt(int count) {
    return _intFormat.format(count);
  }

  /// Formatea porcentaje (ej. 12,5%)
  static String formatPct(num pct) {
    return '${_kgFormat.format(pct)}%';
  }

  /// Extrae el valor numérico double de un texto formateado en pesos (ej. "$ 86.906" -> 86906.0)
  static double parseCOP(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digitsOnly) ?? 0.0;
  }
}

/// Formateador interactivo en tiempo real para TextFormFields que manejan dinero en COP
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'es_CO');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digitsOnly);
    final formatted = '\$ ${_formatter.format(number)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
