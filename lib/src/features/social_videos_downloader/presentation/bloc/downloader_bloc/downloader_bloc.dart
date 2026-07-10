import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/helpers/permission_helper.dart';
import '../../../domain/entities/download_item.dart';
import '../../../domain/entities/video_item.dart';
import '../../../domain/usecase/get_video_usecase.dart';
import '../../../domain/usecase/save_video_usecase.dart';

part 'downloader_event.dart';

part 'downloader_state.dart';

class DownloaderBloc extends Bloc<DownloaderEvent, DownloaderState> {
  final GetVideoUseCase getVideoUseCase;
  final SaveVideoUseCase saveVideoUseCase;
  static const String _downloadHistoryKey = 'download_history';

  DownloaderBloc({
    required this.getVideoUseCase,
    required this.saveVideoUseCase,
  }) : super(DownloaderInitial()) {
    on<LoadOldDownloads>(_loadOldDownloads);
    on<LoadDownloadHistory>(_loadDownloadHistory);
    on<DownloaderGetVideo>(_getVideo);
    on<DownloaderSaveVideo>(_saveVideo);
    on<DownloaderPauseVideo>(_pauseVideo);
    on<DownloaderResumeVideo>(_resumeVideo);
    on<DownloaderDeleteDownload>(_deleteDownload);
    on<DownloaderRetryDownload>(_retryDownload);

    add(LoadDownloadHistory());
  }

  List<DownloadItem> newDownloads = [];

  // CancelToken per download path - used for actual HTTP cancellation
  final Map<String, CancelToken> _cancelTokens = {};

  Future<void> _getVideo(
    DownloaderGetVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    emit(const DownloaderGetVideoLoading());
    final result = await getVideoUseCase(event.videoLink);
    result.fold(
      (left) => emit(DownloaderGetVideoFailure(left.message)),
      (right) => emit(DownloaderGetVideoSuccess(right)),
    );
  }

  Future<void> _saveVideo(
    DownloaderSaveVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    bool checkPermissions = await PermissionsHelper.checkPermission();
    if (!checkPermissions) {
      emit(DownloaderSaveVideoFailure(AppStrings.permissionsRequired));
      return;
    }

    final selectedVideoLink = event.video.videoLinks
        .firstWhere((videoLink) => videoLink.quality == event.selectedLink);
    final selectedLink = selectedVideoLink.link;
    final path = await _getPathById(event.video.rId,
        quality: event.selectedLink,
        originalLink: selectedLink,
        isAudio: selectedVideoLink.isAudio);

    final platform = DownloadItem.detectPlatform(event.video.srcUrl);
    final videoTitle = _extractVideoTitle(event.video.title);

    DownloadItem item = DownloadItem(
      video: event.video,
      selectedLink: selectedLink,
      status: DownloadStatus.downloading,
      path: path,
      progress: 0.0,
      platform: platform,
      videoTitle: videoTitle,
      downloadTime: DateTime.now(),
    );

    int index = _checkIfItemIsExistInDownloads(item);
    _addItem(index, item);
    await _saveDownloadHistory();
    emit(const DownloaderSaveVideoLoading());

    // Create CancelToken for this download
    final cancelToken = CancelToken();
    _cancelTokens[path] = cancelToken;

    // Progress callback - no broken checks, just throttle by time
    DateTime? lastProgressUpdate;
    void onProgressUpdate(int received, int total) {
      if (total > 0) {
        final now = DateTime.now();
        if (lastProgressUpdate != null &&
            now.difference(lastProgressUpdate!).inMilliseconds < 200) {
          return;
        }
        lastProgressUpdate = now;

        double progress = (received / total) * 100;
        progress = progress.clamp(1.0, 99.0);

        _updateItem(
            index,
            item.copyWith(
              status: DownloadStatus.downloading,
              progress: progress,
            ));

        if (progress % 10 < 1) {
          _saveDownloadHistory();
        }

        emit(DownloaderSaveVideoProgress(progress: progress, path: path));
      }
    }

    SaveVideoParams params = SaveVideoParams(
      savePath: path,
      videoLink: selectedLink,
      cancelToken: cancelToken,
      onReceiveProgress: onProgressUpdate,
    );

    final result = await saveVideoUseCase.call(params);
    _cancelTokens.remove(path);

    result.fold(
      (failure) {
        // Don't mark as error if it was cancelled (paused)
        if (cancelToken.isCancelled) return;

        _updateItem(
            index,
            item.copyWith(
              status: DownloadStatus.error,
              progress: 0.0,
            ));
        _saveDownloadHistory();
        emit(DownloaderSaveVideoFailure(failure.message));
      },
      (right) async {
        String? thumbPath;
        if (!_isImageUrl(path)) {
          thumbPath = await _generateThumbnail(path);
        }

        _updateItem(
            index,
            item.copyWith(
              status: DownloadStatus.success,
              progress: 100.0,
              thumbnailPath: thumbPath,
            ));
        _saveDownloadHistory();
        emit(DownloaderSaveVideoSuccess(message: right, path: path));
      },
    );
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        quality: 50,
        maxWidth: 200,
      );
      return thumb;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getPathById(String id,
      {String? quality, String? originalLink, bool isAudio = false}) async {
    final appPath = await DirHelper.getAppPath();

    String extension = ".mp4";

    if (isAudio) {
      extension = ".mp3";
    } else if (originalLink != null && _isImageUrl(originalLink)) {
      if (originalLink.toLowerCase().contains('.jpg') ||
          originalLink.toLowerCase().contains('.jpeg')) {
        extension = ".jpg";
      } else if (originalLink.toLowerCase().contains('.png')) {
        extension = ".png";
      } else if (originalLink.toLowerCase().contains('.webp')) {
        extension = ".webp";
      } else {
        extension = ".jpg";
      }
    }

    String filename = id;
    if (quality != null && quality.startsWith("Image")) {
      filename = "${id}_${quality.replaceAll(' ', '_')}";
    }

    return "$appPath/$filename$extension";
  }

  bool _isImageUrl(String url) {
    return url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.webp');
  }

  void _updateItem(int index, DownloadItem item) {
    if (index == -1) {
      newDownloads.last = item;
    } else {
      newDownloads[index] = item;
    }
  }

  void _addItem(int index, DownloadItem item) {
    if (index == -1) {
      newDownloads.add(item);
    } else {
      newDownloads[index] = item.copyWith(status: DownloadStatus.downloading);
    }
  }

  int _checkIfItemIsExistInDownloads(DownloadItem item) {
    int index = -1;
    for (int i = 0; i < newDownloads.length; i++) {
      if (newDownloads[i].video == item.video) {
        index = i;
        return index;
      }
    }
    return index;
  }

  List<VideoItem> oldDownloads = [];

  Future<void> _loadOldDownloads(
    LoadOldDownloads event,
    Emitter<DownloaderState> emit,
  ) async {
    emit(const OldDownloadsLoading());
    oldDownloads.clear();
    final path = await DirHelper.getAppPath();
    final directory = Directory(path);
    final files = await directory.list().toList();
    final newDownloadedVideosPaths = newDownloads.map((e) => e.path);
    for (final file in files) {
      if (file is File && file.path.endsWith('.mp4')) {
        final videoPath = file.path;
        if (newDownloadedVideosPaths.contains(videoPath)) continue;
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          quality: 30,
        );
        oldDownloads
            .add(VideoItem(path: videoPath)..thumbnailPath = thumbnailPath);
      }
    }
    emit(OldDownloadsLoadingSuccess(downloads: oldDownloads));
  }

  String _extractVideoTitle(String title) {
    if (title.isEmpty) return "Downloaded Video";
    // Only strip URLs, keep everything else (hashtags, mentions are part of title)
    String clean = title.replaceAll(RegExp(r'https?://\S+'), '').trim();
    return clean.isNotEmpty ? clean : "Downloaded Video";
  }

  Future<void> _loadDownloadHistory(
    LoadDownloadHistory event,
    Emitter<DownloaderState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_downloadHistoryKey);

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        newDownloads =
            historyList.map((item) => DownloadItem.fromJson(item)).toList();

        for (int i = 0; i < newDownloads.length; i++) {
          final file = File(newDownloads[i].path);
          if (!file.existsSync()) {
            newDownloads[i] =
                newDownloads[i].copyWith(status: DownloadStatus.error);
          } else if (newDownloads[i].status == DownloadStatus.downloading) {
            newDownloads[i] =
                newDownloads[i].copyWith(status: DownloadStatus.paused);
          }
        }

        await _saveDownloadHistory();
        emit(DownloadHistoryLoaded(downloads: newDownloads));
      }
    } catch (e) {
      newDownloads = [];
    }
  }

  Future<void> _saveDownloadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          json.encode(newDownloads.map((item) => item.toJson()).toList());
      await prefs.setString(_downloadHistoryKey, historyJson);
    } catch (e) {
      // Silent
    }
  }

  Future<void> _pauseVideo(
    DownloaderPauseVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    final index = newDownloads.indexWhere((item) => item.path == event.path);
    if (index != -1 &&
        newDownloads[index].status == DownloadStatus.downloading) {
      // Cancel the actual HTTP request
      _cancelTokens[event.path]?.cancel("Paused by user");
      _cancelTokens.remove(event.path);

      _updateItem(
          index, newDownloads[index].copyWith(status: DownloadStatus.paused));
      await _saveDownloadHistory();
      emit(DownloaderVideoPaused(path: event.path));
    }
  }

  Future<void> _resumeVideo(
    DownloaderResumeVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    final index = newDownloads.indexWhere((item) => item.path == event.path);
    if (index != -1 && newDownloads[index].status == DownloadStatus.paused) {
      final item = newDownloads[index];
      add(DownloaderSaveVideo(
          video: item.video, selectedLink: item.selectedLink));
    }
  }

  Future<void> _deleteDownload(
    DownloaderDeleteDownload event,
    Emitter<DownloaderState> emit,
  ) async {
    try {
      final index = newDownloads.indexWhere((item) => item.path == event.path);
      if (index != -1) {
        final item = newDownloads[index];

        // Cancel active download if running
        if (item.status == DownloadStatus.downloading) {
          _cancelTokens[event.path]?.cancel("Deleted by user");
          _cancelTokens.remove(event.path);
        }

        newDownloads.removeAt(index);

        if (event.deleteFile) {
          final file = File(event.path);
          if (file.existsSync()) {
            await file.delete();
          }
        }

        await _saveDownloadHistory();
        emit(DownloaderVideoDeleted(path: event.path));
      }
    } catch (e) {
      emit(DownloaderSaveVideoFailure(
          "Failed to delete download: ${e.toString()}"));
    }
  }

  Future<void> _retryDownload(
    DownloaderRetryDownload event,
    Emitter<DownloaderState> emit,
  ) async {
    final index = newDownloads.indexWhere((item) => item.path == event.path);
    if (index != -1) {
      final item = newDownloads[index];

      _updateItem(index,
          item.copyWith(status: DownloadStatus.downloading, progress: 0.0));
      await _saveDownloadHistory();

      add(DownloaderSaveVideo(
          video: item.video, selectedLink: item.selectedLink));
    }
  }
}
