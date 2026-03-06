// lib/services/firebase_model_service.dart
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import '../config/app_constants.dart';
import '../utils/logger.dart';

class FirebaseModelService {
  static final FirebaseModelService _instance = FirebaseModelService._internal();
  factory FirebaseModelService() => _instance;
  FirebaseModelService._internal();

  String? _downloadedModelPath;
  bool _isDownloaded = false;

  bool get isDownloaded => _isDownloaded;
  String? get modelPath => _downloadedModelPath;

  /// Download model from Firebase ML
  Future<String?> downloadModel({
    FirebaseModelDownloadConditions? conditions,
    void Function(double)? onProgress,
  }) async {
    try {
      appLogger.i('Starting Firebase ML model download...');

      final downloadConditions = conditions ??
          FirebaseModelDownloadConditions(
            iosAllowsCellularAccess: true,
            iosAllowsBackgroundDownloading: false,
            androidChargingRequired: false,
            androidWifiRequired: false,
            androidDeviceIdleRequired: false,
          );

      final model = await FirebaseModelDownloader.instance.getModel(
        AppConstants.firebaseModelName,
        FirebaseModelDownloadType.latestModel,
        downloadConditions,
      );

      _downloadedModelPath = model.file.path;
      _isDownloaded = true;
      appLogger.i('Firebase ML model downloaded to: $_downloadedModelPath');
      return _downloadedModelPath;
    } catch (e) {
      appLogger.e('Firebase ML download error: $e');
      return null;
    }
  }

  /// Check if a newer model is available
  Future<bool> isUpdateAvailable() async {
    try {
      final localModel = await FirebaseModelDownloader.instance.getModel(
        AppConstants.firebaseModelName,
        FirebaseModelDownloadType.localModel,
        FirebaseModelDownloadConditions(),
      );
      return localModel.file.existsSync();
    } catch (e) {
      appLogger.w('Could not check for model update: $e');
      return false;
    }
  }

  /// Delete cached model
  Future<void> deleteModel() async {
    try {
      await FirebaseModelDownloader.instance.deleteDownloadedModel(
        AppConstants.firebaseModelName,
      );
      _downloadedModelPath = null;
      _isDownloaded = false;
    } catch (e) {
      appLogger.e('Error deleting Firebase ML model: $e');
    }
  }
}
