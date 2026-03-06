// lib/providers/image_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/permission_helper.dart';
import '../utils/logger.dart';

enum ImageSourceType { camera, gallery }

class AppImageProvider extends ChangeNotifier {
  String? _selectedImagePath;
  bool _isLoading = false;
  String? _error;

  String? get selectedImagePath => _selectedImagePath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasImage => _selectedImagePath != null;

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage(ImageSourceType sourceType) async {
    _setLoading(true);
    _error = null;

    try {
      // Request permissions
      bool hasPermission = false;
      if (sourceType == ImageSourceType.camera) {
        hasPermission = await PermissionHelper.requestCameraPermission();
      } else {
        hasPermission = await PermissionHelper.requestStoragePermission();
      }

      if (!hasPermission) {
        _error = 'Permission denied. Please enable in settings.';
        notifyListeners();
        return null;
      }

      final source = sourceType == ImageSourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (file != null) {
        _selectedImagePath = file.path;
        notifyListeners();
        return file.path;
      }
      return null;
    } catch (e) {
      _error = 'Failed to pick image: $e';
      appLogger.e(_error!);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void setImagePath(String path) {
    _selectedImagePath = path;
    notifyListeners();
  }

  void clearImage() {
    _selectedImagePath = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
