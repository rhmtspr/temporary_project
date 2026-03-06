// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'providers/camera_provider.dart';
import 'providers/image_provider.dart';
import 'providers/prediction_provider.dart';
import 'providers/meal_provider.dart';

class FoodClassifierApp extends StatelessWidget {
  const FoodClassifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppImageProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(
          create: (_) => PredictionProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => MealProvider()),
      ],
      child: MaterialApp.router(
        title: 'Food Classifier',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE94560),
            brightness: Brightness.dark,
          ),
          fontFamily: 'SF Pro Display',
        ),
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
