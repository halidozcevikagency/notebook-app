/// Tarih biçimlendirme yardımcısı
import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date) {
    try {
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (date.year == now.year) return DateFormat('MMM d').format(date);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }

  static String fullFormat(DateTime date) {
    try {
      return DateFormat('MMMM d, yyyy · h:mm a').format(date);
    } catch (_) {
      return date.toString();
    }
  }
}
