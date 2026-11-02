import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/scan/presentation/scan_example_screen.dart';
import '../../features/result/presentation/result_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/history/presentation/history_detail_screen.dart';
import '../../features/knowledge/presentation/knowledge_screen.dart';
import '../../features/knowledge/presentation/article_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../widgets/main_scaffold.dart';
import 'page_transitions.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanExample = '/scan/example';
  static const String result = '/result';
  static const String history = '/history';
  static const String historyDetail = '/history/:id';
  static const String knowledge = '/knowledge';
  static const String articleDetail = '/knowledge/:id';
  static const String profile = '/profile';
  static const String feedback = '/feedback';
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => buildPageTransition(
              context: context,
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.history,
            pageBuilder: (context, state) => buildPageTransition(
              context: context,
              state: state,
              child: const HistoryScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: HistoryDetailScreen(scanId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.knowledge,
            pageBuilder: (context, state) => buildPageTransition(
              context: context,
              state: state,
              child: const KnowledgeScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => buildPageTransition(
                  context: context,
                  state: state,
                  child: ArticleDetailScreen(articleId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => buildPageTransition(
              context: context,
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.scan,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const ScanScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.scanExample,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const ScanExampleScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.result,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return buildPageTransition(
            context: context,
            state: state,
            child: ResultScreen(analysisData: extra ?? {}),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.feedback,
        pageBuilder: (context, state) => buildPageTransition(
          context: context,
          state: state,
          child: const FeedbackScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.uri.path}'),
      ),
    ),
  );
}
