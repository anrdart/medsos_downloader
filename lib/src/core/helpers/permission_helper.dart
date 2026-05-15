import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static int? _sdkVersion;

  static Future<int> _getAndroidSdkVersion() async {
    if (_sdkVersion != null) return _sdkVersion!;
    final info = await DeviceInfoPlugin().androidInfo;
    _sdkVersion = info.version.sdkInt;
    return _sdkVersion!;
  }

  static Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _getAndroidSdkVersion();

    if (sdk >= 33) {
      // Android 13+ : need granular media permissions
      final videoStatus = await Permission.videos.status;
      final photoStatus = await Permission.photos.status;

      if (videoStatus.isGranted && photoStatus.isGranted) return true;

      final results = await [
        Permission.videos,
        Permission.photos,
      ].request();

      return (results[Permission.videos]?.isGranted ?? false) ||
          (results[Permission.photos]?.isGranted ?? false);
    } else if (sdk >= 30) {
      // Android 11-12: MANAGE_EXTERNAL_STORAGE or scoped storage
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) return true;

      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) return true;

      return await _requestLegacyStorage();
    } else {
      // Android 10 and below
      return await _requestLegacyStorage();
    }
  }

  static Future<bool> _requestLegacyStorage() async {
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    return result.isGranted;
  }
}
