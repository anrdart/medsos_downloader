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
        // Try to use external storage directory first
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          appDownloadsPath = dir.path;
        } else {
          // Fallback to application documents directory
          final fallbackDir = await getApplicationDocumentsDirectory();
          appDownloadsPath = fallbackDir.path;
        }
      } catch (e) {
        // If external storage is not accessible, use app documents directory
        final fallbackDir = await getApplicationDocumentsDirectory();
        appDownloadsPath = fallbackDir.path;
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      appDownloadsPath = dir.path;
    }
    return appDownloadsPath;
  }

  static Future<void> _createPathIfNotExist(String path) async {
    try {
      if (!await Directory(path).exists()) {
        await Directory(path).create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error creating directory: $e');
      rethrow;
    }
  }

  static Future<void> saveVideoToGallery(videoPath) async {
    try {
      await Gal.putVideo(videoPath, album: 'SocialSaver_downloads');
    } catch (e) {
      debugPrint('Error saving video to gallery: $e');
      rethrow;
    }
  }

  static Future<void> removeFileFromDownloadsDir(videoPath) async {
    try {
      await File(videoPath).delete();
    } catch (e) {
      debugPrint('Error removing file: $e');
      rethrow;
    }
  }

  /// Share the APK file of the current app
  static Future<void> shareAppAPK() async {
    try {
      if (Platform.isAndroid) {
        await _shareAndroidAPKRobust();
      } else {
        // For non-Android platforms, share app info instead
        await _shareAppInfo();
      }
    } catch (e) {
      debugPrint('Error sharing app: $e');
      // Fallback to sharing app info
      await _shareAppInfo();
    }
  }

  static Future<void> _shareAndroidAPKRobust() async {
    try {
      // Get the APK path using a more robust method
      String? apkPath = await _findAPKPath();

      if (apkPath != null && await File(apkPath).exists()) {
        debugPrint('Found APK at: $apkPath');

        // Get app cache directory for temporary copy
        final cacheDir = await getTemporaryDirectory();
        final copiedApkPath = path.join(cacheDir.path, 'ANRSaver.apk');

        // Copy APK to temporary location
        await File(apkPath).copy(copiedApkPath);
        debugPrint('Copied APK to: $copiedApkPath');

        // Verify the copied file exists and has content
        final copiedFile = File(copiedApkPath);
        if (await copiedFile.exists()) {
          final fileSize = await copiedFile.length();
          debugPrint('Copied APK size: $fileSize bytes');

          if (fileSize > 0) {
            // Share the copied APK
            final result = await Share.shareXFiles(
              [
                XFile(copiedApkPath,
                    mimeType: 'application/vnd.android.package-archive')
              ],
              text: '🚀 ANR Saver - Ultimate Video Downloader!\n\n'
                  '📱 Features:\n'
                  '• Download from TikTok, Instagram, YouTube, Facebook, RedNote\n'
                  '• Multiple quality options (HD, Original, Audio-only)\n'
                  '• Save directly to gallery\n'
                  '• Beautiful UI with dark/light theme\n'
                  '• Fast and reliable downloads\n\n'
                  '📲 Install this APK to start downloading your favorite content!',
              subject: 'ANR Saver - Video Downloader App',
            );

            debugPrint('Share result: ${result.raw}');

            // Clean up temporary file after 30 seconds
            Future.delayed(const Duration(seconds: 30), () async {
              try {
                if (await copiedFile.exists()) {
                  await copiedFile.delete();
                  debugPrint('Cleaned up temporary APK file');
                }
              } catch (e) {
                debugPrint('Error cleaning up temporary APK: $e');
              }
            });

            return; // Success, exit early
          }
        }
      }

      // If we reach here, fallback to sharing app info
      debugPrint('APK sharing failed, falling back to app info sharing');
      await _shareAppInfo();
    } catch (e) {
      debugPrint('Error in _shareAndroidAPKRobust: $e');
      await _shareAppInfo();
    }
  }

  static Future<String?> _findAPKPath() async {
    try {
      const packageName = 'com.ekalliptus.anrsaver';

      // Common APK locations for different Android versions
      List<String> possiblePaths = [
        // Android 11+ (API 30+)
        '/data/app/~~*/$packageName-*/base.apk',
        // Android 10 (API 29)
        '/data/app/$packageName-*/base.apk',
        // Older Android versions
        '/data/app/$packageName-1/base.apk',
        '/data/app/$packageName-2/base.apk',
        '/data/app/$packageName/base.apk',
        // System apps
        '/system/app/ANRSaver/base.apk',
        '/system/priv-app/ANRSaver/base.apk',
      ];

      // Try to find APK in application info directory
      try {
        final appDir = await getApplicationSupportDirectory();
        final manifestPath = path.join(appDir.parent.path, 'base.apk');
        if (await File(manifestPath).exists()) {
          possiblePaths.insert(0, manifestPath);
        }
      } catch (e) {
        debugPrint('Could not access application support directory: $e');
      }

      // Check each possible path
      for (String apkPath in possiblePaths) {
        try {
          if (apkPath.contains('*')) {
            // Handle wildcard patterns
            final baseDir = apkPath.split('*')[0];
            final suffix = apkPath.split('*').last;

            final directory = Directory(baseDir);
            if (await directory.exists()) {
              await for (final entity in directory.list()) {
                if (entity is Directory) {
                  final fullPath = path.join(entity.path, suffix.substring(1));
                  if (await File(fullPath).exists()) {
                    debugPrint('Found APK via wildcard: $fullPath');
                    return fullPath;
                  }
                }
              }
            }
          } else {
            if (await File(apkPath).exists()) {
              debugPrint('Found APK at: $apkPath');
              return apkPath;
            }
          }
        } catch (e) {
          // Continue to next path if this one fails
          debugPrint('Failed to check path $apkPath: $e');
          continue;
        }
      }

      debugPrint('No APK found in any of the checked locations');
      return null;
    } catch (e) {
      debugPrint('Error finding APK path: $e');
      return null;
    }
  }

  static Future<void> _shareAppInfo() async {
    await Share.share(
      '🚀 ANR Saver - Ultimate Video Downloader!\n\n'
      '📱 Features:\n'
      '• Download videos from TikTok, Instagram, YouTube, Facebook\n'
      '• Support for RedNote (Xiaohongshu) content\n'
      '• Multiple quality options (HD, Original, etc.)\n'
      '• Audio-only downloads\n'
      '• Save directly to gallery\n'
      '• Dark/Light theme support\n'
      '• Clean and modern interface\n\n'
      '🔗 Get the latest version from our official channels\n'
      '📧 Contact us for support and updates\n\n'
      '#VideoDownloader #ANRSaver #SocialMedia',
      subject: 'ANR Saver - Ultimate Video Downloader',
    );
  }

  /// Alternative method to share app using system sharing without APK
  static Future<void> shareAppSimple() async {
    // Always try to share the APK first
    await shareAppAPK();
  }
}
