import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  Timer? _checkTimer;
  final _updateController = StreamController<UpdateInfo>.broadcast();

  Stream<UpdateInfo> get updateStream => _updateController.stream;

  Future<void> initialize() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await config.setDefaults({
        'latest_version_name': '1.3.0',
        'latest_version_code': 3,
        'download_url': '',
        'changelog': '',
        'is_forced': false,
      });
      await config.fetchAndActivate();
      developer.log('Firebase Remote Config initialized', name: 'UpdateService');
    } catch (e) {
      developer.log('Remote Config init failed: $e', name: 'UpdateService');
    }
  }

  void startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      checkForUpdate();
    });
    // Initial check after 5 seconds
    Future.delayed(const Duration(seconds: 5), checkForUpdate);
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final config = FirebaseRemoteConfig.instance;
      await config.fetchAndActivate();

      final latestVersionCode = config.getInt('latest_version_code');
      final latestVersionName = config.getString('latest_version_name');
      final downloadUrl = config.getString('download_url');
      final changelog = config.getString('changelog');
      final isForced = config.getBool('is_forced');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (latestVersionCode > currentCode && downloadUrl.isNotEmpty) {
        final info = UpdateInfo(
          versionName: latestVersionName,
          versionCode: latestVersionCode,
          currentVersionCode: currentCode,
          currentVersionName: packageInfo.version,
          downloadUrl: downloadUrl,
          changelog: changelog,
          isForced: isForced,
        );
        _updateController.add(info);
        developer.log('Update available: $latestVersionName', name: 'UpdateService');
        return info;
      }
    } catch (e) {
      developer.log('Update check failed: $e', name: 'UpdateService');
    }
    return null;
  }

  Future<String?> downloadUpdate(String url, {Function(double)? onProgress}) async {
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/anr_saver_update.apk';

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return savePath;
    } catch (e) {
      developer.log('Download update failed: $e', name: 'UpdateService');
      return null;
    }
  }

  Future<bool> installUpdate(String apkPath) async {
    try {
      if (Platform.isAndroid) {
        await OpenFile.open(apkPath);
        return true;
      }
    } catch (e) {
      developer.log('Install update failed: $e', name: 'UpdateService');
    }
    return false;
  }

  void dispose() {
    _checkTimer?.cancel();
    _updateController.close();
  }
}

class UpdateInfo {
  final String versionName;
  final int versionCode;
  final int currentVersionCode;
  final String currentVersionName;
  final String downloadUrl;
  final String changelog;
  final bool isForced;

  UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.currentVersionCode,
    required this.currentVersionName,
    required this.downloadUrl,
    this.changelog = '',
    this.isForced = false,
  });

  bool get isNewerVersion => versionCode > currentVersionCode;
}

enum UpdateStatus { idle, checking, available, downloading, installing, error }
