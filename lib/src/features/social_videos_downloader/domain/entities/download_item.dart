import 'package:equatable/equatable.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video.dart';

import '../../../../core/utils/app_enums.dart';

enum SocialPlatform {
  tiktok,
  instagram,
  facebook,
  youtube,
  rednote,
  snapchat,
  unknown
}

class DownloadItem extends Equatable {
  final Video video;
  final String selectedLink;
  final DownloadStatus status;
  final String path;
  final double progress;
  final SocialPlatform platform;
  final String videoTitle;
  final DateTime downloadTime;

  DownloadItem({
    required this.video,
    required this.selectedLink,
    required this.status,
    required this.path,
    this.progress = 0.0,
    this.platform = SocialPlatform.unknown,
    this.videoTitle = "",
    DateTime? downloadTime,
  }) : downloadTime = downloadTime ?? DateTime.now();

  @override
  List<Object?> get props => [
        video,
        selectedLink,
        status,
        path,
        progress,
        platform,
        videoTitle,
        downloadTime,
      ];

  /// Get platform name as string
  String get platformName {
    switch (platform) {
      case SocialPlatform.tiktok:
        return "TikTok";
      case SocialPlatform.instagram:
        return "Instagram";
      case SocialPlatform.facebook:
        return "Facebook";
      case SocialPlatform.youtube:
        return "YouTube";
      case SocialPlatform.rednote:
        return "RedNote";
      case SocialPlatform.snapchat:
        return "Snapchat";
      case SocialPlatform.unknown:
        return "Unknown";
    }
  }

  DownloadItem copyWith({
    Video? video,
    String? selectedLink,
    DownloadStatus? status,
    String? path,
    double? progress,
    SocialPlatform? platform,
    String? videoTitle,
    DateTime? downloadTime,
  }) {
    return DownloadItem(
      video: video ?? this.video,
      selectedLink: selectedLink ?? this.selectedLink,
      status: status ?? this.status,
      path: path ?? this.path,
      progress: progress ?? this.progress,
      platform: platform ?? this.platform,
      videoTitle: videoTitle ?? this.videoTitle,
      downloadTime: downloadTime ?? this.downloadTime,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'video': video.toJson(),
      'selectedLink': selectedLink,
      'status': status.name,
      'path': path,
      'progress': progress,
      'platform': platform.name,
      'videoTitle': videoTitle,
      'downloadTime': downloadTime.toIso8601String(),
    };
  }

  /// Create from JSON for persistence
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      video: Video.fromJson(json['video']),
      selectedLink: json['selectedLink'],
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.error,
      ),
      path: json['path'],
      progress: json['progress']?.toDouble() ?? 0.0,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.unknown,
      ),
      videoTitle: json['videoTitle'] ?? "",
      downloadTime: DateTime.parse(json['downloadTime']),
    );
  }

  /// Determine platform from video URL
  static SocialPlatform detectPlatform(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('tiktok.com') ||
        lowerUrl.contains('douyin.com') ||
        lowerUrl.contains('v.douyin.com')) {
      return SocialPlatform.tiktok;
    } else if (lowerUrl.contains('instagram.com')) {
      return SocialPlatform.instagram;
    } else if (lowerUrl.contains('facebook.com') ||
        lowerUrl.contains('fb.watch')) {
      return SocialPlatform.facebook;
    } else if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be')) {
      return SocialPlatform.youtube;
    } else if (lowerUrl.contains('xiaohongshu.com') ||
        lowerUrl.contains('xhslink.com') ||
        lowerUrl.contains('rednote')) {
      return SocialPlatform.rednote;
    } else if (lowerUrl.contains('snapchat.com')) {
      return SocialPlatform.snapchat;
    } else {
      return SocialPlatform.unknown;
    }
  }

  /// Get platform icon asset path
  String get platformIcon {
    switch (platform) {
      case SocialPlatform.tiktok:
        return 'assets/images/tiktok.svg';
      case SocialPlatform.instagram:
        return 'assets/images/instagram.svg';
      case SocialPlatform.facebook:
        return 'assets/images/facebook.svg';
      case SocialPlatform.youtube:
        return 'assets/images/youtube.svg';
      case SocialPlatform.rednote:
        return 'assets/images/rednote.svg';
      case SocialPlatform.snapchat:
        return 'assets/images/snapchat.svg';
      case SocialPlatform.unknown:
        return 'assets/images/default_video.svg';
    }
  }
}
