// lib/features/scan/domain/scan_result.dart
// Model domain untuk hasil analisis kulit
class ScanResult {
  final String skinType;
  final double confidence;
  final Map<String, double> probabilities;
  final String description;
  final List<RoutineStep> routineMorning;
  final List<RoutineStep> routineNight;
  final List<ProductRecommendation> products;
  final bool isDemo;

  const ScanResult({
    required this.skinType,
    required this.confidence,
    required this.probabilities,
    required this.description,
    required this.routineMorning,
    required this.routineNight,
    required this.products,
    this.isDemo = false,
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

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final probRaw = json['probabilities'] as Map<String, dynamic>? ?? {};
    final probs = probRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    final morningRaw = json['routine'] != null
        ? (json['routine']['morning'] as List? ?? [])
        : (json['routine_morning'] as List? ?? []);
    final nightRaw = json['routine'] != null
        ? (json['routine']['night'] as List? ?? [])
        : (json['routine_night'] as List? ?? []);

    return ScanResult(
      skinType: json['skin_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: probs,
      description: json['description'] as String? ?? '',
      routineMorning: morningRaw
          .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      routineNight: nightRaw
          .map((e) => RoutineStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: (json['products'] as List? ?? [])
          .map((e) => ProductRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      isDemo: json['demo'] as bool? ?? false,
    );
  }
}

class RoutineStep {
  final String step;
  final String name;
  final String detail;

  const RoutineStep({required this.step, required this.name, required this.detail});

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
        step: json['step']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );
}

class ProductRecommendation {
  final String name;
  final String note;

  const ProductRecommendation({required this.name, required this.note});

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) =>
      ProductRecommendation(
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}
