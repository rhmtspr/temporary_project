// lib/services/tflite_service.dart
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../config/app_constants.dart';
import '../models/food_prediction.dart';
import '../helpers/image_helper.dart';
import '../utils/logger.dart';

class _IsolateData {
  final SendPort sendPort;
  final String modelFilePath;
  final Float32List inputData;
  final int numClasses;

  _IsolateData({
    required this.sendPort,
    required this.modelFilePath,
    required this.inputData,
    required this.numClasses,
  });
}

void _inferenceIsolate(_IsolateData data) async {
  try {
    final interpreter = await Interpreter.fromFile(File(data.modelFilePath));
    final inputShape = interpreter.getInputTensor(0).shape;
    final numClasses = data.numClasses;

    final input = data.inputData.reshape(inputShape);
    final output = List.generate(1, (_) => List<double>.filled(numClasses, 0.0));

    interpreter.run(input, output);
    interpreter.close();

    data.sendPort.send(output[0]);
  } catch (e) {
    data.sendPort.send('ERROR: $e');
  }
}

class TfliteService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  String? _modelFilePath;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({String? customModelPath}) async {
    try {
      _labels = await _loadLabels();
      _modelFilePath = customModelPath ?? await _copyAssetToTemp(
        AppConstants.localModelPath,
        'food_classification.tflite',
      );

      // Load interpreter to verify model
      _interpreter = await Interpreter.fromFile(File(_modelFilePath!));
      _isInitialized = true;
      appLogger.i('TFLite initialized. Labels: ${_labels.length}, Model: $_modelFilePath');
    } catch (e) {
      appLogger.e('TFLite initialization error: $e');
      rethrow;
    }
  }

  Future<void> updateModel(String modelPath) async {
    _interpreter?.close();
    _modelFilePath = modelPath;
    _interpreter = await Interpreter.fromFile(File(modelPath));
    _isInitialized = true;
    appLogger.i('Model updated from: $modelPath');
  }

  Future<List<PredictionResult>> runInference(String imagePath) async {
    if (!_isInitialized || _modelFilePath == null) {
      throw Exception('TFLite not initialized');
    }

    final inputBytes = await ImageHelper.preprocessImage(imagePath);
    if (inputBytes == null) throw Exception('Failed to preprocess image');

    final float32Data = Float32List.fromList(
      inputBytes.buffer.asFloat32List(),
    );

    final probabilities = await _runInIsolate(float32Data);
    return _processProbabilities(probabilities);
  }

  Future<List<double>> _runInIsolate(Float32List inputData) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _inferenceIsolate,
      _IsolateData(
        sendPort: receivePort.sendPort,
        modelFilePath: _modelFilePath!,
        inputData: inputData,
        numClasses: _labels.length,
      ),
    );

    final result = await receivePort.first;
    receivePort.close();

    if (result is String && result.startsWith('ERROR:')) {
      throw Exception(result.substring(7));
    }

    return List<double>.from(result as List);
  }

  List<PredictionResult> _processProbabilities(List<double> probabilities) {
    final results = <PredictionResult>[];

    for (int i = 0; i < probabilities.length && i < _labels.length; i++) {
      results.add(PredictionResult(
        label: _labels[i],
        confidence: probabilities[i],
      ));
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  Future<List<PredictionResult>> runInferenceFromBytes(
    Uint8List imageBytes,
  ) async {
    if (!_isInitialized) throw Exception('TFLite not initialized');

    // For camera feed - direct bytes processing
    final float32Data = Float32List.fromList(
      imageBytes.buffer.asFloat32List(),
    );

    final probabilities = await _runInIsolate(float32Data);
    return _processProbabilities(probabilities);
  }

  Future<List<String>> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(AppConstants.labelsPath);
      return labelData.split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (e) {
      appLogger.w('Could not load labels from assets, using defaults: $e');
      return _getDefaultLabels();
    }
  }

  Future<String> _copyAssetToTemp(String assetPath, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    try {
      final bytes = await rootBundle.load(assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List());
      return file.path;
    } catch (e) {
      appLogger.w('Could not load model from assets: $e');
      // Return path anyway - Firebase ML will update it
      return file.path;
    }
  }

  List<String> _getDefaultLabels() {
    return [
      'Apple Pie', 'Baby Back Ribs', 'Baklava', 'Beef Carpaccio',
      'Beef Tartare', 'Beet Salad', 'Beignets', 'Bibimbap', 'Bread Pudding',
      'Breakfast Burrito', 'Bruschetta', 'Caesar Salad', 'Cannoli',
      'Caprese Salad', 'Carrot Cake', 'Ceviche', 'Cheese Plate', 'Cheesecake',
      'Chicken Curry', 'Chicken Quesadilla', 'Chicken Wings', 'Chocolate Cake',
      'Chocolate Mousse', 'Churros', 'Clam Chowder', 'Club Sandwich',
      'Crab Cakes', 'Creme Brulee', 'Croque Madame', 'Cup Cakes',
      'Deviled Eggs', 'Donuts', 'Dumplings', 'Edamame', 'Eggs Benedict',
      'Escargots', 'Falafel', 'Filet Mignon', 'Fish And Chips', 'Foie Gras',
      'French Fries', 'French Onion Soup', 'French Toast', 'Fried Calamari',
      'Fried Rice', 'Frozen Yogurt', 'Garlic Bread', 'Gnocchi', 'Greek Salad',
      'Grilled Cheese Sandwich', 'Grilled Salmon', 'Guacamole', 'Gyoza',
      'Hamburger', 'Hot And Sour Soup', 'Hot Dog', 'Huevos Rancheros',
      'Hummus', 'Ice Cream', 'Lasagna', 'Lobster Bisque', 'Lobster Roll Sandwich',
      'Macaroni And Cheese', 'Macarons', 'Miso Soup', 'Mussels', 'Nachos',
      'Omelette', 'Onion Rings', 'Oysters', 'Pad Thai', 'Paella', 'Pancakes',
      'Panna Cotta', 'Peking Duck', 'Pho', 'Pizza', 'Pork Chop',
      'Poutine', 'Prime Rib', 'Pulled Pork Sandwich', 'Ramen', 'Ravioli',
      'Red Velvet Cake', 'Risotto', 'Samosa', 'Sashimi', 'Scallops',
      'Seaweed Salad', 'Shrimp And Grits', 'Spaghetti Bolognese',
      'Spaghetti Carbonara', 'Spring Rolls', 'Steak', 'Strawberry Shortcake',
      'Sushi', 'Tacos', 'Takoyaki', 'Tiramisu', 'Tuna Tartare', 'Waffles',
    ];
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
