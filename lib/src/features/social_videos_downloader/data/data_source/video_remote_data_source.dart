import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_model.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'dart:io';

import '../../../../core/helpers/dio_helper.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/api_config.dart';

abstract class VideoBaseRemoteDataSource {
  Future<VideoModel> getVideo(String videoLink);

  Future<String> saveVideo({
    required String videoLink,
    required String savePath,
    CancelToken? cancelToken,
    Function(int received, int total)? onReceiveProgress,
  });
}

class TiktokVideoRemoteDataSource implements VideoBaseRemoteDataSource {
  final DioHelper dioHelper;

  TiktokVideoRemoteDataSource({required this.dioHelper});

  @override
  Future<VideoModel> getVideo(String videoLink) async {
    // Try Cobalt instances
    for (final instance in ApiConfig.cobaltInstances) {
      try {
        final result = await _tryGetVideoFromCobalt(instance, videoLink);
        if (result.success && result.videoLinks.isNotEmpty) {
          developer.log("Success via Cobalt: $instance", name: "VideoAPI");
          return result;
        }
      } catch (e) {
        developer.log("Cobalt instance $instance failed: $e", name: "VideoAPI");
      }
    }

    // yt-dlp fallback for ALL platforms (strongest extractor; works for
    // TikTok/IG/Twitter/etc. when Cobalt fails on datacenter IPs).
    try {
      final result = await _tryGetVideoFromYtdlp(videoLink);
      if (result.success && result.videoLinks.isNotEmpty) {
        developer.log("Success via yt-dlp fallback", name: "VideoAPI");
        return result;
      }
    } catch (e) {
      developer.log("yt-dlp fallback failed: $e", name: "VideoAPI");
    }

    // TikWM fallback for TikTok/Douyin
    if (ApiConfig.useTikwmFallback && _isTikTokUrl(videoLink)) {
      try {
        final result = await _tryGetVideoFromTikwm(videoLink);
        if (result.success && result.videoLinks.isNotEmpty) {
          developer.log("Success via TikWM fallback", name: "VideoAPI");
          return result;
        }
      } catch (e) {
        developer.log("TikWM fallback failed: $e", name: "VideoAPI");
      }
    }

    return VideoModel(
      success: false,
      message: ApiConfig.allApisFailed,
      srcUrl: videoLink,
      ogUrl: "",
      title: "Download Failed",
      picture: "",
      images: const [],
      timeTaken: DateTime.now().toString(),
      rId: DateTime.now().millisecondsSinceEpoch.toString(),
      videoLinks: const [],
    );
  }

  Future<VideoModel> _tryGetVideoFromCobalt(
      String instanceUrl, String videoLink) async {
    final headers = <String, dynamic>{
      "Accept": "application/json",
      "Content-Type": "application/json",
    };

    if (ApiConfig.cobaltApiKey != null) {
      headers["Authorization"] = "Api-Key ${ApiConfig.cobaltApiKey}";
    }

    // Try with configured quality first, then fallback to lower qualities
    final qualities = [ApiConfig.videoQuality, "720", "480", "360"];
    final tried = <String>{};

    for (final quality in qualities) {
      if (tried.contains(quality)) continue;
      tried.add(quality);

      final response = await dioHelper.post(
        path: AppConstants.cobaltEndpoint,
        baseUrl: instanceUrl,
        customHeaders: headers,
        // Short connect timeout: skip dead instances fast in the fallback chain
        connectTimeout:
            const Duration(seconds: ApiConfig.cobaltConnectTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: ApiConfig.cobaltReceiveTimeoutSeconds),
        data: {
          "url": videoLink,
          "videoQuality": quality,
          "filenameStyle": "basic",
          "downloadMode": "auto",
        },
      );

      if (response.data == null) continue;

      final data = response.data as Map<String, dynamic>;
      final status = data["status"] as String?;

      if (status == "error") {
        final error = data["error"];
        final code = error is Map ? error["code"]?.toString() : error?.toString();
        // YouTube login required - won't help to retry with lower quality
        if (code != null && code.contains("youtube.login")) {
          throw Exception(
              "Video ini membutuhkan autentikasi YouTube di server. "
              "Hubungi admin server Cobalt untuk konfigurasi cookies YouTube.");
        }
        // Link invalid
        if (code != null && code.contains("link.invalid")) {
          throw Exception("Link tidak valid atau tidak didukung.");
        }
        // Fetch empty - content not accessible
        if (code != null && code.contains("fetch.empty")) {
          throw Exception(
              "Tidak bisa mengakses konten. Video mungkin private, "
              "dihapus, atau platform membutuhkan cookies di server.");
        }
        throw Exception("Cobalt error: $code");
      }

      // For tunnel/redirect: verify the URL is valid before returning
      if (status == "tunnel" || status == "redirect") {
        final tunnelUrl = data["url"] as String? ?? "";
        if (tunnelUrl.isNotEmpty) {
          final isValid = await _validateTunnelUrl(tunnelUrl);
          if (isValid) {
            return VideoModel.fromCobalt(data, videoLink);
          }
          developer.log("Tunnel invalid at $quality, trying lower", name: "VideoAPI");
          continue;
        }
      }

      // Picker status (galleries) - no need to validate
      if (status == "picker") {
        return VideoModel.fromCobalt(data, videoLink);
      }
    }

    throw Exception(
        "Server tidak bisa memproses video ini. "
        "Coba video lain atau hubungi admin server.");
  }

  /// HEAD check tunnel URL to verify it will return actual data
  Future<bool> _validateTunnelUrl(String tunnelUrl) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);

      final response = await dio.head(tunnelUrl);
      if (response.statusCode != 200) return false;

      final estimated = response.headers.value('estimated-content-length');
      final contentLength = response.headers.value('content-length');

      // If Content-Length is present and > 0, it's valid
      if (contentLength != null) {
        final size = int.tryParse(contentLength) ?? 0;
        return size > 0;
      }

      // If Estimated-Content-Length is -1, Cobalt can't process this video
      if (estimated != null) {
        final size = int.tryParse(estimated) ?? -1;
        return size > 0;
      }

      // No size headers at all - assume it works (chunked streaming)
      return true;
    } catch (e) {
      developer.log("Tunnel validation failed: $e", name: "VideoAPI");
      return false;
    }
  }

  Future<VideoModel> _tryGetVideoFromTikwm(String videoLink) async {
    final response = await dioHelper.get(
      path: AppConstants.tikwmEndpoint,
      baseUrl: AppConstants.tikwmBaseUrl,
      queryParams: {"url": videoLink, "hd": "1"},
      customHeaders: {
        "Accept": "application/json",
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      },
    );

    if (response.data == null) {
      throw Exception("Empty response from TikWM");
    }

    final data = response.data as Map<String, dynamic>;
    if (data["code"] != 0 && data["code"] != "0") {
      throw Exception("TikWM error: ${data["msg"]}");
    }

    return VideoModel.fromTikwm(data, videoLink);
  }

  bool _isTikTokUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains("tiktok.com") ||
        lower.contains("douyin.com") ||
        lower.contains("v.douyin.com");
  }

  Future<VideoModel> _tryGetVideoFromYtdlp(String videoLink) async {
    final baseUrl = ApiConfig.ytdlpApiUrl;
    final apiKey = ApiConfig.ytdlpApiKey;

    final response = await dioHelper.post(
      path: "/download",
      baseUrl: baseUrl,
      customHeaders: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-Api-Key": apiKey,
      },
      data: {
        "url": videoLink,
        "quality": ApiConfig.videoQuality,
      },
    );

    if (response.data == null) {
      throw Exception("Empty response from yt-dlp API");
    }

    final data = response.data as Map<String, dynamic>;
    final status = data["status"] as String?;

    if (status == "error" || status == null) {
      throw Exception("yt-dlp error: ${data["detail"] ?? "unknown"}");
    }

    return VideoModel.fromYtdlp(data, videoLink, baseUrl);
  }

  @override
  Future<String> saveVideo({
    required String videoLink,
    required String savePath,
    CancelToken? cancelToken,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      if (videoLink.isEmpty) {
        throw Exception("Video link cannot be empty");
      }

      if (savePath.isEmpty) {
        throw Exception("Save path cannot be empty");
      }

      developer.log("Starting download: $videoLink to $savePath",
          name: "DownloadService");

      if (_isImageUrl(videoLink)) {
        await dioHelper.downloadImage(
          savePath: savePath,
          downloadLink: videoLink,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
      } else {
        await dioHelper.download(
          savePath: savePath,
          downloadLink: videoLink,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
      }

      final file = File(savePath);
      if (!file.existsSync()) {
        throw Exception("Download failed: File was not created");
      }

      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        await file.delete();
        throw Exception("Download failed: File is empty");
      }

      developer.log("Download completed successfully: $fileSize bytes",
          name: "DownloadService");
      return AppStrings.downloadSuccess;
    } catch (error) {
      developer.log("Download error: $error", name: "DownloadService");

      try {
        final file = File(savePath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (cleanupError) {
        developer.log("Failed to cleanup: $cleanupError",
            name: "DownloadService");
      }

      rethrow;
    }
  }

  bool _isImageUrl(String url) {
    return url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.webp');
  }
}
