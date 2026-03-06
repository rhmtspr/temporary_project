// lib/providers/prediction_provider.dart
import 'package:flutter/foundation.dart';
import '../models/food_prediction.dart';
import '../services/tflite_service.dart';
import '../services/firebase_model_service.dart';
import '../utils/logger.dart';

enum PredictionState { idle, initializing, predicting, success, error }

class PredictionProvider extends ChangeNotifier {
  final TfliteService _tfliteService;
  final FirebaseModelService _firebaseModelService;

  PredictionState _state = PredictionState.idle;
  FoodPrediction? _currentPrediction;
  String? _error;
  bool _useFirebaseModel = false;
  bool _isModelDownloading = false;

  PredictionProvider({
    TfliteService? tfliteService,
    FirebaseModelService? firebaseModelService,
  })  : _tfliteService = tfliteService ?? TfliteService(),
        _firebaseModelService = firebaseModelService ?? FirebaseModelService();

  PredictionState get state => _state;
  FoodPrediction? get currentPrediction => _currentPrediction;
  String? get error => _error;
  bool get isLoading => _state == PredictionState.predicting ||
      _state == PredictionState.initializing;
  bool get useFirebaseModel => _useFirebaseModel;
  bool get isModelDownloading => _isModelDownloading;

  Future<void> initialize() async {
    _setState(PredictionState.initializing);
    try {
      await _tfliteService.initialize();
      _setState(PredictionState.idle);
      appLogger.i('PredictionProvider initialized');
    } catch (e) {
      _setError('Failed to initialize ML model: $e');
    }
  }

  Future<void> downloadFirebaseModel() async {
    if (_isModelDownloading) return;
    _isModelDownloading = true;
    notifyListeners();

    try {
      final modelPath = await _firebaseModelService.downloadModel();
      if (modelPath != null) {
        await _tfliteService.updateModel(modelPath);
        _useFirebaseModel = true;
        appLogger.i('Switched to Firebase ML model');
      }
    } catch (e) {
      appLogger.e('Firebase model download error: $e');
    } finally {
      _isModelDownloading = false;
      notifyListeners();
    }
  }

  Future<FoodPrediction?> predict(String imagePath) async {
    _setState(PredictionState.predicting);
    _error = null;

    try {
      final results = await _tfliteService.runInference(imagePath);

      if (results.isEmpty) {
        _setError('No prediction results');
        return null;
      }

      final top = results.first;
      _currentPrediction = FoodPrediction(
        imagePath: imagePath,
        foodName: top.label,
        confidence: top.confidence,
        allResults: results.take(5).toList(),
      );

      _setState(PredictionState.success);
      return _currentPrediction;
    } catch (e) {
      _setError('Prediction failed: $e');
      return null;
    }
  }

  void clearPrediction() {
    _currentPrediction = null;
    _setState(PredictionState.idle);
  }

  void _setState(PredictionState state) {
    _state = state;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _state = PredictionState.error;
    appLogger.e(error);
    notifyListeners();
  }
}
