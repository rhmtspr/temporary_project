// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_constants.dart';
import '../models/nutrition.dart';
import '../utils/logger.dart';

class GeminiService {
  GenerativeModel? _model;

  void initialize() {
    final apiKey = AppConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      appLogger.w('Gemini API key not set. Use --dart-define=GEMINI_API_KEY=your_key');
      return;
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    appLogger.i('Gemini initialized');
  }

  Future<Nutrition?> getNutritionInfo(String foodName) async {
    if (_model == null) {
      appLogger.w('Gemini not initialized');
      return _getFallbackNutrition(foodName);
    }

    try {
      final prompt = '''
Provide nutritional information for "$foodName" in JSON format.
Return ONLY valid JSON, no markdown, no explanation.
Format:
{
  "foodName": "$foodName",
  "calories": "XXX kcal",
  "carbohydrates": "XX g",
  "fat": "XX g",
  "fiber": "XX g",
  "protein": "XX g",
  "servingSize": "XXX g",
  "description": "Brief description of the food"
}
Use typical serving size values. Be accurate.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) return null;

      // Clean the response
      String cleaned = text.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      final json = jsonDecode(cleaned.trim()) as Map<String, dynamic>;
      return Nutrition.fromJson(json);
    } catch (e) {
      appLogger.e('Gemini nutrition error: $e');
      return _getFallbackNutrition(foodName);
    }
  }

  Nutrition _getFallbackNutrition(String foodName) {
    return Nutrition(
      foodName: foodName,
      calories: 'N/A',
      carbohydrates: 'N/A',
      fat: 'N/A',
      fiber: 'N/A',
      protein: 'N/A',
      description: 'Nutritional data unavailable. Please set GEMINI_API_KEY.',
    );
  }
}
