import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_api_service.dart';
import '../data/auth_storage.dart';
import '../domain/user.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    User? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthStorage storage;
  final AuthApiService apiService;

  AuthController({
    required this.storage,
    required this.apiService,
  }) : super(const AuthState()) {
    // Hubungkan ApiClient 401 callback ke logout
    ApiClient.initialize(storage, onTokenExpired: () {
      state = state.copyWith(clearUser: true);
    });
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await storage.initToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isInitialized: true, clearUser: true);
        return;
      }

      // Ambil user profil dari API
      final user = await apiService.getMe();
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        user: user,
        clearError: true,
      );
    } catch (_) {
      await storage.clearToken();
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        clearUser: true,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await apiService.login(email: email, password: password);
      await storage.saveToken(result.token);
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        clearError: true,
      );
      return true;
    } catch (e) {
      final errorMsg = ApiClient.extractErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await apiService.register(
        username: username,
        name: name,
        email: email,
        password: password,
      );
      await storage.saveToken(result.token);
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        clearError: true,
      );
      return true;
    } catch (e) {
      final errorMsg = ApiClient.extractErrorMessage(e);
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    await storage.clearToken();
    state = state.copyWith(clearUser: true, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final storage = ref.watch(authStorageProvider);
  final apiService = ref.watch(authApiServiceProvider);
  return AuthController(storage: storage, apiService: apiService);
});
