// lib/providers/meal_provider.dart
import 'package:flutter/foundation.dart';
import '../models/meal.dart';
import '../models/nutrition.dart';
import '../services/mealdb_service.dart';
import '../services/gemini_service.dart';
import '../utils/logger.dart';

enum MealState { idle, loading, success, error }

class MealProvider extends ChangeNotifier {
  final MealDbService _mealDbService;
  final GeminiService _geminiService;

  MealState _mealState = MealState.idle;
  MealState _nutritionState = MealState.idle;

  List<Meal> _meals = [];
  Nutrition? _nutrition;
  String? _mealError;
  String? _nutritionError;

  MealProvider({
    MealDbService? mealDbService,
    GeminiService? geminiService,
  })  : _mealDbService = mealDbService ?? MealDbService(),
        _geminiService = geminiService ?? GeminiService() {
    _geminiService.initialize();
  }

  MealState get mealState => _mealState;
  MealState get nutritionState => _nutritionState;
  List<Meal> get meals => _meals;
  Nutrition? get nutrition => _nutrition;
  String? get mealError => _mealError;
  String? get nutritionError => _nutritionError;
  bool get isMealLoading => _mealState == MealState.loading;
  bool get isNutritionLoading => _nutritionState == MealState.loading;

  Future<void> fetchMealInfo(String foodName) async {
    _mealState = MealState.loading;
    _mealError = null;
    notifyListeners();

    try {
      _meals = await _mealDbService.searchMeals(foodName);
      _mealState = MealState.success;
      appLogger.i('Found ${_meals.length} meals for: $foodName');
    } catch (e) {
      _mealError = 'Failed to load meal info: $e';
      _mealState = MealState.error;
      appLogger.e(_mealError!);
    }
    notifyListeners();
  }

  Future<void> fetchNutrition(String foodName) async {
    _nutritionState = MealState.loading;
    _nutritionError = null;
    notifyListeners();

    try {
      _nutrition = await _geminiService.getNutritionInfo(foodName);
      _nutritionState = MealState.success;
    } catch (e) {
      _nutritionError = 'Failed to load nutrition: $e';
      _nutritionState = MealState.error;
      appLogger.e(_nutritionError!);
    }
    notifyListeners();
  }

  Future<void> loadAllInfo(String foodName) async {
    await Future.wait([
      fetchMealInfo(foodName),
      fetchNutrition(foodName),
    ]);
  }

  void clear() {
    _meals = [];
    _nutrition = null;
    _mealState = MealState.idle;
    _nutritionState = MealState.idle;
    _mealError = null;
    _nutritionError = null;
    notifyListeners();
  }
}
