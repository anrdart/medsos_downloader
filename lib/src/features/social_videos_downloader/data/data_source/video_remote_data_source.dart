import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_model.dart';
import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_link_model.dart';
import 'dart:developer' as developer;

import '../../../../core/helpers/dio_helper.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/api_config.dart';
import 'package:dio/dio.dart';

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
    VideoModel? result;
    Exception? lastError;

    // Retry logic for better success rate
    for (int attempt = 1; attempt <= ApiConfig.maxRetryAttempts; attempt++) {
      try {
        developer.log(
            "Attempt $attempt/${ApiConfig.maxRetryAttempts} for URL: $videoLink",
            name: "VideoAPI");

        // Clean and normalize URL first
        videoLink = _normalizeUrl(videoLink);
        developer.log("Processing URL: $videoLink", name: "VideoAPI");

        // RedNote handling with enhanced support
        if (_isRedNoteUrl(videoLink)) {
          developer.log("Detected RedNote URL: $videoLink", name: "RedNoteAPI");
          videoLink = _extractRedNoteUrl(videoLink);
          developer.log("Cleaned RedNote URL: $videoLink", name: "RedNoteAPI");
          result = await _handleRedNoteUrl(videoLink);
          if (result.success == true) return result;
        }

        // Facebook handling with dedicated support and fallbacks
        if (_isFacebookUrl(videoLink)) {
          developer.log("Detected Facebook URL: $videoLink",
              name: "FacebookAPI");

          // Try alternative Facebook API first
          if (ApiConfig.shouldUseAlternativeFacebookAPI) {
            try {
              result = await _tryAlternativeFacebookAPI(videoLink);
              if (result?.success == true) return result!;
            } catch (e) {
              developer.log("Alternative Facebook API failed: $e",
                  name: "FacebookAPI");
              lastError = e is Exception ? e : Exception(e.toString());

              // If 429 (rate limiting), wait before retry
              if (_isRateLimitError(lastError)) {
                developer.log("Rate limit detected, waiting before retry...",
                    name: "FacebookAPI");
                await Future.delayed(Duration(seconds: 2 * attempt));
              }

              // If 403 (forbidden), skip this API entirely
              if (_isAPI403Error(lastError)) {
                developer.log("403 error detected, skipping Facebook API",
                    name: "FacebookAPI");
                break; // Skip to next platform or universal fallback
              }
            }
          }

          // Try main Facebook handler only if not 403 error
          if (!_isAPI403Error(lastError)) {
            try {
              result = await _handleFacebookUrl(videoLink);
              if (result?.success == true) return result!;
            } catch (e) {
              developer.log("Main Facebook handler failed: $e",
                  name: "FacebookAPI");
              lastError = e is Exception ? e : Exception(e.toString());
            }
          }
        }

        // TikTok/Douyin handling with enhanced API
        if (_isTikTokUrl(videoLink)) {
          developer.log("Detected TikTok/Douyin URL: $videoLink",
              name: "TikTokAPI");

          // If preferBackupAPIs is enabled, try backup API first
          if (ApiConfig.shouldPreferBackupAPIs) {
            try {
              result = await _tryDouyinBackupAPI(videoLink);
              if (result?.success == true) {
                developer.log(
                    "✅ Backup Douyin API successful - stopping other attempts",
                    name: "DouyinAPI");
                return result!;
              }
            } catch (backupError) {
              developer.log("Backup Douyin API failed: $backupError",
                  name: "DouyinAPI");
              lastError = backupError is Exception
                  ? backupError
                  : Exception(backupError.toString());
            }
          }

          // Try enhanced main API with TikTok-specific headers
          try {
            result = await _tryMainAPIWithTikTokHeaders(videoLink);
            if (result?.success == true) return result!;
          } catch (mainError) {
            developer.log("Main API with TikTok headers failed: $mainError",
                name: "TikTokAPI");
            lastError = mainError is Exception
                ? mainError
                : Exception(mainError.toString());
          }

          // Try Douyin-specific API if enabled and not a 403 error
          if (ApiConfig.shouldUseDouyinApi &&
              (!ApiConfig.shouldSkipFailedAPIs || !_isAPI403Error(lastError))) {
            try {
              result = await _tryDouyinAPI(videoLink);
              if (result?.success == true) return result!;
            } catch (douyinError) {
              developer.log(
                  "Douyin API failed, will continue with fallbacks: $douyinError",
                  name: "DouyinAPI");
              lastError = douyinError is Exception
                  ? douyinError
                  : Exception(douyinError.toString());
            }
          }
        }

        // Instagram handling with enhanced support and fallbacks
        if (_isInstagramUrl(videoLink)) {
          developer.log("Detected Instagram URL: $videoLink",
              name: "InstagramAPI");

          // Try alternative Instagram API first
          if (ApiConfig.shouldUseAlternativeInstagramAPI) {
            try {
              result = await _tryAlternativeInstagramAPI(videoLink);
              if (result?.success == true) return result!;
            } catch (e) {
              developer.log("Alternative Instagram API failed: $e",
                  name: "InstagramAPI");
              lastError = e is Exception ? e : Exception(e.toString());
            }
          }

          // Try main Instagram handler
          try {
            result = await _handleInstagramUrl(videoLink);
            if (result?.success == true) return result!;
          } catch (e) {
            developer.log("Main Instagram handler failed: $e",
                name: "InstagramAPI");
            lastError = e is Exception ? e : Exception(e.toString());
          }
        }

        // Universal downloader fallback
        if (ApiConfig.shouldUseUniversalFallback) {
          try {
            result = await _tryUniversalDownloader(videoLink);
            if (result?.success == true) return result!;
          } catch (e) {
            developer.log("Universal downloader failed: $e",
                name: "UniversalAPI");
            lastError = e is Exception ? e : Exception(e.toString());
          }
        }

        // Main API fallback for all platforms
        if (!_isAPI403Error(lastError)) {
          // Skip if previous 403 error
          developer.log("Using main API for URL: $videoLink", name: "VideoAPI");
          try {
            final response = await dioHelper.get(
              path: AppConstants.getVideoEndpoint,
              queryParams: {"url": videoLink},
              customHeaders: {
                "x-rapidapi-key": ApiConfig.rapidApiKey,
                "x-rapidapi-host":
                    "social-media-video-downloader.p.rapidapi.com",
              },
            );

            developer.log("Main API Response: ${response.data}",
                name: "VideoAPI");

            // Enhanced response parsing
            if (response.data != null) {
              result = VideoModel.fromJson(response.data);
              if (result.success == true) return result;
            }
          } catch (mainApiError) {
            lastError = mainApiError is Exception
                ? mainApiError
                : Exception(mainApiError.toString());
            developer.log("Main API failed: $lastError", name: "VideoAPI");
          }
        }
      } catch (error) {
        lastError = error is Exception ? error : Exception(error.toString());
        developer.log("Attempt $attempt failed: $error", name: "VideoAPI");

        // Handle rate limiting with exponential backoff
        if (_isRateLimitError(lastError) &&
            attempt < ApiConfig.maxRetryAttempts) {
          int waitTime = (ApiConfig.retryDelaySeconds *
              attempt *
              attempt); // Exponential backoff
          developer.log(
              "Rate limit detected, waiting ${waitTime}s before retry...",
              name: "VideoAPI");
          await Future.delayed(Duration(seconds: waitTime));
          continue;
        }

        // For other errors, wait normal delay
        if (attempt < ApiConfig.maxRetryAttempts) {
          await Future.delayed(const Duration(seconds: ApiConfig.retryDelaySeconds));
        }
      }
    }

    // All attempts failed, return error response
    developer.log("All attempts failed for URL: $videoLink", name: "VideoAPI");
    return VideoModel(
      success: false,
      message: _getErrorMessage(lastError, videoLink),
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

  String _getErrorMessage(Exception? error, String url) {
    if (error == null) {
      return "Failed to fetch video after ${ApiConfig.maxRetryAttempts} attempts";
    }

    String errorString = error.toString().toLowerCase();

    if (errorString.contains('403') || errorString.contains('not subscribed')) {
      return "API subscription required. Please check your API keys in settings.";
    } else if (errorString.contains('429') ||
        errorString.contains('too many requests')) {
      return "Rate limit exceeded. Please wait a moment and try again.";
    } else if (errorString.contains('404') ||
        errorString.contains("doesn't exist")) {
      return "Video not found or API service unavailable.";
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return "Network connection error. Please check your internet connection.";
    } else if (_isFacebookUrl(url)) {
      return "Facebook video download temporarily unavailable. Please try again later.";
    } else if (_isTikTokUrl(url)) {
      return "TikTok video download temporarily unavailable. Please try again later.";
    } else if (_isInstagramUrl(url)) {
      return "Instagram video download temporarily unavailable. Please try again later.";
    } else {
      return "Unable to download video. The content may be private or restricted.";
    }
  }

  bool _isRateLimitError(Exception? error) {
    if (error == null) return false;
    String errorString = error.toString().toLowerCase();
    return errorString.contains('429') ||
        errorString.contains('too many requests') ||
        errorString.contains('rate limit');
  }

  String _normalizeUrl(String url) {
    // Remove common tracking parameters and normalize URL
    url = url.trim();

    // Remove common tracking parameters
    final trackingParams = [
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'fbclid',
      'igshid'
    ];
    Uri uri = Uri.parse(url);

    Map<String, String> cleanParams = Map.from(uri.queryParameters);
    for (String param in trackingParams) {
      cleanParams.remove(param);
    }

    // Rebuild URL without tracking parameters
    Uri cleanUri =
        uri.replace(queryParameters: cleanParams.isEmpty ? null : cleanParams);
    String cleanUrl = cleanUri.toString();

    developer.log("Normalized URL: $url -> $cleanUrl", name: "URLNormalizer");
    return cleanUrl;
  }


  Future<VideoModel?> _handleFacebookUrl(String videoLink) async {
    try {
      developer.log("Processing Facebook URL: $videoLink", name: "FacebookAPI");

      // Clean Facebook URL
      String cleanUrl = _cleanFacebookUrl(videoLink);
      developer.log("Cleaned Facebook URL: $cleanUrl", name: "FacebookAPI");

      // Try main API with enhanced headers for Facebook
      final response = await dioHelper.get(
        path: AppConstants.getVideoEndpoint,
        queryParams: {"url": cleanUrl},
        customHeaders: {
          "x-rapidapi-key": ApiConfig.rapidApiKey,
          "x-rapidapi-host": "social-media-video-downloader.p.rapidapi.com",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        },
      );

      developer.log("Facebook API Response: ${response.data}",
          name: "FacebookAPI");

      if (response.data != null && response.data['success'] == true) {
        var videoData = response.data;
        List<VideoLinkModel> videoLinks = [];

        // Enhanced parsing for Facebook content
        if (videoData['links'] != null && videoData['links'] is List) {
          var links = videoData['links'] as List;
          for (var link in links) {
            if (link['link'] != null && link['quality'] != null) {
              videoLinks.add(VideoLinkModel(
                quality: _formatQualityName("Facebook ${link['quality']}"),
                link: link['link'].toString(),
              ));
            }
          }
        }

        // Check for direct video URL
        if (videoData['video_url'] != null) {
          videoLinks.add(VideoLinkModel(
            quality: _formatQualityName("Facebook Video"),
            link: videoData['video_url'].toString(),
          ));
        }

        // Check for different quality options
        for (var quality in ['video_hd', 'video_sd', 'video_low']) {
          if (videoData[quality] != null) {
            videoLinks.add(VideoLinkModel(
              quality: _formatQualityName(
                  "Facebook ${quality.replaceAll('video_', '').toUpperCase()}"),
              link: videoData[quality].toString(),
            ));
          }
        }

        if (videoLinks.isNotEmpty) {
          return VideoModel(
            success: true,
            message: "Facebook content extracted successfully",
            srcUrl: cleanUrl,
            ogUrl: videoData['og_url']?.toString() ?? cleanUrl,
            title: videoData['title']?.toString() ?? "Facebook Video",
            picture: videoData['thumbnail']?.toString() ??
                videoData['picture']?.toString() ??
                "",
            images: videoData['images'] != null
                ? List<String>.from(videoData['images'])
                : [],
            timeTaken: DateTime.now().toString(),
            rId: _extractFacebookId(cleanUrl) ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            videoLinks: videoLinks,
          );
        }
      }

      // Return the original response if successful but no enhanced parsing
      return VideoModel.fromJson(response.data);
    } catch (error) {
      developer.log("Error handling Facebook URL: $error", name: "FacebookAPI");
      return null;
    }
  }

  String _cleanFacebookUrl(String url) {
    developer.log("Original Facebook URL: $url", name: "FacebookParser");

    // Pattern 1: Facebook video posts
    RegExp videoPattern =
        RegExp(r'https://www\.facebook\.com/[^/]+/videos/([0-9]+)/?');
    Match? videoMatch = videoPattern.firstMatch(url);

    if (videoMatch != null) {
      String cleanUrl =
          "https://www.facebook.com/video.php?v=${videoMatch.group(1)}";
      developer.log("Cleaned Facebook video URL: $cleanUrl",
          name: "FacebookParser");
      return cleanUrl;
    }

    // Pattern 2: fb.watch short URLs
    RegExp fbWatchPattern = RegExp(r'https://fb\.watch/([a-zA-Z0-9_-]+)/?');
    Match? fbWatchMatch = fbWatchPattern.firstMatch(url);

    if (fbWatchMatch != null) {
      String cleanUrl = "https://fb.watch/${fbWatchMatch.group(1)}/";
      developer.log("Cleaned fb.watch URL: $cleanUrl", name: "FacebookParser");
      return cleanUrl;
    }

    // Pattern 3: Facebook story URLs
    RegExp storyPattern =
        RegExp(r'https://www\.facebook\.com/stories/([0-9]+)/([0-9]+)/?');
    Match? storyMatch = storyPattern.firstMatch(url);

    if (storyMatch != null) {
      String cleanUrl =
          "https://www.facebook.com/stories/${storyMatch.group(1)}/${storyMatch.group(2)}/";
      developer.log("Cleaned Facebook story URL: $cleanUrl",
          name: "FacebookParser");
      return cleanUrl;
    }

    // Remove Facebook tracking parameters
    if (url.contains('?')) {
      List<String> parts = url.split('?');
      String baseUrl = parts[0];
      if (parts.length > 1) {
        List<String> params = parts[1].split('&');
        List<String> cleanParams = params
            .where((param) =>
                !param.startsWith('__tn__') &&
                !param.startsWith('__cft__') &&
                !param.startsWith('__xts__'))
            .toList();

        if (cleanParams.isNotEmpty) {
          String cleanUrl = '$baseUrl?${cleanParams.join('&')}';
          developer.log("Cleaned Facebook URL (removed tracking): $cleanUrl",
              name: "FacebookParser");
          return cleanUrl;
        } else {
          developer.log("Cleaned Facebook URL (removed all params): $baseUrl",
              name: "FacebookParser");
          return baseUrl;
        }
      }
    }

    developer.log("No cleaning needed for Facebook URL",
        name: "FacebookParser");
    return url;
  }

  String? _extractFacebookId(String url) {
    try {
      // Extract Facebook content ID
      RegExp videoIdPattern = RegExp(r'/videos/([0-9]+)');
      Match? videoMatch = videoIdPattern.firstMatch(url);

      if (videoMatch != null) {
        String videoId = videoMatch.group(1)!;
        developer.log("Extracted Facebook video ID: $videoId",
            name: "FacebookParser");
        return videoId;
      }

      // For fb.watch URLs
      RegExp fbWatchPattern = RegExp(r'fb\.watch/([a-zA-Z0-9_-]+)');
      Match? fbWatchMatch = fbWatchPattern.firstMatch(url);

      if (fbWatchMatch != null) {
        String watchId = fbWatchMatch.group(1)!;
        developer.log("Extracted fb.watch ID: $watchId",
            name: "FacebookParser");
        return watchId;
      }

      // For story URLs
      RegExp storyPattern = RegExp(r'/stories/[0-9]+/([0-9]+)');
      Match? storyMatch = storyPattern.firstMatch(url);

      if (storyMatch != null) {
        String storyId = storyMatch.group(1)!;
        developer.log("Extracted Facebook story ID: $storyId",
            name: "FacebookParser");
        return storyId;
      }

      return null;
    } catch (error) {
      developer.log("Error extracting Facebook ID: $error",
          name: "FacebookParser");
      return null;
    }
  }

  Future<VideoModel> _handleRedNoteUrl(String videoLink) async {
    try {
      // Handle short links by resolving them first
      if (videoLink.contains('xhslink.com')) {
        developer.log(
            "Detected xhslink short URL, attempting to resolve: $videoLink",
            name: "RedNoteAPI");

        try {
          // Extract only the xhslink URL from the text first
          RegExp xhsLinkPattern = RegExp(r'http://xhslink\.com/[a-zA-Z0-9/]+');
          Match? xhsMatch = xhsLinkPattern.firstMatch(videoLink);

          if (xhsMatch != null) {
            String cleanShortUrl = xhsMatch.group(0)!;
            developer.log("Extracted clean xhslink URL: $cleanShortUrl",
                name: "RedNoteAPI");

            String? resolvedUrl = await _resolveShortUrl(cleanShortUrl);
            if (resolvedUrl != null &&
                resolvedUrl.contains('xiaohongshu.com')) {
              videoLink = resolvedUrl;
              developer.log("Resolved short URL to: $videoLink",
                  name: "RedNoteAPI");
            }
          } else {
            developer.log("No valid xhslink URL found in text",
                name: "RedNoteAPI");
          }
        } catch (e) {
          developer.log("Failed to resolve short URL: $e", name: "RedNoteAPI");
          // Continue with original URL processing
        }
      }

      // Extract noteId from RedNote URL
      String? noteId = _extractNoteId(videoLink);

      if (noteId != null) {
        // Try Xiaohongshu-specific API first (most reliable for RedNote)
        developer.log("Trying Xiaohongshu API for noteId: $noteId",
            name: "RedNoteAPI");

        try {
          final xiaohongshuResponse = await _tryXiaohongshuAPI(noteId);
          if (xiaohongshuResponse != null) {
            developer.log("Xiaohongshu API successful", name: "RedNoteAPI");
            return xiaohongshuResponse;
          }
        } catch (xiaohongshuError) {
          developer.log("Xiaohongshu API failed: $xiaohongshuError",
              name: "RedNoteAPI");
        }
      }

      // Try alternative approach with URL pattern matching
      try {
        String? alternativeNoteId = _extractNoteIdFromShortUrl(videoLink);
        if (alternativeNoteId != null && alternativeNoteId != noteId) {
          developer.log("Trying alternative noteId: $alternativeNoteId",
              name: "RedNoteAPI");
          final altResponse = await _tryXiaohongshuAPI(alternativeNoteId);
          if (altResponse != null) {
            developer.log("Alternative Xiaohongshu API successful",
                name: "RedNoteAPI");
            return altResponse;
          }
        }
      } catch (e) {
        developer.log("Alternative noteId extraction failed: $e",
            name: "RedNoteAPI");
      }

      // Try Apify API as secondary option (if configured)
      if (ApiConfig.useApifyForRedNote && ApiConfig.isApifyConfigured) {
        developer.log("Trying Apify API for RedNote: $videoLink",
            name: "RedNoteAPI");

        try {
          final apifyResponse = await _tryApifyRedNoteAPI(videoLink);
          if (apifyResponse != null) {
            developer.log("Apify API successful", name: "RedNoteAPI");
            return apifyResponse;
          }
        } catch (apifyError) {
          developer.log("Apify API failed: $apifyError", name: "RedNoteAPI");
        }
      }

      // Try main API as fallback
      developer.log("Trying main API for RedNote: $videoLink",
          name: "RedNoteAPI");
      try {
        // Only try main API if we have a valid xiaohongshu.com URL
        if (videoLink.contains('xiaohongshu.com')) {
          final response = await dioHelper.get(
            path: AppConstants.getVideoEndpoint,
            queryParams: {"url": videoLink},
            customHeaders: {
              "x-rapidapi-key": ApiConfig.rapidApiKey,
              "x-rapidapi-host": "social-media-video-downloader.p.rapidapi.com",
            },
          );

          developer.log("Main API Response for RedNote: ${response.data}",
              name: "RedNoteAPI");

          if (response.data != null && response.data['success'] == true) {
            return VideoModel.fromJson(response.data);
          }
        }
      } catch (mainApiError) {
        developer.log("Main API failed for RedNote: $mainApiError",
            name: "RedNoteAPI");
      }

      // Return improved fallback response
      return VideoModel(
        success: false,
        message:
            "RedNote content could not be processed. This may be due to:\n• Private content\n• Region restrictions\n• Short link resolution issues\n\nTip: Try using the direct xiaohongshu.com link if available.",
        srcUrl: videoLink,
        ogUrl: "",
        title: AppStrings.redNoteDetected,
        picture: "",
        images: const [],
        timeTaken: DateTime.now().toString(),
        rId: DateTime.now().millisecondsSinceEpoch.toString(),
        videoLinks: const [],
      );
    } catch (error) {
      developer.log("Error handling RedNote URL: $error", name: "RedNoteAPI");

      // Enhanced fallback response for RedNote
      return VideoModel(
        success: false,
        message:
            "Failed to process RedNote URL: ${error.toString()}\n\nPlease ensure the content is public and try again.",
        srcUrl: videoLink,
        ogUrl: "",
        title: AppStrings.redNoteDetected,
        picture: "",
        images: const [],
        timeTaken: DateTime.now().toString(),
        rId: DateTime.now().millisecondsSinceEpoch.toString(),
        videoLinks: const [],
      );
    }
  }

  String? _extractNoteId(String url) {
    try {
      // Extract noteId from RedNote URL patterns
      // Pattern: https://www.xiaohongshu.com/discovery/item/[noteId]
      RegExp noteIdPattern = RegExp(r'/discovery/item/([a-zA-Z0-9]+)');
      Match? match = noteIdPattern.firstMatch(url);

      if (match != null) {
        String noteId = match.group(1)!;
        developer.log("Extracted noteId: $noteId", name: "RedNoteParser");
        return noteId;
      }

      // Alternative pattern: just look for 24-character alphanumeric strings
      RegExp idPattern = RegExp(r'([a-zA-Z0-9]{24})');
      Match? idMatch = idPattern.firstMatch(url);

      if (idMatch != null) {
        String noteId = idMatch.group(1)!;
        developer.log("Found potential noteId: $noteId", name: "RedNoteParser");
        return noteId;
      }

      developer.log("No noteId found in URL: $url", name: "RedNoteParser");
      return null;
    } catch (error) {
      developer.log("Error extracting noteId: $error", name: "RedNoteParser");
      return null;
    }
  }

  Future<VideoModel?> _tryXiaohongshuAPI(String noteId) async {
    try {
      developer.log("Calling Xiaohongshu API with noteId: $noteId",
          name: "XiaohongshuAPI");

      final response = await dioHelper.get(
        baseUrl: AppConstants.xiaohongshuBaseUrl,
        path: AppConstants.xiaohongshuEndpoint,
        queryParams: {"noteId": noteId},
        customHeaders: {
          "x-rapidapi-key": AppConstants.xiaohongshuApiKey,
          "x-rapidapi-host": AppConstants.xiaohongshuApiHost,
        },
      );

      developer.log("Xiaohongshu API response: ${response.data}",
          name: "XiaohongshuAPI");

      if (response.data != null && response.data['code'] == 0) {
        // Parse the actual Xiaohongshu API response structure
        var responseData = response.data;

        // Navigate to the actual note data
        if (responseData['data'] != null &&
            responseData['data'] is List &&
            responseData['data'].isNotEmpty &&
            responseData['data'][0]['note_list'] != null &&
            responseData['data'][0]['note_list'] is List &&
            responseData['data'][0]['note_list'].isNotEmpty) {
          var noteData = responseData['data'][0]['note_list'][0];

          List<VideoLinkModel> videoLinks = [];
          List<String> imageUrls = [];

          // Extract video URL if available
          if (noteData['video'] != null && noteData['video']['url'] != null) {
            String videoUrl = noteData['video']['url'];
            developer.log("Found video URL: $videoUrl", name: "XiaohongshuAPI");
            videoLinks.add(VideoLinkModel(
                quality: _formatQualityName(
                    "RedNote Video (${noteData['video']['width']}x${noteData['video']['height']})"),
                link: videoUrl));
          }

          // Extract image URLs from images_list
          if (noteData['images_list'] != null &&
              noteData['images_list'] is List) {
            var imagesList = noteData['images_list'] as List;
            for (int i = 0; i < imagesList.length; i++) {
              var imageData = imagesList[i];
              String imageUrl = "";

              // Try to get original quality first, then fallback to regular URL
              if (imageData['original'] != null) {
                imageUrl = imageData['original'];
              } else if (imageData['url'] != null) {
                imageUrl = imageData['url'];
              }

              if (imageUrl.isNotEmpty) {
                imageUrls.add(imageUrl);
                videoLinks.add(VideoLinkModel(
                    quality: _formatQualityName(
                        "Image ${i + 1} (${imageData['width']}x${imageData['height']})"),
                    link: imageUrl));
                developer.log("Found image URL: $imageUrl",
                    name: "XiaohongshuAPI");
              }
            }
          }

          // Extract user and content info
          String title = noteData['desc'] ??
              noteData['title'] ??
              AppStrings.redNoteDetected;
          String userName = "";
          String coverImage = "";

          if (noteData['user'] != null) {
            userName =
                noteData['user']['nickname'] ?? noteData['user']['name'] ?? "";
          }

          // Get cover image
          if (imageUrls.isNotEmpty) {
            coverImage = imageUrls[0];
          } else if (noteData['video'] != null &&
              noteData['video']['first_frame'] != null) {
            coverImage = noteData['video']['first_frame'];
          }

          // Add user info to title if available
          if (userName.isNotEmpty) {
            title = "$userName: $title";
          }

          developer.log(
              "Parsed successfully - Videos: ${videoLinks.where((v) => v.quality.contains('Video')).length}, Images: ${imageUrls.length}",
              name: "XiaohongshuAPI");

          return VideoModel(
            success: true,
            message: "Content extracted successfully from RedNote",
            srcUrl: "https://www.xiaohongshu.com/discovery/item/$noteId",
            ogUrl: responseData['data'][0]['note_list'][0]['share_info']
                    ?['link'] ??
                "",
            title: title,
            picture: coverImage,
            images: imageUrls,
            timeTaken: DateTime.now().toString(),
            rId: noteId,
            videoLinks: videoLinks,
          );
        }
      }

      developer.log("Failed to parse Xiaohongshu response structure",
          name: "XiaohongshuAPI");
      return null;
    } catch (error) {
      developer.log("Xiaohongshu API error: $error", name: "XiaohongshuAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryApifyRedNoteAPI(String videoLink) async {
    try {
      // Check if Apify is configured
      if (!ApiConfig.useApifyForRedNote || !ApiConfig.isApifyConfigured) {
        developer.log("Apify not configured. ${ApiConfig.apifyInstructions}",
            name: "ApifyAPI");
        return null;
      }

      String endpoint = AppConstants.apifyRunEndpoint.replaceFirst(
        '{actorId}',
        AppConstants.apifyRedNoteActor,
      );

      // Apify API request body
      Map<String, dynamic> requestBody = {
        "url": videoLink,
        "proxy": {"useApifyProxy": true},
        "maxItems": 1,
      };

      developer.log("Calling Apify API: ${AppConstants.apifyBaseUrl}$endpoint",
          name: "ApifyAPI");

      final response = await dioHelper.post(
        baseUrl: AppConstants.apifyBaseUrl,
        path: endpoint,
        data: requestBody,
        queryParams: {"token": ApiConfig.apifyApiToken},
        customHeaders: {"Content-Type": "application/json"},
      );

      developer.log("Apify response: ${response.data}", name: "ApifyAPI");

      if (response.data != null &&
          response.data is List &&
          response.data.isNotEmpty) {
        var item = response.data[0]; // First item from dataset

        // Parse Apify response into VideoModel
        List<VideoLinkModel> videoLinks = [];
        List<String> imageUrls = [];

        if (item['videoUrl'] != null) {
          videoLinks.add(VideoLinkModel(
              quality: _formatQualityName("RedNote Video"),
              link: item['videoUrl']));
        }

        if (item['imageUrls'] != null && item['imageUrls'] is List) {
          imageUrls = List<String>.from(item['imageUrls']);
          // Add images as downloadable links too
          for (int i = 0; i < imageUrls.length; i++) {
            videoLinks.add(VideoLinkModel(
                quality: _formatQualityName("Image ${i + 1}"),
                link: imageUrls[i]));
          }
        }

        return VideoModel(
          success: true,
          message: "Content extracted successfully",
          srcUrl: videoLink,
          ogUrl: item['url'] ?? videoLink,
          title: item['title'] ?? item['content'] ?? AppStrings.redNoteDetected,
          picture:
              item['thumbnail'] ?? (imageUrls.isNotEmpty ? imageUrls[0] : ""),
          images: imageUrls,
          timeTaken: DateTime.now().toString(),
          rId: DateTime.now().millisecondsSinceEpoch.toString(),
          videoLinks: videoLinks,
        );
      }

      return null;
    } catch (error) {
      developer.log("Apify API error: $error", name: "ApifyAPI");
      return null;
    }
  }

  @override
  Future<String> saveVideo({
    required String videoLink,
    required String savePath,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      // Handle image downloads for RedNote galleries
      if (_isImageUrl(videoLink)) {
        await dioHelper.downloadImage(
            savePath: savePath,
            downloadLink: videoLink,
            onReceiveProgress: onReceiveProgress);
      } else {
        await dioHelper.download(
            savePath: savePath,
            downloadLink: videoLink,
            onReceiveProgress: onReceiveProgress);
      }
      return AppStrings.downloadSuccess;
    } catch (error) {
      rethrow;
    }
  }

  bool _isRedNoteUrl(String url) {
    // Check for RedNote (小红书) URL patterns including short links
    return url.contains('xiaohongshu.com') ||
        url.contains('xhslink.com') ||
        url.contains('小红书') ||
        url.toLowerCase().contains('rednote') ||
        url.contains('SMcoyMr1SzEetqh'); // RedNote specific pattern
  }

  String _extractRedNoteUrl(String text) {
    // Extract clean URL from RedNote share text
    developer.log("Original RedNote text: $text", name: "RedNoteParser");

    // Pattern 1: Look for xhslink.com short URLs
    RegExp xhsLinkPattern = RegExp(r'http://xhslink\.com/[a-zA-Z0-9/]+');
    Match? xhsMatch = xhsLinkPattern.firstMatch(text);

    if (xhsMatch != null) {
      String shortUrl = xhsMatch.group(0)!;
      developer.log("Found xhslink short URL: $shortUrl",
          name: "RedNoteParser");
      return shortUrl; // Return short URL for processing
    }

    // Pattern 2: Look for https://www.xiaohongshu.com/discovery/item/[id] pattern
    RegExp discoveryPattern =
        RegExp(r'https://www\.xiaohongshu\.com/discovery/item/[a-zA-Z0-9]+');
    Match? discoveryMatch = discoveryPattern.firstMatch(text);

    if (discoveryMatch != null) {
      String cleanUrl = discoveryMatch.group(0)!;
      developer.log("Extracted discovery URL: $cleanUrl",
          name: "RedNoteParser");
      return cleanUrl;
    }

    // Pattern 3: Look for any xiaohongshu.com URL and extract the main part
    RegExp urlPattern = RegExp(r'https://[^\s]*xiaohongshu\.com[^\s]*');
    Match? match = urlPattern.firstMatch(text);

    if (match != null) {
      String fullUrl = match.group(0)!;
      developer.log("Found full URL: $fullUrl", name: "RedNoteParser");

      // Extract the main URL part before query parameters
      if (fullUrl.contains('?')) {
        String baseUrl = fullUrl.split('?')[0];
        developer.log("Extracted base URL: $baseUrl", name: "RedNoteParser");
        return baseUrl;
      }
      return fullUrl;
    }

    // Pattern 4: Look for note ID pattern and construct URL (SMcoyMr1SzEetqh format)
    RegExp noteIdPattern = RegExp(r'([a-zA-Z0-9]{12,24})');
    Match? idMatch = noteIdPattern.firstMatch(text);

    if (idMatch != null) {
      String noteId = idMatch.group(0)!;
      // Skip common patterns that aren't note IDs
      if (noteId.length >= 12 &&
          !noteId.contains('http') &&
          !noteId.contains('www')) {
        String constructedUrl =
            "https://www.xiaohongshu.com/discovery/item/$noteId";
        developer.log("Constructed URL from ID: $constructedUrl",
            name: "RedNoteParser");
        return constructedUrl;
      }
    }

    developer.log("No URL pattern found, returning original text",
        name: "RedNoteParser");
    // Return original if no URL pattern found
    return text;
  }

  bool _isImageUrl(String url) {
    return url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.webp');
  }

  bool _isTikTokUrl(String url) {
    return url.contains('tiktok.com') ||
        url.contains('douyin.com') ||
        url.contains('v.douyin.com'); // Add support for Douyin short links
  }

  bool _isFacebookUrl(String url) {
    return url.contains('facebook.com') || url.contains('fb.watch');
  }


  bool _isInstagramUrl(String url) {
    return url.contains('instagram.com');
  }

  /// Helper function to format video quality names to be more user-friendly
  String _formatQualityName(String originalQuality) {
    // Handle common quality patterns and make them more readable
    final quality = originalQuality.toLowerCase();

    // Video quality patterns
    if (quality.contains('video_hd_original')) {
      return '📺 High Quality (Original)';
    }
    if (quality.contains('video_hd_540p_normal')) {
      return '📺 Medium Quality (540p)';
    }
    if (quality.contains('video_hd_540p_lowest')) {
      return '📺 Standard Quality (540p)';
    }
    if (quality.contains('video_hd_720p')) return '📺 HD Quality (720p)';
    if (quality.contains('video_hd_1080p')) return '📺 Full HD (1080p)';
    if (quality.contains('video_hd')) return '📺 HD Video';
    if (quality.contains('hdplay')) return '📺 High Definition';
    if (quality.contains('play')) return '📺 Standard Video';
    if (quality.contains('wmplay')) return '📺 Video (with watermark)';

    // Audio patterns
    if (quality.contains('audio')) return '🎵 Audio Only';
    if (quality.contains('mp3')) return '🎵 Audio (MP3)';

    // Image patterns
    if (quality.contains('image')) return '🖼️ $originalQuality';

    // TikTok/Douyin patterns
    if (quality.contains('tiktok video quality')) {
      String number = originalQuality.replaceAll(RegExp(r'[^\d]'), '');
      return '📺 TikTok Quality ${number.isNotEmpty ? number : ""}';
    }
    if (quality.contains('tiktok video')) return '📺 TikTok Video';

    // RedNote patterns
    if (quality.contains('rednote video')) return '📺 RedNote Video';

    // Default patterns
    if (quality.contains('video')) return '📺 Video';
    if (quality.contains('standard')) return '📺 Standard Quality';
    if (quality.contains('hd')) return '📺 HD Quality';
    if (quality.contains('low')) return '📺 Low Quality';
    if (quality.contains('high')) return '📺 High Quality';

    // If no pattern matches, return original with video icon
    return '📺 $originalQuality';
  }

  Future<VideoModel?> _tryDouyinAPI(String videoLink) async {
    try {
      developer.log("Starting enhanced Douyin API processing: $videoLink",
          name: "DouyinAPI");

      // Strategy 1: Try primary Douyin API (douyin-api-new.p.rapidapi.com)
      VideoModel? result = await _tryDouyinPrimaryAPI(videoLink);
      if (result != null && result.success) {
        developer.log(
            "✅ Primary Douyin API successful - stopping other attempts",
            name: "DouyinAPI");
        return result;
      }

      // Strategy 2: Try search method with keyword
      result = await _tryDouyinSearchWithKeyword(videoLink);
      if (result?.success == true) {
        developer.log(
            "✅ Douyin search method successful - stopping other attempts",
            name: "DouyinAPI");
        return result!;
      }

      // Strategy 3: Try alternative TikTok API
      result = await _tryDouyinAlternativeAPI(videoLink);
      if (result != null && result.success) {
        developer.log(
            "✅ Alternative Douyin API successful - stopping other attempts",
            name: "DouyinAPI");
        return result;
      }

      // Strategy 4: Try backup Chinese API (api.douyin.wtf)
      result = await _tryDouyinBackupAPI(videoLink);
      if (result != null && result.success) {
        developer.log(
            "✅ Backup Douyin API successful - stopping other attempts",
            name: "DouyinAPI");
        return result;
      }

      // Strategy 5: Try 52api.cn alternative (for Chinese Douyin)
      result = await _tryAlternativeTikTokAPI(videoLink);
      if (result?.success == true) {
        developer.log(
            "✅ 52api.cn Douyin API successful - stopping other attempts",
            name: "DouyinAPI");
        return result!;
      }

      // Strategy 6: Try URL resolution approach (like RedNote)
      result = await _tryDouyinURLResolution(videoLink);
      if (result != null && result.success) {
        developer.log(
            "✅ Douyin URL resolution successful - stopping other attempts",
            name: "DouyinAPI");
        return result;
      }

      developer.log("❌ All Douyin API strategies failed", name: "DouyinAPI");
      return null;
    } catch (error) {
      developer.log("❌ Error in enhanced Douyin API processing: $error",
          name: "DouyinAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryDouyinPrimaryAPI(String videoLink) async {
    try {
      developer.log("Trying primary Douyin API (douyin-api-new): $videoLink",
          name: "DouyinAPI");

      // Clean the URL first (like RedNote processing)
      String cleanUrl = _cleanDouyinUrl(videoLink);
      developer.log("Cleaned Douyin URL: $cleanUrl", name: "DouyinAPI");

      // Validate URL before making request
      if (!_isValidUrl(cleanUrl)) {
        developer.log("⚠️ Invalid URL format, skipping primary API",
            name: "DouyinAPI");
        return null;
      }

      final response = await dioHelper.post(
        baseUrl: AppConstants.douyinBaseUrl,
        path: AppConstants.douyinVideoEndpoint,
        data: {"url": cleanUrl},
        customHeaders: {
          "x-rapidapi-key": AppConstants.douyinApiKey,
          "x-rapidapi-host": AppConstants.douyinApiHost,
          "Content-Type": "application/json",
          "Host": AppConstants.douyinApiHost,
        },
      );

      developer.log("Primary Douyin API response: ${response.data}",
          name: "DouyinAPI");

      if (response.data != null) {
        return _parseDouyinUnifiedResponse(response.data, videoLink);
      }

      return null;
    } catch (error) {
      developer.log("⚠️ Primary Douyin API error: $error", name: "DouyinAPI");
      return null;
    }
  }

  bool _isValidUrl(String url) {
    try {
      // Check if URL is empty or just whitespace
      if (url.trim().isEmpty) {
        return false;
      }

      // Check if it's a proper URI
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return false;
      }

      // Check if it has a valid scheme and host
      if (uri.scheme.isEmpty || uri.host.isEmpty) {
        return false;
      }

      // Check for valid schemes
      if (!['http', 'https', 'ftp', 'ftps']
          .contains(uri.scheme.toLowerCase())) {
        return false;
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  Future<VideoModel?> _tryDouyinAlternativeAPI(String videoLink) async {
    try {
      developer.log("Trying alternative TikTok API: $videoLink",
          name: "DouyinAPI");

      String cleanUrl = _cleanDouyinUrl(videoLink);

      final response = await dioHelper.post(
        baseUrl: AppConstants.douyinAltBaseUrl,
        path: AppConstants.douyinAltEndpoint,
        data: {"url": cleanUrl},
        customHeaders: {
          "x-rapidapi-key": AppConstants.douyinApiKey,
          "x-rapidapi-host": AppConstants.douyinAltApiHost,
          "Content-Type": "application/json",
        },
      );

      developer.log("Alternative Douyin API response: ${response.data}",
          name: "DouyinAPI");

      if (response.data != null) {
        return _parseDouyinUnifiedResponse(response.data, videoLink);
      }

      return null;
    } catch (error) {
      developer.log("Alternative Douyin API error: $error", name: "DouyinAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryDouyinBackupAPI(String videoLink) async {
    try {
      developer.log("Trying backup Chinese Douyin API: $videoLink",
          name: "DouyinAPI");

      String cleanUrl = _cleanDouyinUrl(videoLink);

      // Validate URL before making request
      if (!_isValidUrl(cleanUrl)) {
        developer.log("⚠️ Invalid URL format, skipping backup API",
            name: "DouyinAPI");
        return null;
      }

      final response = await dioHelper.get(
        baseUrl: AppConstants.douyinBackupBaseUrl,
        path: AppConstants.douyinBackupEndpoint,
        queryParams: {"url": cleanUrl, "minimal": "false"},
        customHeaders: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
          "Accept": "application/json",
        },
      );

      developer.log("Backup Douyin API response: ${response.data}",
          name: "DouyinAPI");

      if (response.data != null) {
        return _parseDouyinUnifiedResponse(response.data, videoLink);
      }

      return null;
    } catch (error) {
      developer.log("⚠️ Backup Douyin API error: $error", name: "DouyinAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryDouyinURLResolution(String videoLink) async {
    try {
      developer.log("Trying Douyin URL resolution approach: $videoLink",
          name: "DouyinAPI");

      // Try to resolve short URLs first (like RedNote approach)
      String? resolvedUrl = await _resolveDouyinShortUrl(videoLink);
      if (resolvedUrl != null && resolvedUrl != videoLink) {
        developer.log("Resolved Douyin URL: $resolvedUrl", name: "DouyinAPI");

        // Try primary API with resolved URL
        VideoModel? result = await _tryDouyinPrimaryAPI(resolvedUrl);
        if (result != null && result.success) {
          return result;
        }
      }

      return null;
    } catch (error) {
      developer.log("Douyin URL resolution error: $error", name: "DouyinAPI");
      return null;
    }
  }

  String _cleanDouyinUrl(String url) {
    try {
      developer.log("Cleaning Douyin URL: $url", name: "DouyinParser");

      // Extract clean Douyin URL from share text (like RedNote processing)
      if (url.contains('v.douyin.com')) {
        RegExp douyinUrlPattern =
            RegExp(r'https://v\.douyin\.com/[a-zA-Z0-9]+/?');
        Match? urlMatch = douyinUrlPattern.firstMatch(url);
        if (urlMatch != null) {
          String cleanUrl = urlMatch.group(0)!;
          // Remove trailing slash for consistency
          if (cleanUrl.endsWith('/')) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
          }
          developer.log("Extracted clean short URL: $cleanUrl",
              name: "DouyinParser");
          return cleanUrl;
        }
      }

      // Handle regular Douyin URLs
      if (url.contains('douyin.com/video/')) {
        RegExp videoPattern = RegExp(r'https://www\.douyin\.com/video/[0-9]+');
        Match? videoMatch = videoPattern.firstMatch(url);
        if (videoMatch != null) {
          String cleanUrl = videoMatch.group(0)!;
          developer.log("Extracted clean video URL: $cleanUrl",
              name: "DouyinParser");
          return cleanUrl;
        }
      }

      // Handle discovery URLs
      if (url.contains('douyin.com/discover')) {
        RegExp discoveryPattern = RegExp(r'modal_id=([0-9]+)');
        Match? discoveryMatch = discoveryPattern.firstMatch(url);
        if (discoveryMatch != null) {
          String videoId = discoveryMatch.group(1)!;
          String cleanUrl = "https://www.douyin.com/video/$videoId";
          developer.log("Converted discovery URL to: $cleanUrl",
              name: "DouyinParser");
          return cleanUrl;
        }
      }

      // Remove tracking parameters
      if (url.contains('?')) {
        String baseUrl = url.split('?')[0];
        developer.log("Removed query parameters: $baseUrl",
            name: "DouyinParser");
        return baseUrl;
      }

      developer.log("URL already clean: $url", name: "DouyinParser");
      return url;
    } catch (error) {
      developer.log("Error cleaning Douyin URL: $error", name: "DouyinParser");
      return url;
    }
  }

  Future<String?> _resolveDouyinShortUrl(String shortUrl) async {
    try {
      // Only try to resolve if it's actually a short URL
      if (!shortUrl.contains('v.douyin.com')) {
        return null;
      }

      developer.log("Attempting to resolve Douyin short URL: $shortUrl",
          name: "DouyinResolver");

      final Dio urlDio = Dio();
      urlDio.options = BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 400,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );

      final response = await urlDio.get(
        shortUrl,
        options: Options(
          headers: {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.8,en-US;q=0.5,en;q=0.3",
          },
        ),
      );

      String? finalUrl = response.realUri.toString();
      if (finalUrl.contains('douyin.com')) {
        developer.log("Successfully resolved to: $finalUrl",
            name: "DouyinResolver");
        return finalUrl;
      }

      return null;
    } catch (error) {
      developer.log("Error resolving Douyin short URL: $error",
          name: "DouyinResolver");
      return null;
    }
  }

  VideoModel? _parseDouyinUnifiedResponse(
      Map<String, dynamic> responseData, String originalUrl) {
    try {
      developer.log("Parsing Douyin unified response", name: "DouyinParser");

      List<VideoLinkModel> videoLinks = [];

      // Check for success status
      bool isSuccess = responseData['success'] == true ||
          responseData['status'] == 'success' ||
          responseData['code'] == 0 ||
          responseData['status_code'] == 200;

      if (!isSuccess && responseData['data'] == null) {
        developer.log(
            "Response indicates failure: ${responseData['message'] ?? 'Unknown error'}",
            name: "DouyinParser");
        return null;
      }

      // Get the actual video data (from backup API it's in 'data' field)
      Map<String, dynamic> videoData = responseData['data'] ?? responseData;

      // Handle the actual backup API structure seen in logs
      if (videoData['video'] != null &&
          videoData['video']['bit_rate'] != null) {
        var video = videoData['video'];
        var bitRateArray = video['bit_rate'] as List;

        // Create unique video links from bit_rate array
        for (var bitRateItem in bitRateArray) {
          if (bitRateItem['play_addr'] != null &&
              bitRateItem['play_addr']['url_list'] != null) {
            var urlList = bitRateItem['play_addr']['url_list'] as List;
            if (urlList.isNotEmpty) {
              String videoUrl = urlList[0].toString();

              // Create descriptive quality name from gear_name and bit_rate
              String gearName =
                  bitRateItem['gear_name']?.toString() ?? 'unknown';
              int bitRate = bitRateItem['bit_rate'] ?? 0;
              String qualityType =
                  bitRateItem['quality_type']?.toString() ?? '';

              String qualityName =
                  _formatDouyinQualityName(gearName, bitRate, qualityType);

              videoLinks.add(VideoLinkModel(
                quality: qualityName,
                link: videoUrl,
              ));
            }
          }
        }
      }

      // If no bit_rate array, try other patterns
      if (videoLinks.isEmpty) {
        // Pattern 1: Simple URL structure
        if (videoData['url'] != null) {
          videoLinks.add(VideoLinkModel(
            quality: "📺 Video",
            link: videoData['url'].toString(),
          ));
        }

        // Pattern 2: Direct video URL fields
        for (var field in ['video_url', 'play_url', 'download_url', 'hdplay', 'play', 'wmplay']) {
          if (videoData[field] != null) {
            videoLinks.add(VideoLinkModel(
              quality:
                  _formatQualityName("Douyin ${field.replaceAll('_', ' ')}"),
              link: videoData[field].toString(),
            ));
          }
        }

        // Pattern 3: Nested video object
        if (videoData['video'] != null) {
          var video = videoData['video'];
          if (video['play_addr'] != null) {
            var playAddr = video['play_addr'];
            if (playAddr['url_list'] != null && playAddr['url_list'] is List) {
              var urlList = playAddr['url_list'] as List;
              for (int i = 0; i < urlList.length; i++) {
                videoLinks.add(VideoLinkModel(
                  quality: _formatQualityName("Douyin Video Quality ${i + 1}"),
                  link: urlList[i].toString(),
                ));
              }
            } else if (playAddr['url'] != null) {
              videoLinks.add(VideoLinkModel(
                quality: _formatQualityName("Douyin Video"),
                link: playAddr['url'].toString(),
              ));
            }
          }

          // Check for download URLs
          if (video['download_addr'] != null) {
            var downloadAddr = video['download_addr'];
            if (downloadAddr['url_list'] != null &&
                downloadAddr['url_list'] is List) {
              var urlList = downloadAddr['url_list'] as List;
              for (int i = 0; i < urlList.length; i++) {
                videoLinks.add(VideoLinkModel(
                  quality: _formatQualityName("Douyin Download ${i + 1}"),
                  link: urlList[i].toString(),
                ));
              }
            }
          }
        }
      }

      // Pattern 4: aweme_detail structure
      if (videoLinks.isEmpty && videoData['aweme_detail'] != null) {
        return _parseNewDouyinResponse(videoData['aweme_detail'], originalUrl);
      }

      if (videoLinks.isEmpty) {
        developer.log("No video URLs found in response", name: "DouyinParser");
        return null;
      }

      // Remove duplicate video links with same URL
      Map<String, VideoLinkModel> uniqueLinks = {};
      for (var link in videoLinks) {
        uniqueLinks[link.link] = link;
      }
      videoLinks = uniqueLinks.values.toList();

      // Extract metadata from backup API structure
      String title = "Douyin Video";
      if (videoData['desc'] != null) {
        title = videoData['desc'].toString();
      } else if (videoData['title'] != null) {
        title = videoData['title'].toString();
      } else if (videoData['caption'] != null) {
        title = videoData['caption'].toString();
      }

      String author = "";
      if (videoData['author'] != null &&
          videoData['author']['nickname'] != null) {
        author = videoData['author']['nickname'].toString();
      }

      if (author.isNotEmpty) {
        title = "$author: $title";
      }

      // Enhanced cover image extraction for backup API response structure
      String coverImage = "";

      // Try to extract from complex nested structures first (backup API format)
      if (videoData['author'] != null &&
          videoData['author']['cover_url'] != null) {
        var coverData = videoData['author']['cover_url'];
        if (coverData is List &&
            coverData.isNotEmpty &&
            coverData[0]['url_list'] != null) {
          var urlList = coverData[0]['url_list'] as List;
          if (urlList.isNotEmpty) {
            coverImage = urlList[0].toString();
          }
        }
      }

      // Try video cover if author cover not found
      if (coverImage.isEmpty && videoData['video'] != null) {
        var video = videoData['video'];
        if (video['cover'] != null && video['cover']['url_list'] != null) {
          var urlList = video['cover']['url_list'] as List;
          if (urlList.isNotEmpty) {
            coverImage = urlList[0].toString();
          }
        } else if (video['dynamic_cover'] != null &&
            video['dynamic_cover']['url_list'] != null) {
          var urlList = video['dynamic_cover']['url_list'] as List;
          if (urlList.isNotEmpty) {
            coverImage = urlList[0].toString();
          }
        } else if (video['origin_cover'] != null &&
            video['origin_cover']['url_list'] != null) {
          var urlList = video['origin_cover']['url_list'] as List;
          if (urlList.isNotEmpty) {
            coverImage = urlList[0].toString();
          }
        }
      }

      // Fallback to simple string fields
      if (coverImage.isEmpty) {
        coverImage = videoData['cover']?.toString() ??
            videoData['thumbnail']?.toString() ??
            videoData['picture']?.toString() ??
            "";
      }

      // Validate cover image URL to prevent empty URI errors
      if (coverImage.isNotEmpty && !_isValidUrl(coverImage)) {
        developer.log("Invalid cover image URL detected, clearing: $coverImage",
            name: "DouyinParser");
        coverImage = "";
      }

      String videoId = videoData['id']?.toString() ??
          videoData['aweme_id']?.toString() ??
          _extractTikTokVideoId(originalUrl) ??
          DateTime.now().millisecondsSinceEpoch.toString();

      return VideoModel(
        success: true,
        message: "Video extracted successfully from Douyin",
        srcUrl: originalUrl,
        ogUrl: originalUrl,
        title: title,
        picture: coverImage,
        images: coverImage.isNotEmpty ? [coverImage] : [],
        timeTaken: DateTime.now().toString(),
        rId: videoId,
        videoLinks: videoLinks,
      );
    } catch (error) {
      developer.log("Error parsing Douyin unified response: $error",
          name: "DouyinParser");
      return null;
    }
  }

  Future<VideoModel?> _tryDouyinSearchWithKeyword(String videoLink) async {
    try {
      developer.log("Douyin search method not implemented yet",
          name: "DouyinAPI");
      return null;
    } catch (error) {
      developer.log("Douyin search error: $error", name: "DouyinAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryAlternativeTikTokAPI(String videoLink) async {
    try {
      developer.log("Alternative TikTok API not implemented yet",
          name: "DouyinAPI");
      return null;
    } catch (error) {
      developer.log("Alternative TikTok API error: $error", name: "DouyinAPI");
      return null;
    }
  }

  String _formatDouyinQualityName(
      String gearName, int bitRate, String qualityType) {
    String quality = "📺 ";

    if (gearName.contains('1080')) {
      quality += "Full HD (1080p)";
    } else if (gearName.contains('720')) {
      quality += "HD (720p)";
    } else if (gearName.contains('540')) {
      quality += "Standard (540p)";
    } else {
      quality += gearName.replaceAll('_', ' ');
    }

    if (bitRate > 0) {
      double bitRateMbps = bitRate / 1000000;
      quality += " (${bitRateMbps.toStringAsFixed(1)}Mbps)";
    }

    return quality;
  }

  String? _extractTikTokVideoId(String url) {
    try {
      RegExp videoIdPattern = RegExp(r'/video/(\d+)');
      Match? match = videoIdPattern.firstMatch(url);

      if (match != null) {
        String videoId = match.group(1)!;
        developer.log("Extracted TikTok video ID: $videoId", name: "DouyinAPI");
        return videoId;
      }

      return null;
    } catch (error) {
      developer.log("Error extracting TikTok video ID: $error",
          name: "DouyinAPI");
      return null;
    }
  }

  VideoModel? _parseNewDouyinResponse(
      Map<String, dynamic> responseData, String originalUrl) {
    try {
      List<VideoLinkModel> videoLinks = [];

      if (responseData['video_url'] != null) {
        videoLinks.add(VideoLinkModel(
          quality: _formatQualityName("Douyin Video"),
          link: responseData['video_url'].toString(),
        ));
      }

      if (videoLinks.isEmpty) {
        developer.log("No video URLs found in new Douyin response",
            name: "DouyinAPI");
        return null;
      }

      String title = responseData['title']?.toString() ?? "Douyin Video";
      String coverImage = responseData['cover']?.toString() ?? "";

      return VideoModel(
        success: true,
        message: "Video extracted successfully from Douyin",
        srcUrl: originalUrl,
        ogUrl: originalUrl,
        title: title,
        picture: coverImage,
        images: coverImage.isNotEmpty ? [coverImage] : [],
        timeTaken: DateTime.now().toString(),
        rId: DateTime.now().millisecondsSinceEpoch.toString(),
        videoLinks: videoLinks,
      );
    } catch (error) {
      developer.log("Error parsing new Douyin response: $error",
          name: "DouyinAPI");
      return null;
    }
  }

  bool _isAPI403Error(Exception? error) {
    if (error == null) return false;
    String errorString = error.toString().toLowerCase();
    return errorString.contains('403') ||
        errorString.contains('not subscribed') ||
        errorString.contains('forbidden');
  }

  Future<VideoModel?> _tryAlternativeFacebookAPI(String videoLink) async {
    try {
      developer.log("Trying alternative Facebook API: $videoLink",
          name: "FacebookAltAPI");

      // Try new working Facebook API - GetFB.net style API
      try {
        final response = await dioHelper.post(
          baseUrl: "https://getfb-api.p.rapidapi.com",
          path: "/facebook-downloader",
          data: {"url": videoLink},
          customHeaders: {
            "x-rapidapi-key": ApiConfig.rapidApiKey,
            "x-rapidapi-host": "getfb-api.p.rapidapi.com",
            "Content-Type": "application/json",
          },
        );

        developer.log("GetFB-style API Response: ${response.data}",
            name: "FacebookAltAPI");

        if (response.data != null && response.data['success'] == true) {
          return _parseFacebookResponse(response.data, videoLink);
        }
      } catch (e) {
        developer.log("GetFB-style API failed: $e", name: "FacebookAltAPI");
      }

      // Try FBVideo.net style API
      try {
        final response = await dioHelper.get(
          baseUrl: "https://fbvideo-api.p.rapidapi.com",
          path: "/download",
          queryParams: {"url": videoLink},
          customHeaders: {
            "x-rapidapi-key": ApiConfig.rapidApiKey,
            "x-rapidapi-host": "fbvideo-api.p.rapidapi.com",
          },
        );

        developer.log("FBVideo-style API Response: ${response.data}",
            name: "FacebookAltAPI");

        if (response.data != null && response.data['success'] == true) {
          return _parseFacebookResponse(response.data, videoLink);
        }
      } catch (e) {
        developer.log("FBVideo-style API failed: $e", name: "FacebookAltAPI");
      }

      // Try Backup Facebook downloader API
      try {
        final response = await dioHelper.post(
          baseUrl: "https://facebook-reel-and-video-downloader.p.rapidapi.com",
          path: "/app/main.php",
          data: {"url": videoLink},
          customHeaders: {
            "x-rapidapi-key": ApiConfig.rapidApiKey,
            "x-rapidapi-host":
                "facebook-reel-and-video-downloader.p.rapidapi.com",
            "Content-Type": "application/json",
          },
        );

        developer.log("Backup Facebook API Response: ${response.data}",
            name: "FacebookAltAPI");

        if (response.data != null && response.data['success'] == true) {
          return _parseFacebookResponse(response.data, videoLink);
        }
      } catch (e) {
        developer.log("Backup Facebook API failed: $e", name: "FacebookAltAPI");
      }

      return null;
    } catch (error) {
      developer.log("Alternative Facebook API error: $error",
          name: "FacebookAltAPI");
      return null;
    }
  }

  VideoModel? _parseFacebookResponse(
      Map<String, dynamic> data, String videoLink) {
    try {
      List<VideoLinkModel> videoLinks = [];

      // Pattern 1: Standard links array
      if (data['links'] != null && data['links'] is List) {
        var links = data['links'] as List;
        for (var link in links) {
          if (link['link'] != null && link['quality'] != null) {
            videoLinks.add(VideoLinkModel(
              quality: _formatQualityName("📺 ${link['quality']}"),
              link: link['link'].toString(),
            ));
          }
        }
      }

      // Pattern 2: Direct video URLs
      for (var key in ['hd_url', 'sd_url', 'video_url', 'download_url']) {
        if (data[key] != null && data[key].toString().isNotEmpty) {
          String quality = key.contains('hd')
              ? "HD"
              : key.contains('sd')
                  ? "SD"
                  : "Video";
          videoLinks.add(VideoLinkModel(
            quality: _formatQualityName("📺 Facebook $quality"),
            link: data[key].toString(),
          ));
        }
      }

      // Pattern 3: Quality-based structure
      if (data['video'] != null && data['video'] is Map) {
        var video = data['video'] as Map;
        for (var quality in ['hd', 'sd', 'low']) {
          if (video[quality] != null) {
            videoLinks.add(VideoLinkModel(
              quality:
                  _formatQualityName("📺 Facebook ${quality.toUpperCase()}"),
              link: video[quality].toString(),
            ));
          }
        }
      }

      if (videoLinks.isNotEmpty) {
        return VideoModel(
          success: true,
          message: "Facebook video extracted successfully",
          srcUrl: videoLink,
          ogUrl: data['og_url']?.toString() ?? videoLink,
          title: data['title']?.toString() ??
              data['video_title']?.toString() ??
              "Facebook Video",
          picture: data['thumbnail']?.toString() ??
              data['thumb']?.toString() ??
              data['picture']?.toString() ??
              "",
          images: data['images'] != null && data['images'] is List
              ? List<String>.from(data['images'])
              : [],
          timeTaken: DateTime.now().toString(),
          rId: _extractFacebookId(videoLink) ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          videoLinks: videoLinks,
        );
      }

      return null;
    } catch (e) {
      developer.log("Error parsing Facebook response: $e",
          name: "FacebookAltAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryMainAPIWithTikTokHeaders(String videoLink) async {
    try {
      developer.log("Calling main API with TikTok-specific headers: $videoLink",
          name: "TikTokAPI");

      final response = await dioHelper.get(
        path: AppConstants.getVideoEndpoint,
        queryParams: {"url": videoLink},
        customHeaders: {
          "x-rapidapi-key": ApiConfig.rapidApiKey,
          "x-rapidapi-host": "social-media-video-downloader.p.rapidapi.com",
          "User-Agent":
              "Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36",
          "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          "Accept-Language": "zh-CN,zh;q=0.8,en-US;q=0.5,en;q=0.3",
        },
      );

      developer.log("TikTok API Response: ${response.data}", name: "TikTokAPI");

      if (response.data != null && response.data['success'] == true) {
        return VideoModel.fromJson(response.data);
      }

      return null;
    } catch (error) {
      developer.log("Error calling main API with TikTok headers: $error",
          name: "TikTokAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryAlternativeInstagramAPI(String videoLink) async {
    try {
      developer.log("Trying alternative Instagram API: $videoLink",
          name: "InstagramAltAPI");

      final response = await dioHelper.post(
        baseUrl:
            "https://instagram-downloader-download-instagram-videos-stories.p.rapidapi.com",
        path: "/",
        data: {"url": videoLink},
        customHeaders: {
          "x-rapidapi-key": ApiConfig.rapidApiKey,
          "x-rapidapi-host":
              "instagram-downloader-download-instagram-videos-stories.p.rapidapi.com",
          "Content-Type": "application/json",
        },
      );

      developer.log("Instagram Alt API Response: ${response.data}",
          name: "InstagramAltAPI");

      if (response.data != null && response.data['success'] == true) {
        return VideoModel.fromJson(response.data);
      }

      return null;
    } catch (error) {
      developer.log("Alternative Instagram API error: $error",
          name: "InstagramAltAPI");
      return null;
    }
  }

  Future<VideoModel?> _handleInstagramUrl(String videoLink) async {
    try {
      developer.log("Processing Instagram URL: $videoLink",
          name: "InstagramAPI");

      final response = await dioHelper.get(
        path: AppConstants.getVideoEndpoint,
        queryParams: {"url": videoLink},
        customHeaders: {
          "x-rapidapi-key": ApiConfig.rapidApiKey,
          "x-rapidapi-host": "social-media-video-downloader.p.rapidapi.com",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        },
      );

      developer.log("Instagram API Response: ${response.data}",
          name: "InstagramAPI");

      if (response.data != null && response.data['success'] == true) {
        return VideoModel.fromJson(response.data);
      }

      return null;
    } catch (error) {
      developer.log("Error handling Instagram URL: $error",
          name: "InstagramAPI");
      return null;
    }
  }

  Future<VideoModel?> _tryUniversalDownloader(String videoLink) async {
    try {
      developer.log(
          "Universal downloader is currently disabled due to API issues",
          name: "UniversalAPI");
      return null;
    } catch (error) {
      developer.log("Universal downloader error: $error", name: "UniversalAPI");
      return null;
    }
  }

  Future<String?> _resolveShortUrl(String shortUrl) async {
    try {
      developer.log("Attempting to resolve short URL: $shortUrl",
          name: "URLResolver");

      if (!shortUrl.startsWith('http://') && !shortUrl.startsWith('https://')) {
        developer.log("Invalid URL format, skipping resolution: $shortUrl",
            name: "URLResolver");
        return null;
      }

      final Dio urlDio = Dio();
      urlDio.options = BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (status) => status != null && status < 400,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );

      final response = await urlDio.get(
        shortUrl,
        options: Options(
          headers: {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
          },
        ),
      );

      String? finalUrl = response.realUri.toString();
      if (finalUrl.contains('xiaohongshu.com')) {
        developer.log("Successfully resolved to: $finalUrl",
            name: "URLResolver");
        return finalUrl;
      }

      return null;
    } catch (error) {
      developer.log("Error resolving short URL: $error", name: "URLResolver");
      return null;
    }
  }

  String? _extractNoteIdFromShortUrl(String url) {
    try {
      if (url.contains('xhslink.com')) {
        RegExp xhsPattern = RegExp(r'xhslink\.com/[a-zA-Z]/([a-zA-Z0-9]+)');
        Match? match = xhsPattern.firstMatch(url);
        if (match != null) {
          String pathId = match.group(1)!;
          developer.log("Extracted path ID from xhslink: $pathId",
              name: "RedNoteParser");
          return pathId;
        }
      }

      return null;
    } catch (error) {
      developer.log("Error extracting noteId from short URL: $error",
          name: "RedNoteParser");
      return null;
    }
  }
}

// Enhanced RedNote specific data source
class RedNoteVideoRemoteDataSource implements VideoBaseRemoteDataSource {
  final DioHelper dioHelper;

  RedNoteVideoRemoteDataSource({required this.dioHelper});

  @override
  Future<VideoModel> getVideo(String videoLink) async {
    try {
      developer.log("Processing RedNote URL: $videoLink", name: "RedNoteAPI");

      // For now, return a placeholder indicating the feature is in development
      return VideoModel(
        success: false,
        message: AppStrings.redNoteDevelopment,
        srcUrl: videoLink,
        ogUrl: "",
        title: AppStrings.redNoteDetected,
        picture: "",
        images: const [],
        timeTaken: "",
        rId: DateTime.now().millisecondsSinceEpoch.toString(),
        videoLinks: const [],
      );
    } catch (error) {
      developer.log("Error processing RedNote URL: $error", name: "RedNoteAPI");
      rethrow;
    }
  }

  @override
  Future<String> saveVideo({
    required String videoLink,
    required String savePath,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      // Handle image downloads for RedNote galleries
      if (_isImageUrl(videoLink)) {
        await dioHelper.downloadImage(
            savePath: savePath,
            downloadLink: videoLink,
            onReceiveProgress: onReceiveProgress);
      } else {
        await dioHelper.download(
            savePath: savePath,
            downloadLink: videoLink,
            onReceiveProgress: onReceiveProgress);
      }
      return AppStrings.downloadSuccess;
    } catch (error) {
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
