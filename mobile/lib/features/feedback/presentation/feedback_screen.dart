import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../data/feedback_repository.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _repo = FeedbackRepository();
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _repo.submitFeedback(
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text('Gagal mengirim ulasan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Beri Masukan',
          style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _submitted ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          SkinlyCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 22,
            child: Row(
              children: [
                const SkinlyMascot(
                  width: 70,
                  height: 70,
                  variant: SkinlyMascotVariant.standard,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suaramu Berarti! 💬',
                        style: AppTextStyles.h3.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bantu kami mengembangkan Skinly agar semakin akurat dan nyaman digunakan.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Rating Card
          SkinlyCard(
            padding: const EdgeInsets.all(22),
            borderRadius: 22,
            child: Column(
              children: [
                Text(
                  'Seberapa puas kamu dengan akurasi Skinly?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    final isSelected = rating <= _selectedRating;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRating = rating);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 42,
                            color: isSelected ? const Color(0xFFFFB300) : AppColors.neutral300,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  _getRatingDescription(_selectedRating),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Komentar / Saran Card
          SkinlyCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kritik & Saran (Opsional)',
                  style: AppTextStyles.h3.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan pengalamanmu, saran fitur baru, atau kendala yang dihadapi...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                    filled: true,
                    fillColor: AppColors.primaryBackground.withOpacity(0.5),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Kirim
          SkinlyButton(
            text: 'Kirim Masukan',
            variant: SkinlyButtonVariant.primaryPink,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SkinlyMascot(
              width: 130,
              height: 130,
              animated: true,
              variant: SkinlyMascotVariant.standard,
            ),
            const SizedBox(height: 24),
            Text(
              'Terima Kasih Banyak! 🎉',
              textAlign: TextAlign.center,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textTealDark,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Masukanmu sangat berharga bagi kami untuk terus menyempurnakan aplikasi Skinly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SkinlyButton(
              text: 'Kembali',
              variant: SkinlyButtonVariant.primaryTeal,
              width: double.infinity,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Kurang 😔';
      case 2:
        return 'Kurang Memuaskan 🙁';
      case 3:
        return 'Cukup Baik 😐';
      case 4:
        return 'Sangat Bagus! 😊';
      case 5:
        return 'Luar Biasa Membantu! 😍';
      default:
        return '';
    }
  }
}
