part of 'downloader_bloc.dart';

abstract class DownloaderEvent extends Equatable {
  const DownloaderEvent();
}

class DownloaderGetVideo extends DownloaderEvent {
  final String videoLink;

  const DownloaderGetVideo(this.videoLink);

  @override
  List<Object?> get props => [videoLink];
}

class DownloaderSaveVideo extends DownloaderEvent {
  final Video video;
  final VideoLink selectedLink;

  const DownloaderSaveVideo({required this.video, required this.selectedLink});

  @override
  List<Object?> get props => [video, selectedLink];
}

/// Resolve an audio-only (MP3) URL on demand, then download it.
class DownloaderGetAudio extends DownloaderEvent {
  final Video video;

  const DownloaderGetAudio({required this.video});

  @override
  List<Object?> get props => [video];
}

class LoadOldDownloads extends DownloaderEvent {
  @override
  List<Object?> get props => [];
}

class LoadDownloadHistory extends DownloaderEvent {
  @override
  List<Object?> get props => [];
}

class DownloaderPauseVideo extends DownloaderEvent {
  final String path;

  const DownloaderPauseVideo({required this.path});

  @override
  List<Object?> get props => [path];
}

class DownloaderResumeVideo extends DownloaderEvent {
  final String path;

  const DownloaderResumeVideo({required this.path});

  @override
  List<Object?> get props => [path];
}

class DownloaderDeleteDownload extends DownloaderEvent {
  final String path;
  final bool deleteFile;

  const DownloaderDeleteDownload({required this.path, this.deleteFile = true});

  @override
  List<Object?> get props => [path, deleteFile];
}

class DownloaderRetryDownload extends DownloaderEvent {
  final String path;

  const DownloaderRetryDownload({required this.path});

  @override
  List<Object?> get props => [path];
}
