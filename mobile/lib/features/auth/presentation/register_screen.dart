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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _usernameError;
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _usernameError = null;
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool isValid = true;

    if (username.isEmpty) {
      _usernameError = 'Username wajib diisi.';
      isValid = false;
    } else if (username.length < 4) {
      _usernameError = 'Username minimal 4 karakter.';
      isValid = false;
    } else if (username.contains(' ')) {
      _usernameError = 'Username tidak boleh mengandung spasi.';
      isValid = false;
    }

    if (name.isEmpty) {
      _nameError = 'Nama lengkap wajib diisi.';
      isValid = false;
    }

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

  Future<void> _handleRegister() async {
    if (!_validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
      username: _usernameController.text.trim().toLowerCase(),
      name: _nameController.text.trim(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Maskot
                const SkinlyMascot(
                  width: 90,
                  height: 90,
                  animated: true,
                ),
                const SizedBox(height: 12),

                // Judul
                Text(
                  'Buat Akun Baru',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.textTealDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mulai perjalanan merawat kulit sehatmu bersama Skinly',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Kartu Form Registrasi
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

                      // Field Username
                      SkinlyTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hintText: 'mis. aura_skin',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        errorText: _usernameError,
                        onChanged: (_) {
                          if (_usernameError != null) setState(() => _usernameError = null);
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field Nama Lengkap
                      SkinlyTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        hintText: 'mis. Aura Kasih',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        errorText: _nameError,
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Field Password
                      SkinlyTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Minimal 8 karakter',
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        errorText: _passwordError,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleRegister(),
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                          ref.read(authControllerProvider.notifier).clearError();
                        },
                      ),
                      const SizedBox(height: 26),

                      // Tombol Daftar
                      SkinlyButton(
                        text: 'Daftar Akun',
                        isLoading: authState.isLoading,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tautan kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(authControllerProvider.notifier).clearError();
                        context.pop();
                      },
                      child: Text(
                        'Masuk di sini',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
