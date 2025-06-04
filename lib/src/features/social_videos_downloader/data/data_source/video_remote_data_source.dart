import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_model.dart';
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
    Function(int received, int total)? onReceiveProgress,
  });
}

class TiktokVideoRemoteDataSource implements VideoBaseRemoteDataSource {
  final DioHelper dioHelper;

  TiktokVideoRemoteDataSource({required this.dioHelper});

  @override
  Future<VideoModel> getVideo(String videoLink) async {
    try {
      final response = await dioHelper.get(
        path: AppConstants.getVideoEndpoint,
        queryParams: {"url": videoLink},
        customHeaders: {
          "x-rapidapi-key": ApiConfig.rapidApiKey,
          "x-rapidapi-host": "social-media-video-downloader.p.rapidapi.com",
        },
      );

      if (response.data != null) {
        return VideoModel.fromJson(response.data);
      } else {
        return VideoModel(
          success: false,
          message: "No data received from server",
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
    } catch (error) {
      developer.log("API error: $error", name: "VideoAPI");
      return VideoModel(
        success: false,
        message: "Failed to fetch video: $error",
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
  }

  @override
  Future<String> saveVideo({
    required String videoLink,
    required String savePath,
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

      // Handle image downloads for RedNote galleries
      if (_isImageUrl(videoLink)) {
        await dioHelper.downloadImage(
          savePath: savePath,
          downloadLink: videoLink,
          onReceiveProgress: onReceiveProgress,
        );
      } else {
        await dioHelper.download(
          savePath: savePath,
          downloadLink: videoLink,
          onReceiveProgress: onReceiveProgress,
        );
      }

      // Verify file was actually downloaded
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

      // Clean up partial download if it exists
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
