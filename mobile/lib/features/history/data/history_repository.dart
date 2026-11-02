// lib/features/history/data/history_repository.dart
// Repositori untuk API riwayat scan
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/scan_history.dart';

class HistoryRepository {
  final Dio _dio = ApiClient.dio;

  /// Ambil daftar riwayat scan (GET /scans)
  Future<ScanHistoryList> getHistory({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get('/api/v1/scans', queryParameters: {
        'page': page,
        'page_size': pageSize,
      });
      return ScanHistoryList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  /// Ambil detail satu riwayat scan (GET /scans/{id})
  Future<ScanHistoryItem> getDetail(String id) async {
    try {
      final response = await _dio.get('/api/v1/scans/$id');
      return ScanHistoryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  /// Hapus riwayat scan (DELETE /scans/{id})
  Future<void> deleteScan(String id) async {
    try {
      await _dio.delete('/api/v1/scans/$id');
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
