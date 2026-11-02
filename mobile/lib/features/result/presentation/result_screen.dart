import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../scan/domain/scan_result.dart';
import '../../scan/data/scan_repository.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> analysisData;
  const ResultScreen({super.key, required this.analysisData});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _confidenceAnim;
  bool _isSaving = false;
  bool _saved = false;

  ScanResult get result => widget.analysisData['result'] as ScanResult;
  File? get imageFile => widget.analysisData['imageFile'] as File?;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _confidenceAnim = Tween<double>(begin: 0, end: result.confidence).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    if (_saved || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ScanRepository().saveResult(result);
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Hasil berhasil disimpan ke Riwayat!',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text('Gagal menyimpan riwayat: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _getSkinTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return AppColors.skinNormal;
      case 'oily':
        return AppColors.skinOily;
      case 'dry':
        return AppColors.skinDry;
      case 'combination':
        return AppColors.skinCombination;
      default:
        return AppColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skinColor = _getSkinTypeColor(result.skinType);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Hasil Analisis Kulitmu',
          style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge Mode Demo (jika aktif)
              if (result.isDemo) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Mode demo (model machine learning offline)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Kartu Utama Hasil Analisis
              SkinlyCard(
                padding: const EdgeInsets.all(22),
                borderRadius: 24,
                child: Column(
                  children: [
                    // Foto dengan Hero animation
                    Hero(
                      tag: 'scan_image',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: skinColor, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: skinColor.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: imageFile != null
                              ? Image.file(imageFile!, fit: BoxFit.cover)
                              : Container(
                                  color: AppColors.primaryBackground,
                                  child: const Icon(
                                    Icons.face_retouching_natural_rounded,
                                    size: 60,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Jenis Kulit Utama
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: skinColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.skinTypeLabel,
                        style: AppTextStyles.h1.copyWith(
                          color: skinColor,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Count-up Skor Akurasi
                    AnimatedBuilder(
                      animation: _confidenceAnim,
                      builder: (context, child) {
                        final percent = (_confidenceAnim.value * 100).toInt();
                        return Text(
                          'Tingkat Keyakinan: $percent%',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textTealDark,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // 4 Bar Probabilitas Jenis Kulit
                    _buildProbabilityBars(),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Deskripsi Karakteristik Kulit
              SkinlyCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, color: AppColors.primaryDark, size: 22),
                        const SizedBox(width: 10),
                        Text('Karakteristik Kulit', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Rekomendasi Rutinitas Pagi
              SkinlyCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFA000), size: 22),
                        const SizedBox(width: 10),
                        Text('Rutinitas Pagi Hari', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildRoutineSteps(result.routineMorning),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Rekomendasi Rutinitas Malam
              SkinlyCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nightlight_round, color: Color(0xFF5C6BC0), size: 22),
                        const SizedBox(width: 10),
                        Text('Rutinitas Malam Hari', style: AppTextStyles.h3),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildRoutineSteps(result.routineNight),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Rekomendasi Bahan Aktif & Produk
              if (result.products.isNotEmpty) ...[
                SkinlyCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spa_rounded, color: AppColors.primaryDark, size: 22),
                          const SizedBox(width: 10),
                          Text('Rekomendasi Produk & Kandungan', style: AppTextStyles.h3),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.products.map((prod) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              prod.name.isNotEmpty ? prod.name : prod.toString(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTealDeep,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Disclaimer Medis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.health_and_safety_outlined, color: AppColors.neutral600, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hasil ini bersifat estimasi dan bukan diagnosis medis. Konsultasikan ke dokter kulit untuk masalah kulit yang serius.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Simpan ke Riwayat & Scan Ulang
              SkinlyButton(
                text: _saved ? 'Tersimpan di Riwayat' : 'Simpan ke Riwayat',
                variant: _saved ? SkinlyButtonVariant.primaryTeal : SkinlyButtonVariant.primaryPink,
                isLoading: _isSaving,
                icon: Icon(_saved ? Icons.check_circle_rounded : Icons.bookmark_add_outlined, size: 20, color: Colors.white),
                onPressed: _saveToHistory,
              ),
              const SizedBox(height: 12),
              SkinlyButton(
                text: 'Scan Ulang',
                variant: SkinlyButtonVariant.outline,
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primaryDark),
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilityBars() {
    final probs = result.probabilities;
    final keys = ['normal', 'oily', 'dry', 'combination'];
    final labels = {
      'normal': 'Normal',
      'oily': 'Berminyak',
      'dry': 'Kering',
      'combination': 'Kombinasi',
    };

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Column(
          children: keys.map((key) {
            final targetValue = (probs[key] ?? 0.0).clamp(0.0, 1.0);
            final animatedValue = targetValue * _animController.value;
            final percent = (animatedValue * 100).toInt();
            final color = _getSkinTypeColor(key);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        labels[key] ?? key,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: animatedValue,
                      minHeight: 8,
                      backgroundColor: AppColors.neutral200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRoutineSteps(List<RoutineStep> steps) {
    if (steps.isEmpty) {
      return Text(
        'Tidak ada rutinitas spesifik.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      );
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  step.step.isNotEmpty ? step.step : '${index + 1}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (step.detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.detail,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
