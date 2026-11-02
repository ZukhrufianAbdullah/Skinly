import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  Future<({User user, String token})> register({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/v1/auth/register',
      data: {
        'username': username.trim().toLowerCase(),
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    return (user: user, token: token);
  }

  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    return (user: user, token: token);
  }

  Future<User> getMe() async {
    final response = await _dio.get('/api/v1/auth/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
