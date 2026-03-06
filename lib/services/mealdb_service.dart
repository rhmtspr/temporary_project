// lib/services/mealdb_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../models/meal.dart';
import '../utils/logger.dart';

class MealDbService {
  final http.Client _client;

  MealDbService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Meal>> searchMeals(String query) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.mealDbBaseUrl}${AppConstants.mealDbSearchEndpoint}?s=$query',
      );

      appLogger.i('Searching MealDB for: $query');
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final meals = data['meals'];

        if (meals == null) {
          appLogger.w('No meals found for: $query');
          return [];
        }

        return (meals as List)
            .map((m) => Meal.fromJson(m as Map<String, dynamic>))
            .toList();
      } else {
        appLogger.e('MealDB error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      appLogger.e('MealDB service error: $e');
      return [];
    }
  }

  Future<Meal?> getMealById(String id) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.mealDbBaseUrl}/lookup.php?i=$id',
      );

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final meals = data['meals'];
        if (meals != null && (meals as List).isNotEmpty) {
          return Meal.fromJson(meals[0] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      appLogger.e('MealDB getMealById error: $e');
      return null;
    }
  }

  void dispose() => _client.close();
}
