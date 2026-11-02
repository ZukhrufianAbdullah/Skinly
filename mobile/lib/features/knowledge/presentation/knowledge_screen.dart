import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../data/knowledge_repository.dart';
import '../domain/article.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final _repo = KnowledgeRepository();
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

  final _categories = [
    {'key': null, 'label': 'Semua'},
    {'key': 'jenis_kulit', 'label': 'Jenis Kulit'},
    {'key': 'masalah_kulit', 'label': 'Masalah Kulit'},
    {'key': 'perawatan', 'label': 'Perawatan'},
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _repo.getArticles(category: _selectedCategory);
      setState(() => _articles = list.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectCategory(String? key) {
    setState(() => _selectedCategory = key);
    _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Skin Knowledge',
          style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final key = cat['key'];
                  final label = cat['label'] as String;
                  final isSelected = _selectedCategory == key;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _selectCategory(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryDark : AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryDark : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.textTealDark,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Daftar Artikel
          Expanded(child: _buildBody()),
        ],
      ),
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
              SkinlyButton(text: 'Coba Lagi', onPressed: _loadArticles),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkinlyMascot(width: 90, height: 90),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Artikel',
                style: AppTextStyles.h2.copyWith(color: AppColors.textTealDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Artikel untuk kategori ini belum tersedia saat ini.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      color: AppColors.primaryDark,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _articles.length,
        itemBuilder: (ctx, index) {
          final item = _articles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: SkinlyCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 22,
              onTap: () => context.push('/knowledge/${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.categoryLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.neutral500),
                          const SizedBox(width: 4),
                          Text(
                            '${item.readMinutes} menit baca',
                            style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: AppTextStyles.h3.copyWith(fontSize: 17, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.summary,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Baca selengkapnya',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 60).ms, duration: 300.ms).slideY(begin: 0.08, end: 0);
        },
      ),
    );
  }
}
