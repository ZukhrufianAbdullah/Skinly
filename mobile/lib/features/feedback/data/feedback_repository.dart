// lib/features/feedback/data/feedback_repository.dart
// Repositori untuk API feedback pengguna
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class FeedbackRepository {
  final Dio _dio = ApiClient.dio;

  /// Kirim feedback (POST /feedback)
  Future<void> submitFeedback({required int rating, String? comment}) async {
    try {
      await _dio.post('/api/v1/feedback', data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
