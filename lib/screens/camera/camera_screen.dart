// lib/screens/camera/camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/camera_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../models/food_prediction.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  bool _isLiveDetecting = false;
  FoodPrediction? _livePrediction;
  Timer? _streamTimer;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveDetection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraProvider = context.read<CameraProvider>();
    if (state == AppLifecycleState.inactive) {
      _stopLiveDetection();
    } else if (state == AppLifecycleState.resumed) {
      cameraProvider.initialize();
    }
  }

  void _startLiveDetection() {
    final cameraProvider = context.read<CameraProvider>();
    final predictionProvider = context.read<PredictionProvider>();

    setState(() => _isLiveDetecting = true);

    cameraProvider.startImageStream((CameraImage image) async {
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      // Process every 30 frames to avoid overload
      _streamTimer?.cancel();
      _streamTimer = Timer(const Duration(milliseconds: 1000), () async {
        try {
          // Capture a frame for inference
          final path = await cameraProvider.takePicture();
          if (path != null) {
            final prediction = await predictionProvider.predict(path);
            if (prediction != null && mounted) {
              setState(() => _livePrediction = prediction);
              // Clean up temp file
              File(path).deleteSync();
            }
          }
        } finally {
          _isProcessingFrame = false;
        }
      });
    });
  }

  void _stopLiveDetection() {
    _streamTimer?.cancel();
    context.read<CameraProvider>().stopImageStream();
    setState(() {
      _isLiveDetecting = false;
      _isProcessingFrame = false;
    });
  }

  Future<void> _capture() async {
    final cameraProvider = context.read<CameraProvider>();
    if (_isLiveDetecting) _stopLiveDetection();

    final path = await cameraProvider.takePicture();
    if (path != null && mounted) {
      context.push(AppRoutes.crop, extra: path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraProvider>(
        builder: (context, camera, _) {
          if (camera.state == CameraState.uninitialized ||
              camera.state == CameraState.error) {
            return _buildCameraError(camera);
          }

          if (!camera.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(camera.controller!),
              _buildOverlay(camera),
              if (_isLiveDetecting && _livePrediction != null)
                _buildLivePredictionOverlay(),
              _buildTopBar(camera),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraError(CameraProvider camera) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 80),
          const SizedBox(height: 16),
          Text(
            camera.error ?? 'Camera unavailable',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => camera.initialize(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(CameraProvider camera) {
    return CustomPaint(
      painter: _CameraOverlayPainter(),
    );
  }

  Widget _buildLivePredictionOverlay() {
    return Positioned(
      bottom: 150,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE94560).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant, color: Color(0xFFE94560), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _livePrediction!.foodName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Confidence: ${_livePrediction!.confidencePercent}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(CameraProvider camera) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => context.pop(),
              ),
              const Text(
                'Camera',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _CircleButton(
                    icon: camera.isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: () => camera.toggleFlash(),
                  ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    icon: Icons.cameraswitch,
                    onTap: () => camera.switchCamera(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Live detection toggle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isLiveDetecting ? _stopLiveDetection : _startLiveDetection,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLiveDetecting
                          ? const Color(0xFFE94560)
                          : Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                    child: Icon(
                      _isLiveDetecting ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLiveDetecting ? 'Stop' : 'Live',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            // Capture button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, size: 36, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Capture',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            // Placeholder
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    // Draw corners
    final corners = [
      [rect.topLeft, Offset(rect.left + cornerLength, rect.top),
        Offset(rect.left, rect.top + cornerLength)],
      [rect.topRight, Offset(rect.right - cornerLength, rect.top),
        Offset(rect.right, rect.top + cornerLength)],
      [rect.bottomLeft, Offset(rect.left + cornerLength, rect.bottom),
        Offset(rect.left, rect.bottom - cornerLength)],
      [rect.bottomRight, Offset(rect.right - cornerLength, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLength)],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], paint);
      canvas.drawLine(corner[0], corner[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
