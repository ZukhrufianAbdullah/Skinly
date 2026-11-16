import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_dialog.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../data/history_repository.dart';
import '../domain/scan_history.dart';
import '../../scan/domain/scan_result.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String scanId;
  final ScanHistoryItem? initialItem;
  const HistoryDetailScreen({super.key, required this.scanId, this.initialItem});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final _repo = HistoryRepository();
  ScanHistoryItem? _item;
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _item = widget.initialItem;
      _isLoading = false;
    }
    _load();
  }

  Future<void> _load() async {
    if (_item == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final item = await _repo.getDetail(widget.scanId);
      if (mounted) {
        setState(() {
          _item = item;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _item == null) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final item = _item;
    if (item == null) return;

    final confirm = await SkinlyDialog.show(
      context: context,
      title: 'Hapus Riwayat Scan?',
      message: 'Riwayat scan "${item.skinTypeLabel}" ini akan dihapus permanen dari akunmu.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 40),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _repo.deleteScan(item.id);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: const Text('Riwayat scan berhasil dihapus.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Gagal menghapus: $e'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
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
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Detail Riwayat Scan',
          style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_item != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: _isDeleting ? null : _handleDelete,
              tooltip: 'Hapus Riwayat',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkinlyMascot(width: 80, height: 80),
              const SizedBox(height: 16),
              Text('Gagal Memuat Detail', style: AppTextStyles.h3.copyWith(color: AppColors.error)),
              const SizedBox(height: 6),
              Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              SkinlyButton(text: 'Coba Lagi', onPressed: _load),
            ],
          ),
        ),
      );
    }

    final item = _item!;
    final skinColor = _getSkinTypeColor(item.skinType);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kartu Utama Hasil Analisis
          SkinlyCard(
            padding: const EdgeInsets.all(22),
            borderRadius: 24,
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: skinColor.withOpacity(0.15),
                    border: Border.all(color: skinColor, width: 3),
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 50,
                    color: skinColor,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: skinColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.skinTypeLabel,
                    style: AppTextStyles.h1.copyWith(
                      color: skinColor,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tingkat Keyakinan: ${item.confidencePercent}%',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textTealDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormatter.formatFull(item.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                ),
                const SizedBox(height: 20),
                // Bar Probabilitas 4 Jenis Kulit (Akurat argmax 4 kelas)
                _buildProbabilities(item),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Karakteristik Kulit
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
                  item.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Rutinitas Pagi Hari
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
                _buildRoutineSteps(item.routineMorning),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Rutinitas Malam Hari
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
                _buildRoutineSteps(item.routineNight),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Rekomendasi Kandungan & Produk
          if (item.products.isNotEmpty) ...[
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
                    children: item.products.map((prod) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                    'Hasil ini bersifat estimasi dan bukan diagnosis medis. Konsultasikan ke dokter spesialis kulit untuk kondisi kulit tertentu.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Hapus Riwayat
          SkinlyButton(
            text: 'Hapus Riwayat Ini',
            variant: SkinlyButtonVariant.outline,
            isLoading: _isDeleting,
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
            onPressed: _handleDelete,
          ),
        ],
      ),
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
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    if (step.detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        step.detail,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
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

  Widget _buildProbabilities(ScanHistoryItem item) {
    final probs = item.probabilities;
    final keys = ['normal', 'oily', 'dry', 'combination'];
    final labels = {
      'normal': 'Normal',
      'oily': 'Berminyak',
      'dry': 'Kering',
      'combination': 'Kombinasi',
    };

    return Column(
      children: keys.map((key) {
        final val = (probs[key] ?? 0.0).clamp(0.0, 1.0);
        final percent = (val * 100).toInt();
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
                  value: val,
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
  }
}
