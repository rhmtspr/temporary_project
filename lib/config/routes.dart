// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/crop/crop_screen.dart';
import '../screens/prediction/prediction_screen.dart';
import '../screens/result/result_screen.dart';
import '../models/food_prediction.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String camera = '/camera';
  static const String crop = '/crop';
  static const String prediction = '/prediction';
  static const String result = '/result';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: camera,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: crop,
        builder: (context, state) {
          final imagePath = state.extra as String;
          return CropScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: prediction,
        builder: (context, state) {
          final imagePath = state.extra as String;
          return PredictionScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: result,
        builder: (context, state) {
          final prediction = state.extra as FoodPrediction;
          return ResultScreen(prediction: prediction);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
