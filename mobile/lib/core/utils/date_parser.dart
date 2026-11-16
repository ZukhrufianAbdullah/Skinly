// lib/core/utils/date_parser.dart
// Helper membaca timestamp dari backend.
//
// Backend (Skinly) menyimpan dan mengirim waktu dalam UTC. Sebagian respons
// lama mengirim string tanpa penanda zona waktu (mis. "2026-11-16T05:12:00").
// DateTime.parse() membaca string seperti itu sebagai waktu LOKAL perangkat,
// sehingga tampilan "x jam lalu" bisa meleset (contoh: langsung "7 jam lalu"
// untuk scan yang baru dibuat di WIB). Helper ini memaksa string tanpa zona
// waktu dibaca sebagai UTC.
import 'package:flutter/foundation.dart';

final RegExp _zoneSuffix = RegExp(r'(z|[+-]\d{2}:?\d{2})$');

DateTime parseServerDate(String value) {
  final trimmed = value.trim();
  final parsed = DateTime.parse(trimmed);
  final hasZone = parsed.isUtc || _zoneSuffix.hasMatch(trimmed.toLowerCase());
  if (hasZone) return parsed;

  // String tanpa zona waktu: perlakukan komponen waktunya sebagai UTC.
  if (kDebugMode) {
    debugPrint('parseServerDate: "$trimmed" tanpa zona waktu, dianggap UTC');
  }
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
