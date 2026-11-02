// lib/features/history/domain/scan_history.dart
// Model domain untuk riwayat scan yang tersimpan di database
class ScanHistoryItem {
  final String id;
  final String deviceId;
  final String skinType;
  final double confidence;
  final Map<String, double> probabilities;
  final String? imagePath;
  final DateTime createdAt;

  const ScanHistoryItem({
    required this.id,
    required this.deviceId,
    required this.skinType,
    required this.confidence,
    required this.probabilities,
    this.imagePath,
    required this.createdAt,
  });

  String get skinTypeLabel {
    switch (skinType.toLowerCase()) {
      case 'normal': return 'Kulit Normal';
      case 'oily': return 'Kulit Berminyak';
      case 'dry': return 'Kulit Kering';
      case 'combination': return 'Kulit Kombinasi';
      default: return skinType;
    }
  }

  int get confidencePercent => (confidence * 100).round();

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    final probRaw = json['probabilities'] as Map<String, dynamic>? ?? {};
    final probs = probRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return ScanHistoryItem(
      id: json['id'] as String,
      deviceId: json['device_id'] as String? ?? '',
      skinType: json['skin_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: probs,
      imagePath: json['image_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'skin_type': skinType,
        'confidence': confidence,
        'probabilities': probabilities,
        if (imagePath != null) 'image_path': imagePath,
      };
}

class ScanHistoryList {
  final List<ScanHistoryItem> items;
  final int total;
  final int page;
  final int pageSize;

  const ScanHistoryList({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ScanHistoryList.fromJson(Map<String, dynamic> json) {
    return ScanHistoryList(
      items: (json['items'] as List? ?? [])
          .map((e) => ScanHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }
}
