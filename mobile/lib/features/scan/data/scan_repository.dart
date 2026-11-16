// lib/features/scan/data/scan_repository.dart
// Repositori untuk API scan (analyze & save)
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/network/api_client.dart';
import '../domain/scan_result.dart';
import '../../history/domain/scan_history.dart';

class ScanRepository {
  final Dio _dio = ApiClient.dio;

  /// Kirim foto ke backend untuk dianalisis (POST /scans/analyze).
  ///
  /// Menerima bytes (bukan `File`) agar kompatibel di Android maupun web.
  Future<ScanResult> analyze(
    Uint8List originalBytes, {
    String filename = 'upload.jpg',
  }) async {
    // Kompres gambar sebelum upload (sisi terpanjang maks 1280px).
    // Jika kompresi tidak tersedia di platform tertentu, pakai bytes asli.
    Uint8List bytes = originalBytes;
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: 85,
      );
      if (compressed.isNotEmpty) bytes = compressed;
    } catch (_) {
      bytes = originalBytes;
    }

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename.isEmpty ? 'upload.jpg' : filename,
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
