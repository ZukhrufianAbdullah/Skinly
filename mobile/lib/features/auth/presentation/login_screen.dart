import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_text_field.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../../../core/router/app_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool isValid = true;

    if (email.isEmpty) {
      _emailError = 'Email wajib diisi.';
      isValid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Format email tidak valid.';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Password wajib diisi.';
      isValid = false;
    } else if (password.length < 8) {
      _passwordError = 'Password minimal 8 karakter.';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Maskot Skinly
                const SkinlyMascot(
                  width: 110,
                  height: 110,
                  animated: true,
                ),
                const SizedBox(height: 16),

                // Judul
                Text(
                  'Masuk ke Skinly',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.textTealDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Deteksi dan pantau kesehatan kulit wajahmu',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Kartu Form Login
                SkinlyCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pesan error dari server (jika ada)
                      if (authState.errorMessage != null) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Field Email
                      SkinlyTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'nama@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: _emailError,
                        onChanged: (_) {
                          if (_emailError != null) setState(() => _emailError = null);
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: 18),

                      // Field Password
                      SkinlyTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Minimal 8 karakter',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        errorText: _passwordError,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: 28),

                      // Tombol Masuk
                      SkinlyButton(
                        text: 'Masuk Sekarang',
                        isLoading: authState.isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tautan ke Registrasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authControllerProvider.notifier).clearError();
                        context.push(AppRoutes.register);
                      },
                      child: Text(
                        'Daftar di sini',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
