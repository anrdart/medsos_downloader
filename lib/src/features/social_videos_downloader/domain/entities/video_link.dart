import 'package:equatable/equatable.dart';

enum MediaKind { video, audio, image, gif }

class VideoLink extends Equatable {
  final String id;
  final String quality;
  final String link;
  final int? size;
  final MediaKind mediaKind;
  final String mode;
  final String extension;
  final int? height;
  final bool isDeferred;

  const VideoLink({
    this.id = '',
    required this.quality,
    required this.link,
    this.size,
    MediaKind mediaKind = MediaKind.video,
    bool isAudio = false,
    this.mode = 'video',
    this.extension = '.mp4',
    this.height,
    this.isDeferred = false,
  }) : mediaKind = isAudio ? MediaKind.audio : mediaKind;

  bool get isAudio => mediaKind == MediaKind.audio;
  bool get isImage =>
      mediaKind == MediaKind.image || mediaKind == MediaKind.gif;

  @override
  List<Object?> get props => [
        id,
        quality,
        link,
        size,
        mediaKind,
        mode,
        extension,
        height,
        isDeferred,
      ];

  factory VideoLink.fromJson(Map<String, dynamic> json) {
    final isAudio = json['isAudio'] as bool? ?? false;
    final kindName = json['mediaKind']?.toString();
    final kind = MediaKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => isAudio ? MediaKind.audio : MediaKind.video,
    );
    return VideoLink(
      id: json['id']?.toString() ?? '',
      quality: json['quality']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      size: json['size'] as int?,
      mediaKind: kind,
      mode: json['mode']?.toString() ??
          (kind == MediaKind.audio ? 'audio' : 'video'),
      extension: _normalizeExtension(
        json['extension']?.toString() ??
            (kind == MediaKind.audio ? '.mp3' : '.mp4'),
      ),
      height: json['height'] as int?,
      isDeferred: json['isDeferred'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quality': quality,
        'link': link,
        'size': size,
        'isAudio': isAudio,
        'mediaKind': mediaKind.name,
        'mode': mode,
        'extension': extension,
        'height': height,
        'isDeferred': isDeferred,
      };

  static String _normalizeExtension(String value) {
    if (value.isEmpty) return '.mp4';
    return value.startsWith('.')
        ? value.toLowerCase()
        : '.${value.toLowerCase()}';
  }
}
