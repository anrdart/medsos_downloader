import 'package:equatable/equatable.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/video.dart';

import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/app_enums.dart';

class DownloadItem extends Equatable {
  final Video video;
  final String selectedLink;
  final DownloadStatus status;
  final String path;
  final double progress;
  final SocialPlatform platform;
  final String videoTitle;
  final DateTime downloadTime;
  final String? thumbnailPath;

  DownloadItem({
    required this.video,
    required this.selectedLink,
    required this.status,
    required this.path,
    this.progress = 0.0,
    this.platform = SocialPlatform.unknown,
    this.videoTitle = "",
    this.thumbnailPath,
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
        thumbnailPath,
      ];

  String get platformName => _platformNames[platform] ?? "Unknown";

  DownloadItem copyWith({
    Video? video,
    String? selectedLink,
    DownloadStatus? status,
    String? path,
    double? progress,
    SocialPlatform? platform,
    String? videoTitle,
    DateTime? downloadTime,
    String? thumbnailPath,
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
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

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
      'thumbnailPath': thumbnailPath,
    };
  }

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
      thumbnailPath: json['thumbnailPath'],
    );
  }

  static SocialPlatform detectPlatform(String url) {
    final u = url.toLowerCase();

    for (final entry in _urlPatterns.entries) {
      for (final pattern in entry.value) {
        if (u.contains(pattern)) return entry.key;
      }
    }

    return SocialPlatform.unknown;
  }

  static const Map<SocialPlatform, List<String>> _urlPatterns = {
    SocialPlatform.tiktok: ['tiktok.com', 'douyin.com', 'v.douyin.com'],
    SocialPlatform.instagram: ['instagram.com'],
    SocialPlatform.facebook: ['facebook.com', 'fb.watch', 'fb.com'],
    SocialPlatform.youtube: ['youtube.com', 'youtu.be', 'youtube-nocookie.com'],
    SocialPlatform.twitter: ['twitter.com', 'x.com', 't.co'],
    SocialPlatform.reddit: ['reddit.com', 'redd.it'],
    SocialPlatform.pinterest: ['pinterest.com', 'pin.it'],
    SocialPlatform.snapchat: ['snapchat.com'],
    SocialPlatform.bluesky: ['bsky.app', 'bsky.social'],
    SocialPlatform.twitch: ['twitch.tv', 'clips.twitch.tv'],
    SocialPlatform.vimeo: ['vimeo.com'],
    SocialPlatform.soundcloud: ['soundcloud.com'],
    SocialPlatform.tumblr: ['tumblr.com'],
    SocialPlatform.bilibili: ['bilibili.com', 'b23.tv'],
    SocialPlatform.dailymotion: ['dailymotion.com', 'dai.ly'],
    SocialPlatform.vk: ['vk.com', 'vk.ru'],
    SocialPlatform.ok: ['ok.ru'],
    SocialPlatform.rutube: ['rutube.ru'],
    SocialPlatform.loom: ['loom.com'],
    SocialPlatform.streamable: ['streamable.com'],
    SocialPlatform.newgrounds: ['newgrounds.com'],
  };

  static String platformNameOf(SocialPlatform p) => _platformNames[p] ?? "Unknown";

  static const Map<SocialPlatform, String> _platformNames = {
    SocialPlatform.tiktok: "TikTok",
    SocialPlatform.instagram: "Instagram",
    SocialPlatform.facebook: "Facebook",
    SocialPlatform.youtube: "YouTube",
    SocialPlatform.twitter: "Twitter/X",
    SocialPlatform.reddit: "Reddit",
    SocialPlatform.pinterest: "Pinterest",
    SocialPlatform.snapchat: "Snapchat",
    SocialPlatform.bluesky: "Bluesky",
    SocialPlatform.twitch: "Twitch",
    SocialPlatform.vimeo: "Vimeo",
    SocialPlatform.soundcloud: "SoundCloud",
    SocialPlatform.tumblr: "Tumblr",
    SocialPlatform.bilibili: "Bilibili",
    SocialPlatform.dailymotion: "Dailymotion",
    SocialPlatform.vk: "VK",
    SocialPlatform.ok: "OK.ru",
    SocialPlatform.rutube: "Rutube",
    SocialPlatform.loom: "Loom",
    SocialPlatform.streamable: "Streamable",
    SocialPlatform.newgrounds: "Newgrounds",
    SocialPlatform.unknown: "Unknown",
  };
}
