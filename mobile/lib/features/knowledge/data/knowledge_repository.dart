// lib/features/knowledge/data/knowledge_repository.dart
// Repositori untuk API artikel edukasi
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/article.dart';

class KnowledgeRepository {
  final Dio _dio = ApiClient.dio;

  /// Ambil daftar artikel (GET /articles)
  Future<ArticleList> getArticles({String? category}) async {
    try {
      final response = await _dio.get('/api/v1/articles',
          queryParameters: category != null ? {'category': category} : null);
      return ArticleList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  /// Ambil detail artikel (GET /articles/{id})
  Future<Article> getArticleDetail(String id) async {
    try {
      final response = await _dio.get('/api/v1/articles/$id');
      return Article.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
