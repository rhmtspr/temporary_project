// lib/helpers/image_helper.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../config/app_constants.dart';
import '../utils/logger.dart';

class ImageHelper {
  static Future<Uint8List?> preprocessImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        appLogger.e('Image file not found: $imagePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize to model input size
      final resized = img.copyResize(
        image,
        width: AppConstants.cameraImageSize,
        height: AppConstants.cameraImageSize,
      );

      return imageToByteListFloat32(resized);
    } catch (e) {
      appLogger.e('Error preprocessing image: $e');
      return null;
    }
  }

  static Uint8List imageToByteListFloat32(img.Image image) {
    final size = AppConstants.cameraImageSize;
    final convertedBytes = Float32List(1 * size * size * 3);
    int pixelIndex = 0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes[pixelIndex++] = pixel.r / 255.0;
        convertedBytes[pixelIndex++] = pixel.g / 255.0;
        convertedBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  static Uint8List imageToByteListUint8(img.Image image) {
    final size = AppConstants.cameraImageSize;
    final convertedBytes = Uint8List(1 * size * size * 3);
    int pixelIndex = 0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes[pixelIndex++] = pixel.r.toInt();
        convertedBytes[pixelIndex++] = pixel.g.toInt();
        convertedBytes[pixelIndex++] = pixel.b.toInt();
      }
    }
    return convertedBytes;
  }

  static Future<img.Image?> loadAndResizeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      return img.copyResize(
        image,
        width: AppConstants.cameraImageSize,
        height: AppConstants.cameraImageSize,
      );
    } catch (e) {
      appLogger.e('Error loading image: $e');
      return null;
    }
  }
}
