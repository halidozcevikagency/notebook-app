/// Tarih biçimlendirme yardımcısı
/// intl bağımlılığı olmadan basit formatlama
class DateFormatter {
  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String format(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (date.year == now.year) return '${_months[date.month]} ${date.day}';
    return '${_months[date.month]} ${date.day}, ${date.year}';
  }

  static String fullFormat(DateTime date) {
    final h = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${_months[date.month]} ${date.day}, ${date.year} · $h:$m $ampm';
  }
}
