// lib/features/knowledge/domain/article.dart
// Model domain untuk artikel edukasi
class Article {
  final String id;
  final String title;
  final String category;
  final String summary;
  final String? content;
  final String? coverImageUrl;
  final int readMinutes;
  final DateTime createdAt;

  const Article({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    this.content,
    this.coverImageUrl,
    required this.readMinutes,
    required this.createdAt,
  });

  String get categoryLabel {
    switch (category) {
      case 'jenis_kulit': return 'Jenis Kulit';
      case 'masalah_kulit': return 'Masalah Kulit';
      case 'perawatan': return 'Perawatan';
      default: return category;
    }
  }

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        summary: json['summary'] as String,
        content: json['content'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        readMinutes: json['read_minutes'] as int? ?? 3,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ArticleList {
  final List<Article> items;
  final int total;

  const ArticleList({required this.items, required this.total});

  factory ArticleList.fromJson(Map<String, dynamic> json) => ArticleList(
        items: (json['items'] as List? ?? [])
            .map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int? ?? 0,
      );
}
