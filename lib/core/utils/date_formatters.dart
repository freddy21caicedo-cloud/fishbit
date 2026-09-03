import 'package:intl/intl.dart';

/// Formateadores de fecha estándar
class DateFormatters {
  DateFormatters._();

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _friendlyDate = DateFormat('dd MMM yyyy', 'es');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatFriendly(DateTime date) => _friendlyDate.format(date);
  static String formatIso(DateTime date) => _isoDate.format(date);

  static DateTime parseIso(String isoString) {
    try {
      return DateTime.parse(isoString);
    } catch (_) {
      return DateTime.now();
    }
  }
}
