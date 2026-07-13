import 'package:equatable/equatable.dart';

import 'video_link.dart';

class ResolvedMedia extends Equatable {
  final String url;
  final String filename;
  final String extension;
  final MediaKind mediaKind;

  const ResolvedMedia({
    required this.url,
    required this.filename,
    required this.extension,
    required this.mediaKind,
  });

  @override
  List<Object?> get props => [url, filename, extension, mediaKind];
}
