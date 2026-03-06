// lib/helpers/permission_helper.dart
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    appLogger.i('Camera permission: $status');
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    // For Android 13+, use photos permission
    PermissionStatus status;
    if (await Permission.photos.status.isDenied) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.storage.request();
    }
    appLogger.i('Storage permission: $status');
    return status.isGranted || status.isLimited;
  }

  static Future<bool> requestAllPermissions() async {
    final camera = await requestCameraPermission();
    final storage = await requestStoragePermission();
    return camera && storage;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
