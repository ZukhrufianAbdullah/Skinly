// lib/core/theme/app_text_styles.dart
// Text styles terpusat – Fredoka One/Fredoka (judul) & Poppins (body)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ──────────────────────────────────────────
  // FREDOKA ONE – judul besar, nama jenis kulit, tombol utama
  // ──────────────────────────────────────────

  /// Logo / app name (64px seperti di Figma splash)
  static TextStyle get displayXL => GoogleFonts.fredoka(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        height: 1.1,
      );

  /// Judul halaman besar (32px)
  static TextStyle get displayLarge => GoogleFonts.fredoka(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.2,
      );

  /// Judul section (28px)
  static TextStyle get displayMedium => GoogleFonts.fredoka(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.2,
      );

  /// Nama jenis kulit di hasil analisis (24px)
  static TextStyle get displaySmall => GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.3,
      );

  // ──────────────────────────────────────────
  // FREDOKA (SemiBold) – sub-judul slide, section title
  // ──────────────────────────────────────────

  /// Sub-judul besar (24px SemiBold) – walkthrough, kartu
  static TextStyle get headlineLarge => GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.3,
      );

  /// Judul kartu (20px SemiBold)
  static TextStyle get headlineMedium => GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.3,
      );

  /// Judul kecil / section (18px SemiBold)
  static TextStyle get headlineSmall => GoogleFonts.fredoka(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.4,
      );

  // ──────────────────────────────────────────
  // POPPINS – teks isi, label, deskripsi
  // ──────────────────────────────────────────

  /// Body besar (16px Regular)
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  /// Body normal (14px Regular) – deskripsi, konten artikel
  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  /// Body kecil (12px Regular) – caption, disclaimer
  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
        height: 1.5,
      );

  /// Label besar (16px Bold) – nama pengguna, label penting
  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  /// Label medium (14px SemiBold) – chip, tag, nav label
  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  /// Label kecil (12px SemiBold) – badge, keterangan kecil
  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// Caption (11px Light)
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        color: AppColors.textLight,
      );

  // ──────────────────────────────────────────
  // Tombol
  // ──────────────────────────────────────────

  /// Teks tombol utama – Fredoka Bold 20px (seperti Figma "Mulai Sekarang")
  static TextStyle get buttonPrimary => GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.3,
      );

  /// Teks tombol sekunder – Poppins Bold 16px
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.3,
      );

  /// Teks tombol kecil – Poppins SemiBold 14px
  static TextStyle get buttonSmall => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  // ──────────────────────────────────────────
  // Input form
  // ──────────────────────────────────────────

  /// Teks dalam input field
  static TextStyle get input => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
      );

  /// Label/hint input field
  static TextStyle get inputHint => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
      );

  // ──────────────────────────────────────────
  // Bottom nav
  // ──────────────────────────────────────────

  /// Label nav aktif
  static TextStyle get navLabelActive => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.navIconActive,
      );

  /// Label nav non-aktif
  static TextStyle get navLabel => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.navIconInactive,
      );

  // ──────────────────────────────────────────
  // Angka / persen (Fredoka One besar)
  // ──────────────────────────────────────────

  /// Angka akurasi besar (36px)
  static TextStyle get percentLarge => GoogleFonts.fredoka(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
        height: 1.0,
      );

  /// Angka / persen sedang (20px)
  static TextStyle get percentMedium => GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.0,
      );

  // ──────────────────────────────────────────
  // Aliases untuk konsistensi komponen
  // ──────────────────────────────────────────
  static TextStyle get h1 => headlineLarge;
  static TextStyle get h2 => headlineMedium;
  static TextStyle get h3 => headlineSmall;
  static TextStyle get label => labelMedium;
}
