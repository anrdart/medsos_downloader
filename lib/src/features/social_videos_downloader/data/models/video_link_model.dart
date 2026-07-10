import '../../domain/entities/video_link.dart';

class VideoLinkModel extends VideoLink {
  const VideoLinkModel({
    required super.quality,
    required super.link,
    super.size,
    super.isAudio,
    super.mode,
  });

  factory VideoLinkModel.fromJson(Map<String, dynamic> json) {
    return VideoLinkModel(
      quality: json["quality"]?.toString() ?? "",
      link: json["link"]?.toString() ?? "",
      size: json["size"] is int ? json["size"] as int : null,
      isAudio: json["isAudio"] as bool? ?? false,
      mode: json["mode"]?.toString() ?? "video",
    );
  }
}
