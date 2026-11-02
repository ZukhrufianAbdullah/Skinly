import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../../../core/widgets/skinly_dialog.dart';
import '../../../core/router/app_router.dart';
import '../data/history_repository.dart';
import '../domain/scan_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = HistoryRepository();
  List<ScanHistoryItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _repo.getHistory();
      setState(() => _items = list.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(ScanHistoryItem item) async {
    final confirm = await SkinlyDialog.show(
      context: context,
      title: 'Hapus Riwayat Scan?',
      message: 'Riwayat scan "${item.skinTypeLabel}" tanggal ${DateFormatter.formatRelative(item.createdAt)} akan dihapus permanen.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 40),
    );

    if (confirm == true) {
      try {
        await _repo.deleteScan(item.id);
        setState(() => _items.removeWhere((i) => i.id == item.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              content: const Text('Riwayat berhasil dihapus.'),
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
              content: Text('Gagal menghapus: $e'),
            ),
          );
        }
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
          'Riwayat Scan',
          style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDark),
      );
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
              Text(
                'Terjadi Kesalahan',
                style: AppTextStyles.h3.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SkinlyButton(
                text: 'Coba Lagi',
                variant: SkinlyButtonVariant.primaryTeal,
                onPressed: _loadHistory,
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkinlyMascot(
                width: 120,
                height: 120,
                animated: true,
                variant: SkinlyMascotVariant.standard,
              ),
              const SizedBox(height: 20),
              Text(
                'Belum Ada Riwayat Scan',
                style: AppTextStyles.h2.copyWith(color: AppColors.textTealDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Hasil scan foto wajahmu akan tersimpan di sini secara rapi untuk memantau perubahan kulitmu.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SkinlyButton(
                text: 'Scan Sekarang',
                variant: SkinlyButtonVariant.primaryPink,
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                onPressed: () => context.push(AppRoutes.scan),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primaryDark,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _items.length,
        itemBuilder: (ctx, index) {
          final item = _items[index];
          final color = _getSkinTypeColor(item.skinType);

          return Dismissible(
            key: Key(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
            ),
            confirmDismiss: (_) async {
              await _deleteItem(item);
              return false;
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: SkinlyCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 22,
                onTap: () => context.push('/history/${item.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        color: color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.skinTypeLabel,
                                style: AppTextStyles.h3.copyWith(
                                  color: color,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${item.confidencePercent}%',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatRelative(item.createdAt),
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.neutral400, size: 22),
                      onPressed: () => _deleteItem(item),
                      tooltip: 'Hapus riwayat',
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.08, end: 0);
        },
      ),
    );
  }
}
