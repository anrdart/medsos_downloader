import '../../domain/entities/video_link.dart';

class VideoLinkModel extends VideoLink {
  const VideoLinkModel({
    super.id,
    required super.quality,
    required super.link,
    super.size,
    super.mediaKind,
    super.isAudio,
    super.mode,
    super.extension,
    super.height,
    super.isDeferred,
  });

  factory VideoLinkModel.fromJson(Map<String, dynamic> json) {
    final link = VideoLink.fromJson(json);
    return VideoLinkModel(
      id: link.id,
      quality: link.quality,
      link: link.link,
      size: link.size,
      mediaKind: link.mediaKind,
      mode: link.mode,
      extension: link.extension,
      height: link.height,
      isDeferred: link.isDeferred,
    );
  }
}
