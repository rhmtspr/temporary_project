// lib/models/nutrition.dart

class Nutrition {
  final String foodName;
  final String calories;
  final String carbohydrates;
  final String fat;
  final String fiber;
  final String protein;
  final String? servingSize;
  final String? description;

  const Nutrition({
    required this.foodName,
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.protein,
    this.servingSize,
    this.description,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    return Nutrition(
      foodName: json['foodName'] ?? '',
      calories: json['calories'] ?? '0',
      carbohydrates: json['carbohydrates'] ?? '0',
      fat: json['fat'] ?? '0',
      fiber: json['fiber'] ?? '0',
      protein: json['protein'] ?? '0',
      servingSize: json['servingSize'],
      description: json['description'],
    );
  }
}
