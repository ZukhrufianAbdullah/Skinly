import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../data/knowledge_repository.dart';
import '../domain/article.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _repo = KnowledgeRepository();
  Article? _article;
  bool _isLoading = true;
  String? _error;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final article = await _repo.getArticleDetail(widget.articleId);
      setState(() => _article = article);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Edukasi Kulit',
          style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppColors.accentButton : Colors.white,
            ),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 1200),
                  backgroundColor: AppColors.primaryDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text(_isBookmarked ? 'Disimpan ke favorit' : 'Dihapus dari favorit'),
                ),
              );
            },
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
              Text('Gagal Memuat Artikel', style: AppTextStyles.h3.copyWith(color: AppColors.error)),
              const SizedBox(height: 6),
              Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 18),
              SkinlyButton(text: 'Coba Lagi', onPressed: _loadDetail),
            ],
          ),
        ),
      );
    }

    final article = _article!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  article.categoryLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.neutral500),
              const SizedBox(width: 4),
              Text(
                '${article.readMinutes} menit baca',
                style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
              ),
              const Spacer(),
              Text(
                DateFormatter.formatRelative(article.createdAt),
                style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Judul
          Text(
            article.title,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.textTealDark,
              fontSize: 24,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan
          SkinlyCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            backgroundColor: AppColors.white,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryDark, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    article.summary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTealDeep,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Isi artikel
          SkinlyCard(
            padding: const EdgeInsets.all(22),
            borderRadius: 22,
            child: Text(
              article.content?.isNotEmpty == true ? article.content! : article.summary,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Catatan Skinly Expert
          SkinlyCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 20,
            backgroundColor: AppColors.primaryDark,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catatan Tim Skinly',
                        style: AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Konsistensi adalah kunci utama dalam merawat kulit wajah. Selalu gunakan tabir surya setiap pagi dan lakukan scan berkala untuk memantau perkembangan kulitmu.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
