// lib/config/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Food Classifier';

  // MealDB API
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const String mealDbSearchEndpoint = '/search.php';

  // Gemini API
  // Set your Gemini API Key here OR use --dart-define=GEMINI_API_KEY=xxx
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Firebase ML Model Name
  static const String firebaseModelName = 'food_classifier';

  // Local model path (fallback)
  static const String localModelPath = 'assets/models/food_classification.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  // Camera
  static const int cameraImageSize = 224;
  static const double confidenceThreshold = 0.5;

  // Isolate
  static const String isolateInferencePort = 'inference_port';
}
