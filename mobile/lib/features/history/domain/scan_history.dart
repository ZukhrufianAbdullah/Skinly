// lib/features/history/domain/scan_history.dart
// Model domain untuk riwayat scan yang tersimpan di database
import '../../../core/utils/date_parser.dart';
import '../../scan/domain/scan_result.dart';

class ScanHistoryItem {
  final String id;
  final String deviceId;
  final String skinType;
  final double confidence;
  final Map<String, double> probabilities;
  final String? imagePath;
  final DateTime createdAt;
  final String description;
  final List<RoutineStep> routineMorning;
  final List<RoutineStep> routineNight;
  final List<ProductRecommendation> products;

  const ScanHistoryItem({
    required this.id,
    required this.deviceId,
    required this.skinType,
    required this.confidence,
    required this.probabilities,
    this.imagePath,
    required this.createdAt,
    this.description = '',
    this.routineMorning = const [],
    this.routineNight = const [],
    this.products = const [],
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

    final skinType = json['skin_type'] as String? ?? 'normal';

    final morningRaw = json['routine'] != null
        ? (json['routine']['morning'] as List? ?? [])
        : (json['routine_morning'] as List? ?? []);
    final nightRaw = json['routine'] != null
        ? (json['routine']['night'] as List? ?? [])
        : (json['routine_night'] as List? ?? []);
    final productsRaw = json['products'] as List? ?? [];

    List<RoutineStep> morning = morningRaw
        .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
        .toList();
    List<RoutineStep> night = nightRaw
        .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
        .toList();
    List<ProductRecommendation> products = productsRaw
        .map((e) => ProductRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();

    String description = json['description'] as String? ?? '';
    if (description.isEmpty) {
      switch (skinType.toLowerCase()) {
        case 'oily':
          description = 'Kulit memproduksi sebum berlebih terutama di dahi, hidung, dan dagu. Pori-pori tampak besar dan rentan terhadap komedo dan jerawat.';
          break;
        case 'dry':
          description = 'Kulit terasa kencang, kasar, atau bersisik karena kurangnya minyak alami. Rentan mengalami iritasi dan garis halus.';
          break;
        case 'combination':
          description = 'Area T-zone (dahi, hidung, dagu) cenderung berminyak sementara area pipi normal atau kering. Memerlukan perawatan seimbang.';
          break;
        default:
          description = 'Keseimbangan kelembapan dan minyak kulit terjaga dengan baik. Pori-pori halus dan tekstur kulit kenyal.';
      }
    }

    if (morning.isEmpty) {
      morning = const [
        RoutineStep(step: '1', name: 'Pembersih Wajah Gentle', detail: 'Cuci muka dengan pembersih lembut bebas busa keras.'),
        RoutineStep(step: '2', name: 'Pelembap Ringan', detail: 'Oleskan pelembap untuk menjaga hidrasi kulit.'),
        RoutineStep(step: '3', name: 'Sunscreen SPF 30+', detail: 'Wajib gunakan tabir surya setiap pagi sebelum beraktivitas.'),
      ];
    }
    if (night.isEmpty) {
      night = const [
        RoutineStep(step: '1', name: 'Double Cleansing', detail: 'Bersihkan sisa minyak, debu, dan polusi setelah seharian.'),
        RoutineStep(step: '2', name: 'Pelembap / Krim Malam', detail: 'Nutrisi kulit saat regenerasi di malam hari.'),
      ];
    }
    if (products.isEmpty) {
      products = const [
        ProductRecommendation(name: 'Gentle Facial Wash', note: 'Membersihkan kotoran tanpa membuat kulit kering tertarik'),
        ProductRecommendation(name: 'Hydrating Moisturizer', note: 'Mengunci kelembapan dan memperkuat skin barrier'),
        ProductRecommendation(name: 'Broad Spectrum Sunscreen SPF 30+', note: 'Perlindungan maksimal dari radiasi UV matahari'),
      ];
    }

    return ScanHistoryItem(
      id: json['id'] as String,
      deviceId: json['device_id'] as String? ?? '',
      skinType: skinType,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: probs,
      imagePath: json['image_path'] as String?,
      createdAt: parseServerDate(json['created_at'] as String),
      description: description,
      routineMorning: morning,
      routineNight: night,
      products: products,
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
