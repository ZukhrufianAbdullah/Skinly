// test/widget_test.dart
// Unit & widget tests untuk aplikasi Skinly (Tokens, Widgets, Models, & Smoke test)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skinly/core/theme/app_colors.dart';
import 'package:skinly/core/widgets/skinly_button.dart';
import 'package:skinly/core/widgets/skinly_card.dart';
import 'package:skinly/core/widgets/skinly_text_field.dart';
import 'package:skinly/features/auth/domain/user.dart';
import 'package:skinly/features/auth/data/auth_storage.dart';
import 'package:skinly/features/scan/domain/scan_result.dart';
import 'package:skinly/core/utils/date_formatter.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Design Tokens Tests', () {
    test('AppColors skinTypeColor maps types correctly', () {
      expect(AppColors.skinTypeColor('normal'), AppColors.skinNormal);
      expect(AppColors.skinTypeColor('oily'), AppColors.skinOily);
      expect(AppColors.skinTypeColor('dry'), AppColors.skinDry);
      expect(AppColors.skinTypeColor('combination'), AppColors.skinCombination);
      expect(AppColors.skinTypeColor('unknown'), AppColors.primary);
    });

    test('AppColors palette values match Figma specs', () {
      expect(AppColors.primary, const Color(0xFF6CC9BF));
      expect(AppColors.primaryDark, const Color(0xFF327E76));
      expect(AppColors.accent, const Color(0xFFF26D9B));
      expect(AppColors.primaryBackground, const Color(0xFFE8F7F5));
    });
  });

  group('Model Serialization Tests', () {
    test('User model parses JSON correctly', () {
      final json = {
        'id': 1,
        'username': 'john_doe',
        'name': 'John Doe',
        'email': 'john@example.com',
        'created_at': '2026-10-19T10:00:00Z',
      };
      final user = User.fromJson(json);
      expect(user.id, '1');
      expect(user.username, 'john_doe');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.toJson()['username'], 'john_doe');
    });

    test('ScanResult parses response correctly', () {
      final json = {
        'id': 10,
        'image_url': '/static/uploads/face.jpg',
        'skin_type': 'oily',
        'confidence': 0.92,
        'probabilities': {
          'oily': 0.92,
          'combination': 0.05,
          'normal': 0.02,
          'dry': 0.01,
        },
        'recommendation': 'Gunakan pembersih wajah gel dan non-komedogenik.',
        'routine_morning': [
          {'step': 1, 'name': 'Gel Cleanser', 'desc': 'Bersihkan minyak berlebih'},
        ],
        'routine_night': [
          {'step': 1, 'name': 'Double Cleanse', 'desc': 'Micellar water + gel cleanser'},
        ],
        'products': [
          {
            'category': 'Cleanser',
            'name': 'Teal Purifying Gel',
            'desc': 'Formula bebas minyak untuk kulit berminyak.',
          }
        ],
        'notes': 'Hasil terdeteksi dengan baik.',
        'created_at': '2026-10-19T10:00:00Z',
      };
      final result = ScanResult.fromJson(json);
      expect(result.skinType, 'oily');
      expect(result.confidence, 0.92);
      expect(result.routineMorning.length, 1);
      expect(result.routineNight.length, 1);
      expect(result.products.length, 1);
      expect(result.products.first.name, 'Teal Purifying Gel');
    });

    test('ScanResult parses rule-v2 combination fields', () {
      final json = {
        'skin_type': 'oily',
        'confidence': 0.425,
        'probabilities': {
          'normal': 0.253,
          'dry': 0.322,
          'oily': 0.425,
          'combination': 0.644,
        },
        'raw_probabilities': {'dry': 0.322, 'normal': 0.253, 'oily': 0.425},
        'combination_score': 0.644,
        'is_combination': true,
        'rule_version': 'rule-v2',
        'description': 'Kulit berminyak.',
        'routine': {'morning': [], 'night': []},
        'products': [],
        'demo': false,
      };

      final result = ScanResult.fromJson(json);
      expect(result.skinType, 'oily');
      expect(result.rawProbabilities['oily'], closeTo(0.425, 1e-9));
      expect(result.combinationScore, closeTo(0.644, 1e-9));
      expect(result.isCombination, isTrue);
      expect(result.combinationPercent, 64);
      expect(result.ruleVersion, 'rule-v2');
      expect(
        result.primaryProbabilities.keys.toSet(),
        {'normal', 'oily', 'dry'},
      );
    });

    test('ScanResult parses 4-class rule-v3 response', () {
      final json = {
        'skin_type': 'combination',
        'confidence': 0.61,
        'probabilities': {
          'combination': 0.61,
          'dry': 0.05,
          'normal': 0.14,
          'oily': 0.20,
        },
        'raw_probabilities': {
          'combination': 0.61,
          'dry': 0.05,
          'normal': 0.14,
          'oily': 0.20,
        },
        'combination_score': 0.61,
        'is_combination': true,
        'rule_version': 'rule-v3',
        'description': 'Kulit kombinasi.',
        'routine': {'morning': [], 'night': []},
        'products': [],
        'demo': false,
      };

      final result = ScanResult.fromJson(json);
      expect(result.skinType, 'combination');
      expect(result.skinTypeLabel, 'Kulit Kombinasi');
      expect(result.isCombination, isTrue);
      expect(result.ruleVersion, 'rule-v3');
      expect(
        result.primaryProbabilities.keys.toSet(),
        {'combination', 'dry', 'normal', 'oily'},
      );
    });

    test('ScanResult falls back for legacy response without rule fields', () {
      final json = {
        'skin_type': 'dry',
        'confidence': 0.7,
        'probabilities': {
          'normal': 0.1,
          'dry': 0.7,
          'oily': 0.1,
          'combination': 0.2,
        },
        'description': 'Kulit kering.',
        'routine': {'morning': [], 'night': []},
        'products': [],
      };

      final result = ScanResult.fromJson(json);
      expect(result.combinationScore, closeTo(0.2, 1e-9));
      expect(result.isCombination, isFalse);
      expect(result.rawProbabilities['dry'], closeTo(0.7, 1e-9));
      expect(result.ruleVersion, 'rule-v3');
    });
  });

  group('Core Reusable Widgets Tests', () {
    testWidgets('SkinlyButton renders label and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkinlyButton(
              text: 'Mulai Sekarang',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Mulai Sekarang'), findsOneWidget);
      await tester.tap(find.text('Mulai Sekarang'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('SkinlyButton displays loader when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkinlyButton(
              text: 'Simpan',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('SkinlyCard renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkinlyCard(
              child: const Text('Isi Kartu Skinly'),
            ),
          ),
        ),
      );

      expect(find.text('Isi Kartu Skinly'), findsOneWidget);
    });

    testWidgets('SkinlyTextField toggles obscureText for password field', (tester) async {
      final controller = TextEditingController(text: 'secret123');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkinlyTextField(
              label: 'Kata Sandi',
              controller: controller,
              isPassword: true,
            ),
          ),
        ),
      );

      expect(find.text('Kata Sandi'), findsOneWidget);
      // Ikon toggle visibility awal (klik untuk melihat)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('Auth Storage Unit Tests', () {
    test('AuthStorage saves and clears token', () async {
      final storage = AuthStorage();
      expect(storage.cachedToken, isNull);

      await storage.saveToken('test_jwt_token_123');
      expect(storage.cachedToken, 'test_jwt_token_123');

      final readToken = await storage.initToken();
      expect(readToken, 'test_jwt_token_123');

      await storage.clearToken();
      expect(storage.cachedToken, isNull);
    });

    test('AuthStorage onboarding flag persistence', () async {
      final storage = AuthStorage();
      expect(await storage.hasSeenOnboarding(), isFalse);

      await storage.setSeenOnboarding(true);
      expect(await storage.hasSeenOnboarding(), isTrue);
    });
  });

  group('DateFormatter Tests', () {
    test('formatFull formats date with time without throwing', () {
      final dt = DateTime(2026, 11, 16, 19, 30);
      final formatted = DateFormatter.formatFull(dt);
      expect(formatted, contains('2026'));
      expect(formatted, contains('16'));
      expect(formatted, contains('19:30'));
    });

    test('formatShort formats date without throwing', () {
      final dt = DateTime(2026, 11, 16);
      final formatted = DateFormatter.formatShort(dt);
      expect(formatted, contains('2026'));
      expect(formatted, contains('16'));
    });

    test('formatRelative returns appropriate labels', () {
      final now = DateTime.now();
      expect(DateFormatter.formatRelative(now), 'Baru saja');
      expect(DateFormatter.formatRelative(now.subtract(const Duration(minutes: 5))), '5 menit lalu');
      expect(DateFormatter.formatRelative(now.subtract(const Duration(hours: 3))), '3 jam lalu');
      expect(DateFormatter.formatRelative(now.subtract(const Duration(days: 2))), '2 hari lalu');
      final past = now.subtract(const Duration(days: 10));
      expect(DateFormatter.formatRelative(past), contains(past.year.toString()));
    });
  });
}
