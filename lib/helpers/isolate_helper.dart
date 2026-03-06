// lib/helpers/isolate_helper.dart
// NOTE: The actual isolate implementation is embedded directly in TfliteService
// using _inferenceIsolate() top-level function for better Isolate.spawn compatibility.
//
// The isolate approach in tflite_service.dart:
// 1. Accepts Float32List input data + model file path via _IsolateData
// 2. Runs TFLite inference in separate Dart Isolate
// 3. Returns probabilities via SendPort
// 4. Keeps UI thread free during heavy ML inference

