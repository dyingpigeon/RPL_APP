// utils/permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  /// Request permission untuk camera dan storage
  static Future<Map<String, bool>> requestPhotoPermissions() async {
    try {
      // Untuk Android 13+ (API 33+)
      if (await _isAndroid13OrAbove()) {
        final photosStatus = await Permission.photos.request();
        final cameraStatus = await Permission.camera.request();

        return {'photos': photosStatus.isGranted, 'camera': cameraStatus.isGranted};
      }
      // Untuk Android < 13
      else {
        final storageStatus = await Permission.storage.request();
        final cameraStatus = await Permission.camera.request();

        return {'storage': storageStatus.isGranted, 'camera': cameraStatus.isGranted};
      }
    } catch (e) {
      print('❌ Permission request error: $e');
      return {'photos': false, 'camera': false, 'storage': false};
    }
  }

  /// Check permissions status
  static Future<Map<String, bool>> checkPhotoPermissions() async {
    try {
      if (await _isAndroid13OrAbove()) {
        final photosStatus = await Permission.photos.status;
        final cameraStatus = await Permission.camera.status;

        return {'photos': photosStatus.isGranted, 'camera': cameraStatus.isGranted};
      } else {
        final storageStatus = await Permission.storage.status;
        final cameraStatus = await Permission.camera.status;

        return {'storage': storageStatus.isGranted, 'camera': cameraStatus.isGranted};
      }
    } catch (e) {
      print('❌ Permission check error: $e');
      return {'photos': false, 'camera': false, 'storage': false};
    }
  }

  /// Check jika Android 13+ (API level 33)
  static Future<bool> _isAndroid13OrAbove() async {
    try {
      // Cek apakah permission photos tersedia (hanya di Android 13+)
      final photosStatus = await Permission.photos.status;
      return true;
    } catch (e) {
      // Jika error, berarti device < Android 13
      return false;
    }
  }

  // ✅ HAPUS METHOD openAppSettings() YANG RECURSIVE
  // Biarkan package permission_handler menangani sendiri
}
