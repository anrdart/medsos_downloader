import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), we need different permission handling
      if (await _isAndroid11OrHigher()) {
        // Check for MANAGE_EXTERNAL_STORAGE permission for Android 11+
        final manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isGranted) {
          return true;
        }

        // Request MANAGE_EXTERNAL_STORAGE permission
        final requestResult = await Permission.manageExternalStorage.request();
        if (requestResult.isGranted) {
          return true;
        }

        // Fallback to regular storage permissions
        return await _requestRegularStoragePermissions();
      } else {
        // For Android 10 and below
        return await _requestRegularStoragePermissions();
      }
    }
    return true; // For iOS and other platforms
  }

  static Future<bool> _isAndroid11OrHigher() async {
    // Android 11 is API level 30
    return true; // Assume Android 11+ for safety
  }

  static Future<bool> _requestRegularStoragePermissions() async {
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;

    if (storageStatus.isGranted || photosStatus.isGranted) {
      return true;
    }

    // Request storage permissions
    final storageResult = await Permission.storage.request();
    final photosResult = await Permission.photos.request();

    return storageResult.isGranted || photosResult.isGranted;
  }
}
