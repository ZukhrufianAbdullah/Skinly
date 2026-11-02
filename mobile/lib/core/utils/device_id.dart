// lib/core/utils/device_id.dart
// Kelola device_id anonim yang disimpan di SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _key = 'skinly_device_id';
  static String? _cachedId;

  /// Ambil atau buat device_id anonim unik untuk perangkat ini
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);

    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }

    _cachedId = id;
    return id;
  }
}
