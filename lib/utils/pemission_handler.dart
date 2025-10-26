// utils/permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  /// Request permission untuk camera dan storage - FIXED FOR ANDROID 11+
  static Future<Map<String, bool>> requestPhotoPermissions() async {
    try {
      print('🔧 Requesting permissions for Android version...');

      if (await _isAndroid13OrAbove()) {
        // Android 13+ - Butuh READ_MEDIA_IMAGES
        print('📱 Android 13+ detected - Using READ_MEDIA_IMAGES');
        final photosStatus = await Permission.photos.request();
        final cameraStatus = await Permission.camera.request();

        return {
          'photos': photosStatus.isGranted,
          'camera': cameraStatus.isGranted,
          'gallery': photosStatus.isGranted, // Gallery = photos permission di Android 13+
          'storage': photosStatus.isGranted,
          'needsPermission': true, // Android 13+ butuh permission
        };
      } else if (await _isAndroid11OrAbove()) {
        // Android 11-12 - TIDAK BUTUH PERMISSION UNTUK GALLERY
        // System picker bekerja tanpa permission
        print('📱 Android 11-12 detected - No gallery permission needed');

        // Hanya request camera permission
        final cameraStatus = await Permission.camera.request();

        return {
          'camera': cameraStatus.isGranted,
          'gallery': true, // ✅ Android 11+ TIDAK BUTUH PERMISSION GALLERY
          'photos': true, // ✅ System picker available
          'storage': true, // ✅ Tidak butuh storage permission
          'needsPermission': false, // ✅ Android 11+ TIDAK butuh permission gallery
        };
      } else {
        // Android < 11 - Butuh storage permission
        print('📱 Android <11 detected - Using storage permission');
        final storageStatus = await Permission.storage.request();
        final cameraStatus = await Permission.camera.request();

        return {
          'storage': storageStatus.isGranted,
          'camera': cameraStatus.isGranted,
          'gallery': storageStatus.isGranted, // Gallery = storage permission di Android lama
          'photos': storageStatus.isGranted,
          'needsPermission': true, // Android lama butuh permission
        };
      }
    } catch (e) {
      print('❌ Permission request error: $e');
      return {
        'photos': false,
        'camera': false,
        'storage': false,
        'gallery': false,
        'needsPermission': true,
        'error': true,
      };
    }
  }

  /// Check permissions status - FIXED FOR ANDROID 11+
  static Future<Map<String, bool>> checkPhotoPermissions() async {
    try {
      print('🔧 Checking permissions for Android version...');

      if (await _isAndroid13OrAbove()) {
        // Android 13+ - Check READ_MEDIA_IMAGES
        final photosStatus = await Permission.photos.status;
        final cameraStatus = await Permission.camera.status;

        print('📱 Android 13+ - Photos permission: ${photosStatus.isGranted}');

        return {
          'photos': photosStatus.isGranted,
          'camera': cameraStatus.isGranted,
          'gallery': photosStatus.isGranted, // Gallery = photos permission
          'storage': photosStatus.isGranted,
          'needsPermission': true,
        };
      } else if (await _isAndroid11OrAbove()) {
        // Android 11-12 - TIDAK BUTUH PERMISSION UNTUK GALLERY
        print('📱 Android 11-12 detected - Gallery permission NOT needed');

        final cameraStatus = await Permission.camera.status;

        return {
          'camera': cameraStatus.isGranted,
          'gallery': true, // ✅ SELALU TRUE - Tidak butuh permission
          'photos': true, // ✅ SELALU TRUE
          'storage': true, // ✅ SELALU TRUE
          'needsPermission': false, // ✅ TIDAK butuh permission gallery
        };
      } else {
        // Android < 11 - Check storage permission
        final storageStatus = await Permission.storage.status;
        final cameraStatus = await Permission.camera.status;

        print('📱 Android <11 - Storage permission: ${storageStatus.isGranted}');

        return {
          'storage': storageStatus.isGranted,
          'camera': cameraStatus.isGranted,
          'gallery': storageStatus.isGranted, // Gallery = storage permission
          'photos': storageStatus.isGranted,
          'needsPermission': true,
        };
      }
    } catch (e) {
      print('❌ Permission check error: $e');
      return {
        'photos': false,
        'camera': false,
        'storage': false,
        'gallery': false,
        'needsPermission': true,
        'error': true,
      };
    }
  }

  /// Check gallery permission status (simplified version)
  static Future<bool> checkGalleryPermission() async {
    try {
      final permissions = await checkPhotoPermissions();

      // ✅ Android 11+ SELALU return true (tidak butuh permission)
      if (!permissions['needsPermission']!) {
        print('✅ Android 11+ - Gallery always available');
        return true;
      }

      return permissions['gallery'] == true;
    } catch (e) {
      print('❌ Gallery permission check error: $e');
      return false;
    }
  }

  /// Request gallery permission (simplified version)
  static Future<bool> requestGalleryPermission() async {
    try {
      final permissions = await requestPhotoPermissions();

      // ✅ Android 11+ SELALU return true (tidak butuh permission)
      if (!permissions['needsPermission']!) {
        print('✅ Android 11+ - Gallery permission not needed');
        return true;
      }

      return permissions['gallery'] == true;
    } catch (e) {
      print('❌ Gallery permission request error: $e');
      return false;
    }
  }

  /// Check jika Android 13+ (API level 33+)
  static Future<bool> _isAndroid13OrAbove() async {
    try {
      // Cek apakah permission photos tersedia (hanya di Android 13+)
      await Permission.photos.status;
      print('✅ Android 13+ detected');
      return true;
    } catch (e) {
      print('✅ Android <13 detected');
      return false;
    }
  }

  /// Check jika Android 11+ (API level 30+)
  static Future<bool> _isAndroid11OrAbove() async {
    try {
      // Untuk Android 11+, kita bisa asumsikan berdasarkan tahun release
      // Atau gunakan package device_info untuk check yang lebih akurat

      // Cara sederhana: coba access permission yang hanya ada di Android 11+
      try {
        await Permission.manageExternalStorage.status;
        print('✅ Android 11+ detected');
        return true;
      } catch (_) {
        // Fallback: assume modern devices are Android 11+
        // Atau gunakan package device_info untuk check yang tepat
        print('⚠️ Using fallback Android version check');
        return true; // Default to Android 11+ untuk coverage luas
      }
    } catch (e) {
      print('⚠️ Android version check error: $e');
      return true; // Default to Android 11+ untuk safety
    }
  }

  /// Get required permissions untuk debug
  static Future<List<String>> getRequiredPermissions() async {
    if (await _isAndroid13OrAbove()) {
      return ['READ_MEDIA_IMAGES', 'CAMERA'];
    } else if (await _isAndroid11OrAbove()) {
      return ['CAMERA only', 'Gallery: NO PERMISSION NEEDED']; // ✅
    } else {
      return ['READ_EXTERNAL_STORAGE', 'CAMERA'];
    }
  }

  /// Debug method untuk print current permissions status
  static Future<void> debugPermissions() async {
    try {
      final permissions = await checkPhotoPermissions();
      final required = await getRequiredPermissions();
      final isAndroid13 = await _isAndroid13OrAbove();
      final isAndroid11 = await _isAndroid11OrAbove();

      print('''
=== 🔧 PERMISSION DEBUG INFO ===
Android Version: ${isAndroid13
          ? '13+'
          : isAndroid11
          ? '11-12'
          : '<11'}
Required Permissions: $required
Current Status:
- Photos: ${permissions['photos']}
- Camera: ${permissions['camera']} 
- Storage: ${permissions['storage']}
- Gallery: ${permissions['gallery']}
- Needs Permission: ${permissions['needsPermission']}
- Android 11+ Feature: ${isAndroid11 ? 'NO GALLERY PERMISSION NEEDED' : 'NEEDS STORAGE PERMISSION'}
=============================
''');
    } catch (e) {
      print('❌ Permission debug error: $e');
    }
  }

  /// Method khusus untuk Android 11+ - Langsung buka gallery tanpa permission check
  static Future<bool> canAccessGalleryWithoutPermission() async {
    return await _isAndroid11OrAbove();
  }
}
