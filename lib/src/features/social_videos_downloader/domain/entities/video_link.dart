import 'package:equatable/equatable.dart';

class VideoLink extends Equatable {
  final String quality;
  final String link;

  /// File size in bytes if known (null = unknown).
  final int? size;

  /// True when this link is audio-only (saved as .mp3).
  final bool isAudio;

  /// Server download mode hint: "video" (default) or "audio".
  final String mode;

  const VideoLink({
    required this.quality,
    required this.link,
    this.size,
    this.isAudio = false,
    this.mode = 'video',
  });

  @override
  List<Object?> get props => [quality, link, size, isAudio, mode];

  factory VideoLink.fromJson(Map<String, dynamic> json) {
    return VideoLink(
      quality: json['quality'],
      link: json['link'],
      size: json['size'] as int?,
      isAudio: json['isAudio'] as bool? ?? false,
      mode: json['mode'] as String? ?? 'video',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'link': link,
      'size': size,
      'isAudio': isAudio,
      'mode': mode,
    };
  }
}
