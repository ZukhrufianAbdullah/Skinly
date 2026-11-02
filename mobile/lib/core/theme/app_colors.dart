// lib/core/theme/app_colors.dart
// Design tokens warna Skinly – sesuai Figma (teal palette)
// TODO: Verifikasi ulang hex ini dengan Figma Dev Mode inspect.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ──────────────────────────────────────────
  // Primary – Teal (#6CC9BF dari Figma fill_73912c5c)
  // ──────────────────────────────────────────
  static const Color primary = Color(0xFF6CC9BF);
  static const Color primaryDark = Color(0xFF327E76);   // teal gelap – tombol, teks aktif
  static const Color primaryDeep = Color(0xFF1B6159);   // teal sangat gelap
  static const Color primaryLight = Color(0xFF86E4DA);  // mint terang
  static const Color primaryBackground = Color(0xFFE8F7F5); // teal sangat pucat

  // ──────────────────────────────────────────
  // Accent – Pink (#F26D9B / #F76A9B dari Figma)
  // ──────────────────────────────────────────
  static const Color accent = Color(0xFFF26D9B);        // pink aksen utama
  static const Color accentButton = Color(0xFFF76A9B);  // pink tombol CTA
  static const Color accentLight = Color(0xFFF9CDCD);   // pink muda / kartu
  static const Color accentSoft = Color(0xFFFBE0EB);    // pink sangat pucat

  // ──────────────────────────────────────────
  // Surface
  // ──────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTeal = Color(0xFF6CC9BF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // ──────────────────────────────────────────
  // Text
  // ──────────────────────────────────────────
  static const Color textDark = Color(0xFF1E293B);       // #1E293B dari Figma
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textTealDark = Color(0xFF327E76);   // teks di atas teal muda
  static const Color textTealDeep = Color(0xFF1B6159);   // label kecil di atas teal
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ──────────────────────────────────────────
  // Neutral Gray Scale
  // ──────────────────────────────────────────
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);

  // ──────────────────────────────────────────
  // Status
  // ──────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // ──────────────────────────────────────────
  // Skin type (bar progress & chip)
  // ──────────────────────────────────────────
  static const Color skinNormal = Color(0xFF4CAF50);
  static const Color skinOily = Color(0xFF42A5F5);
  static const Color skinDry = Color(0xFFFF7043);
  static const Color skinCombination = Color(0xFFAB47BC);

  // ──────────────────────────────────────────
  // Bottom navigation
  // ──────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navIconActive = Color(0xFF327E76);
  static const Color navIconInactive = Color(0xFF94A3B8);
  static const Color navCameraButton = Color(0xFF6CC9BF);

  // ──────────────────────────────────────────
  // Card / container
  // ──────────────────────────────────────────
  static const Color cardTeal = Color(0xFF86E4DA);
  static const Color cardPink = Color(0xFFF9CDCD);
  static const Color cardDarkTeal = Color(0xFF327E76);

  // ──────────────────────────────────────────
  // Homepage – bagian "Jenis Kulit" (biru, dari Figma homepage)
  // Nilai diperkirakan dari screenshot desain.
  // ──────────────────────────────────────────
  static const Color skinSectionBlue = Color(0xFF3E77C0);  // judul "Jenis Kulit"
  static const Color skinCardBlue = Color(0xFFA8CAFB);     // latar kartu jenis kulit
  static const Color skinCardShadow = Color(0xFF6F9BD8);   // bayangan kartu

  // ──────────────────────────────────────────
  // Divider & border
  // ──────────────────────────────────────────
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // ──────────────────────────────────────────
  // Gradients
  // ──────────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6CC9BF), Color(0xFF327E76)],
  );

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF327E76), Color(0xFF1B6159)],
  );

  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF76A9B), Color(0xFFF26D9B)],
  );

  static const Gradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6CC9BF), Color(0xFF4AAFA4)],
  );

  // ──────────────────────────────────────────
  // Helper
  // ──────────────────────────────────────────
  static Color skinTypeColor(String skinType) {
    switch (skinType.toLowerCase()) {
      case 'normal':
        return skinNormal;
      case 'oily':
        return skinOily;
      case 'dry':
        return skinDry;
      case 'combination':
        return skinCombination;
      default:
        return primary;
    }
  }

  static String skinTypeLabel(String skinType) {
    switch (skinType.toLowerCase()) {
      case 'normal':
        return 'Normal';
      case 'oily':
        return 'Berminyak';
      case 'dry':
        return 'Kering';
      case 'combination':
        return 'Kombinasi';
      default:
        return skinType;
    }
  }
}
