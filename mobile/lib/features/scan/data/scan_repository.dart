// lib/features/scan/data/scan_repository.dart
// Repositori untuk API scan (analyze & save)
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import '../../../core/network/api_client.dart';
import '../domain/scan_result.dart';
import '../../history/domain/scan_history.dart';

class ScanRepository {
  final Dio _dio = ApiClient.dio;

  /// Kirim foto ke backend untuk dianalisis (POST /scans/analyze)
  Future<ScanResult> analyze(File imageFile) async {
    // Kompres gambar sebelum upload (sisi terpanjang maks 1280px)
    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 1280,
      minHeight: 1280,
      quality: 85,
      keepExif: false,
    );

    final bytes = compressed ?? await imageFile.readAsBytes();
    final filename = p.basename(imageFile.path);

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
      ),
    });

    try {
      final response = await _dio.post('/api/v1/scans/analyze', data: formData);
      return ScanResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  /// Simpan hasil scan ke database (POST /scans)
  Future<ScanHistoryItem> saveResult(ScanResult result) async {
    try {
      final payload = {
        'skin_type': result.skinType,
        'confidence': result.confidence,
        'probabilities': result.probabilities,
      };
      final response = await _dio.post('/api/v1/scans', data: payload);
      return ScanHistoryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
