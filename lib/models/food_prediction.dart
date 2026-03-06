// lib/models/food_prediction.dart

class FoodPrediction {
  final String imagePath;
  final String foodName;
  final double confidence;
  final List<PredictionResult> allResults;

  const FoodPrediction({
    required this.imagePath,
    required this.foodName,
    required this.confidence,
    this.allResults = const [],
  });

  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';
}

class PredictionResult {
  final String label;
  final double confidence;

  const PredictionResult({required this.label, required this.confidence});

  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';
}
