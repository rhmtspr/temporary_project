// lib/providers/camera_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../helpers/permission_helper.dart';
import '../utils/logger.dart';

enum CameraState { uninitialized, ready, streaming, error, disposed }

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraState _state = CameraState.uninitialized;
  String? _error;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  CameraController? get controller => _controller;
  CameraState get state => _state;
  String? get error => _error;
  bool get isInitialized => _state == CameraState.ready || _state == CameraState.streaming;
  bool get isStreaming => _state == CameraState.streaming;
  bool get isFlashOn => _isFlashOn;
  int get cameraCount => _cameras.length;

  Future<void> initialize() async {
    try {
      final hasPermission = await PermissionHelper.requestCameraPermission();
      if (!hasPermission) {
        _setError('Camera permission denied');
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('No cameras available');
        return;
      }

      await _initCamera(_selectedCameraIndex);
    } catch (e) {
      _setError('Camera initialization failed: $e');
      appLogger.e(_error!);
    }
  }

  Future<void> _initCamera(int index) async {
    await _controller?.dispose();

    _controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      _state = CameraState.ready;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length <= 1) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCamera(_selectedCameraIndex);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !isInitialized) return;
    _isFlashOn = !_isFlashOn;
    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    notifyListeners();
  }

  Future<String?> takePicture() async {
    if (_controller == null || !isInitialized) return null;

    try {
      final file = await _controller!.takePicture();
      return file.path;
    } catch (e) {
      appLogger.e('Error taking picture: $e');
      return null;
    }
  }

  Future<void> startImageStream(void Function(CameraImage) onImage) async {
    if (_controller == null || !isInitialized || isStreaming) return;
    try {
      await _controller!.startImageStream(onImage);
      _state = CameraState.streaming;
      notifyListeners();
    } catch (e) {
      appLogger.e('Error starting stream: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_controller == null || !isStreaming) return;
    try {
      await _controller!.stopImageStream();
      _state = CameraState.ready;
      notifyListeners();
    } catch (e) {
      appLogger.e('Error stopping stream: $e');
    }
  }

  void _setError(String error) {
    _error = error;
    _state = CameraState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _state = CameraState.disposed;
    super.dispose();
  }
}
