import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

class DirHelper {
  static Future<String> getAppPath() async {
    String mainPath = await _getMainPath();
    String appPath = "$mainPath/SocialSaverVideos";
    await _createPathIfNotExist(appPath);
    return appPath;
  }

  static Future<String> _getMainPath() async {
    String appDownloadsPath = "";
    if (Platform.isAndroid) {
      try {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          appDownloadsPath = dir.path;
        } else {
          final fallbackDir = await getApplicationDocumentsDirectory();
          appDownloadsPath = fallbackDir.path;
        }
      } catch (e) {
        final fallbackDir = await getApplicationDocumentsDirectory();
        appDownloadsPath = fallbackDir.path;
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      appDownloadsPath = dir.path;
    }
    return appDownloadsPath;
  }

  static Future<void> _createPathIfNotExist(String dirPath) async {
    try {
      if (!await Directory(dirPath).exists()) {
        await Directory(dirPath).create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error creating directory: $e');
      rethrow;
    }
  }

  static Future<void> saveMediaToGallery(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception("File not found: $filePath");
    }
    if (file.lengthSync() == 0) {
      throw Exception("File is empty");
    }

    // Request gallery access
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) {
        throw Exception("Gallery permission denied. Please allow access in Settings.");
      }
    }

    final lower = filePath.toLowerCase();
    if (_isImageFile(lower)) {
      await Gal.putImage(filePath, album: 'ANR Saver');
    } else {
      await Gal.putVideo(filePath, album: 'ANR Saver');
    }
  }

  // Keep old name for backward compatibility
  static Future<void> saveVideoToGallery(String videoPath) async {
    await saveMediaToGallery(videoPath);
  }

  static bool _isImageFile(String lowerPath) {
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp') ||
        lowerPath.endsWith('.gif');
  }

  static Future<void> removeFileFromDownloadsDir(String videoPath) async {
    try {
      await File(videoPath).delete();
    } catch (e) {
      debugPrint('Error removing file: $e');
      rethrow;
    }
  }

  static Future<void> shareAppAPK() async {
    try {
      if (Platform.isAndroid) {
        await _shareAndroidAPKRobust();
      } else {
        await _shareAppInfo();
      }
    } catch (e) {
      debugPrint('Error sharing app: $e');
      await _shareAppInfo();
    }
  }

  static Future<void> _shareAndroidAPKRobust() async {
    try {
      String? apkPath = await _findAPKPath();

      if (apkPath != null && await File(apkPath).exists()) {
        final cacheDir = await getTemporaryDirectory();
        final copiedApkPath = path.join(cacheDir.path, 'ANRSaver.apk');

        await File(apkPath).copy(copiedApkPath);

        final copiedFile = File(copiedApkPath);
        if (await copiedFile.exists()) {
          final fileSize = await copiedFile.length();

          if (fileSize > 0) {
            await SharePlus.instance.share(
              ShareParams(
                files: [
                  XFile(copiedApkPath,
                      mimeType: 'application/vnd.android.package-archive')
                ],
                text: 'ANR Saver - Ultimate Video Downloader!\n\n'
                    'Download from TikTok, Instagram, YouTube, Facebook, RedNote\n'
                    'Install this APK to start downloading!',
                subject: 'ANR Saver - Video Downloader App',
              ),
            );

            Future.delayed(const Duration(seconds: 30), () async {
              try {
                if (await copiedFile.exists()) {
                  await copiedFile.delete();
                }
              } catch (_) {}
            });

            return;
          }
        }
      }

      await _shareAppInfo();
    } catch (e) {
      debugPrint('Error in _shareAndroidAPKRobust: $e');
      await _shareAppInfo();
    }
  }

  static Future<String?> _findAPKPath() async {
    try {
      const packageName = 'com.ekalliptus.anrsaver';

      List<String> possiblePaths = [
        '/data/app/~~*/$packageName-*/base.apk',
        '/data/app/$packageName-*/base.apk',
        '/data/app/$packageName-1/base.apk',
        '/data/app/$packageName-2/base.apk',
        '/data/app/$packageName/base.apk',
      ];

      try {
        final appDir = await getApplicationSupportDirectory();
        final manifestPath = path.join(appDir.parent.path, 'base.apk');
        if (await File(manifestPath).exists()) {
          possiblePaths.insert(0, manifestPath);
        }
      } catch (_) {}

      for (String apkPath in possiblePaths) {
        try {
          if (apkPath.contains('*')) {
            final baseDir = apkPath.split('*')[0];
            final suffix = apkPath.split('*').last;

            final directory = Directory(baseDir);
            if (await directory.exists()) {
              await for (final entity in directory.list()) {
                if (entity is Directory) {
                  final fullPath = path.join(entity.path, suffix.substring(1));
                  if (await File(fullPath).exists()) {
                    return fullPath;
                  }
                }
              }
            }
          } else {
            if (await File(apkPath).exists()) {
              return apkPath;
            }
          }
        } catch (_) {
          continue;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding APK path: $e');
      return null;
    }
  }

  static Future<void> _shareAppInfo() async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'ANR Saver - Ultimate Video Downloader!\n\n'
            'Download videos from TikTok, Instagram, YouTube, Facebook, RedNote\n'
            'Multiple quality options, save to gallery, dark/light theme',
        subject: 'ANR Saver - Ultimate Video Downloader',
      ),
    );
  }

  static Future<void> shareAppSimple() async {
    await shareAppAPK();
  }
}
