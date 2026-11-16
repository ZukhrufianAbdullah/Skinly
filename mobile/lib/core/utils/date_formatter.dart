// lib/core/utils/date_formatter.dart
// Helper format tanggal dalam Bahasa Indonesia
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await initializeDateFormatting('id_ID', null);
      await initializeDateFormatting('id', null);
      _initialized = true;
    } catch (_) {}
  }

  static String formatFull(DateTime dt) {
    final local = dt.toLocal();
    try {
      return DateFormat('d MMMM yyyy, HH:mm', 'id').format(local);
    } catch (_) {
      try {
        return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(local);
      } catch (_) {
        return _formatFallback(local, withTime: true);
      }
    }
  }

  static String formatShort(DateTime dt) {
    final local = dt.toLocal();
    try {
      return DateFormat('d MMM yyyy', 'id').format(local);
    } catch (_) {
      try {
        return DateFormat('d MMM yyyy', 'id_ID').format(local);
      } catch (_) {
        return _formatFallback(local, withTime: false);
      }
    }
  }

  static String _formatFallback(DateTime dt, {bool withTime = false}) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = dt.day;
    final month = months[dt.month - 1];
    final year = dt.year;
    if (withTime) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    }
    return '$day $month $year';
  }

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.isNegative || diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatShort(dt);
  }
}
