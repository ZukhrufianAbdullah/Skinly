// lib/core/utils/date_formatter.dart
// Helper format tanggal dalam Bahasa Indonesia
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatFull(DateTime dt) {
    return DateFormat('d MMMM yyyy, HH:mm', 'id').format(dt.toLocal());
  }

  static String formatShort(DateTime dt) {
    return DateFormat('d MMM yyyy', 'id').format(dt.toLocal());
  }

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatShort(dt);
  }
}
