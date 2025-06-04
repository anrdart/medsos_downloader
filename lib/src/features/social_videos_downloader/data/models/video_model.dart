import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_link_model.dart';
import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_stats_model.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video.dart';

class VideoModel extends Video {
  const VideoModel({
    required super.success,
    required super.message,
    required super.srcUrl,
    required super.ogUrl,
    required super.title,
    required super.picture,
    required super.images,
    required super.timeTaken,
    required super.rId,
    required super.videoLinks,
    super.stats,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    // Extract video links from different possible fields in the API response
    List<VideoLinkModel> videoLinks = [];

    // Check for direct video URL fields common in TikTok API responses
    if (json['play'] != null) {
      videoLinks.add(VideoLinkModel(
          quality: _formatQualityName("Standard"),
          link: json['play'].toString()));
    }
    if (json['hdplay'] != null) {
      videoLinks.add(VideoLinkModel(
          quality: _formatQualityName("HD"), link: json['hdplay'].toString()));
    }
    if (json['wmplay'] != null) {
      videoLinks.add(VideoLinkModel(
          quality: _formatQualityName("Watermark"),
          link: json['wmplay'].toString()));
    }

    // RedNote specific video links
    if (json['video_url'] != null) {
      videoLinks.add(VideoLinkModel(
          quality: _formatQualityName("RedNote Video"),
          link: json['video_url'].toString()));
    }

    // Check for links array (if present)
    if (json['links'] != null && json['links'] is List) {
      videoLinks.addAll((json['links'] as List)
          .map((linkJson) => VideoLinkModel(
              quality: _formatQualityName(linkJson['quality'] ?? "Video"),
              link: linkJson['link'] ?? ""))
          .toList());
    }

    // RedNote image processing - convert to video links for consistency
    if (json['image_urls'] != null && json['image_urls'] is List) {
      List<String> imageUrls = List<String>.from(json['image_urls']);
      for (int i = 0; i < imageUrls.length; i++) {
        videoLinks.add(VideoLinkModel(
            quality: _formatQualityName("Image ${i + 1}"), link: imageUrls[i]));
      }
    }

    // Create stats model if needed fields are present
    VideoStatsModel? stats;
    if (json['duration'] != null ||
        json['play_count'] != null ||
        json['likes'] != null) {
      stats = VideoStatsModel(
        videoLenght: json['duration']?.toString() ?? "0",
        viewsCount: json['play_count']?.toString() ??
            json['viewCount']?.toString() ??
            json['likes']?.toString() ??
            "0",
      );
    }

    // Extract images list for RedNote galleries
    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images =
          List<String>.from((json['images'] as List).map((e) => e.toString()));
    } else if (json['image_urls'] != null && json['image_urls'] is List) {
      images = List<String>.from(
          (json['image_urls'] as List).map((e) => e.toString()));
    }

    return VideoModel(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      srcUrl: json["src_url"] ?? "",
      ogUrl: json["og_url"] ?? "",
      title: json["title"] ?? "",
      picture: json["picture"] ?? "",
      images: images,
      timeTaken: json["timeTaken"] ?? "",
      rId: json["r_id"] ?? "",
      videoLinks: videoLinks,
      stats: stats,
    );
  }

  /// Helper function to format video quality names to be more user-friendly
  static String _formatQualityName(String originalQuality) {
    // Handle common quality patterns and make them more readable
    final quality = originalQuality.toLowerCase();

    // Video quality patterns with more detailed descriptions
    if (quality.contains('video_hd_original')) {
      return '📺 Original Quality (Best - No Compression)';
    }
    if (quality.contains('video_hd_540p_normal')) {
      return '📺 High Quality (540p - Recommended)';
    }
    if (quality.contains('video_hd_540p_lowest')) {
      return '📺 Standard Quality (540p - Smaller Size)';
    }
    if (quality.contains('video_hd_720p')) {
      return '📺 HD Quality (720p - High Definition)';
    }
    if (quality.contains('video_hd_1080p')) {
      return '📺 Full HD Quality (1080p - Premium)';
    }
    if (quality.contains('video_hd')) return '📺 HD Video (High Definition)';
    if (quality.contains('hdplay')) {
      return '📺 High Definition Video (Best Quality)';
    }
    if (quality.contains('play')) return '📺 Standard Video (Normal Quality)';
    if (quality.contains('wmplay')) {
      return '📺 Video with Watermark (Contains Logo)';
    }

    // Audio patterns with detailed descriptions
    if (quality.contains('audio')) return '🎵 Audio Only (Music/Sound Track)';
    if (quality.contains('mp3')) return '🎵 Audio MP3 (Music File)';

    // Image patterns with platform info
    if (quality.contains('image')) {
      return '🖼️ $originalQuality (Photo/Picture)';
    }

    // TikTok/Douyin patterns with detailed info
    if (quality.contains('tiktok video quality')) {
      String number = originalQuality.replaceAll(RegExp(r'[^\d]'), '');
      return '📺 TikTok Video Quality ${number.isNotEmpty ? number : ""} (Mobile Optimized)';
    }
    if (quality.contains('tiktok video')) {
      return '📺 TikTok Video (Mobile Format)';
    }

    // RedNote patterns with platform info
    if (quality.contains('rednote video')) {
      return '📺 RedNote Video (Xiaohongshu Format)';
    }

    // Instagram patterns
    if (quality.contains('instagram')) {
      return '📺 Instagram Video (Social Format)';
    }
    if (quality.contains('story')) {
      return '📺 Instagram Story (Vertical Format)';
    }
    if (quality.contains('reel')) return '📺 Instagram Reel (Short Video)';
    if (quality.contains('igtv')) return '📺 IGTV Video (Long Format)';

    // Facebook patterns
    if (quality.contains('facebook')) {
      return '📺 Facebook Video (Social Format)';
    }

    // YouTube patterns
    if (quality.contains('youtube')) {
      return '📺 YouTube Video (Platform Format)';
    }
    if (quality.contains('shorts')) return '📺 YouTube Shorts (Vertical Video)';

    // Quality level patterns with descriptions
    if (quality.contains('ultra')) return '📺 Ultra Quality (4K/Highest)';
    if (quality.contains('high')) return '📺 High Quality (Premium)';
    if (quality.contains('medium')) return '📺 Medium Quality (Balanced)';
    if (quality.contains('low')) return '📺 Low Quality (Fast Download)';
    if (quality.contains('standard')) return '📺 Standard Quality (Normal)';
    if (quality.contains('hd')) return '📺 HD Quality (High Definition)';

    // Generic video patterns with helpful descriptions
    if (quality.contains('video')) return '📺 Video File (Downloadable)';

    // If no pattern matches, return original with video icon and helpful text
    return '📺 $originalQuality (Media File)';
  }
}
