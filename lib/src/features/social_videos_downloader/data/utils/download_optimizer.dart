import 'dart:developer' as developer;

/// Download optimization utilities for better performance
class DownloadOptimizer {
  /// Optimized chunk size for different file types
  static const int videoChunkSize = 8192; // 8KB chunks for videos
  static const int imageChunkSize = 4096; // 4KB chunks for images

  /// Maximum concurrent downloads
  static const int maxConcurrentDownloads = 3;

  /// Progress update throttling
  static const int progressUpdateIntervalMs = 200; // Update every 200ms

  /// File size thresholds for different optimization strategies
  static const int smallFileThreshold = 5 * 1024 * 1024; // 5MB
  static const int largeFileThreshold = 50 * 1024 * 1024; // 50MB

  /// Current active downloads counter
  static int _activeDownloads = 0;

  /// Check if we can start a new download
  static bool canStartDownload() {
    return _activeDownloads < maxConcurrentDownloads;
  }

  /// Register a new download
  static void registerDownload() {
    _activeDownloads++;
    developer.log("Active downloads: $_activeDownloads",
        name: "DownloadOptimizer");
  }

  /// Unregister a completed download
  static void unregisterDownload() {
    if (_activeDownloads > 0) {
      _activeDownloads--;
    }
    developer.log("Active downloads: $_activeDownloads",
        name: "DownloadOptimizer");
  }

  /// Get optimal chunk size based on file type and size
  static int getOptimalChunkSize(bool isImage, int? fileSize) {
    if (isImage) {
      return imageChunkSize;
    }

    if (fileSize != null) {
      if (fileSize < smallFileThreshold) {
        return 4096; // Smaller chunks for small files
      } else if (fileSize > largeFileThreshold) {
        return 16384; // Larger chunks for big files
      }
    }

    return videoChunkSize;
  }

  /// Check if progress update should be throttled
  static bool shouldUpdateProgress(DateTime? lastUpdate) {
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    return now.difference(lastUpdate).inMilliseconds >=
        progressUpdateIntervalMs;
  }

  /// Clean up resources
  static void cleanup() {
    _activeDownloads = 0;
    developer.log("Download optimizer cleaned up", name: "DownloadOptimizer");
  }

  /// Get recommended timeout based on file size
  static Duration getRecommendedTimeout(int? fileSize) {
    if (fileSize == null) {
      return const Duration(minutes: 10); // Default timeout
    }

    if (fileSize < smallFileThreshold) {
      return const Duration(minutes: 5);
    } else if (fileSize > largeFileThreshold) {
      return const Duration(minutes: 30);
    } else {
      return const Duration(minutes: 15);
    }
  }

  /// Validate download URL format
  static bool isValidDownloadUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          uri.hasAuthority &&
          (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get file extension from URL
  static String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();

      if (path.contains('.mp4')) return '.mp4';
      if (path.contains('.mov')) return '.mov';
      if (path.contains('.avi')) return '.avi';
      if (path.contains('.jpg') || path.contains('.jpeg')) return '.jpg';
      if (path.contains('.png')) return '.png';
      if (path.contains('.webp')) return '.webp';
      if (path.contains('.gif')) return '.gif';

      // Default based on URL patterns
      if (url.contains('video') ||
          url.contains('tiktok') ||
          url.contains('douyin')) {
        return '.mp4';
      }
      if (url.contains('image') ||
          url.contains('photo') ||
          url.contains('xiaohongshu')) {
        return '.jpg';
      }

      return '.mp4'; // Default for videos
    } catch (e) {
      return '.mp4';
    }
  }
}
