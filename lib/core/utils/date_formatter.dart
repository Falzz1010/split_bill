import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      // Fallback for default locale if id_ID locale data is not loaded yet
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}
