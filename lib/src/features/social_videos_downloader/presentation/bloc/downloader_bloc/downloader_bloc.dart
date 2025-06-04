import 'dart:async';
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

    // Load download history on initialization
    add(LoadDownloadHistory());
  }

  List<DownloadItem> newDownloads = [];

  // Track active downloads for pause/resume functionality
  Map<String, bool> pausedDownloads = {};

  // Track active download cancel tokens for proper cancellation
  Map<String, CancelToken> activeDownloads = {};

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

    final selectedLink = event.video.videoLinks
        .firstWhere((videoLink) => videoLink.quality == event.selectedLink)
        .link;
    final path = await _getPathById(event.video.rId,
        quality: event.selectedLink, originalLink: selectedLink);
    final link = _processLink(selectedLink);

    // Detect platform and extract video title
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
    await _saveDownloadHistory(); // Save to persistent storage
    emit(const DownloaderSaveVideoLoading());

    // Create optimized progress callback for real-time updates
    DateTime? lastProgressUpdate;
    void onProgressUpdate(int received, int total) {
      // Check if download was paused or cancelled
      if (pausedDownloads.containsKey(path) ||
          !activeDownloads.containsKey(path)) {
        return; // Stop progress updates if paused or cancelled
      }

      if (total > 0) {
        // Throttle progress updates to prevent UI blocking
        final now = DateTime.now();
        if (lastProgressUpdate != null &&
            now.difference(lastProgressUpdate!).inMilliseconds < 100) {
          return; // Skip update if less than 100ms since last update
        }
        lastProgressUpdate = now;

        double progress = (received / total) * 100;
        // Ensure progress doesn't exceed 100% and minimum 1% when started
        progress = progress.clamp(1.0, 99.0);

        _updateItem(
            index,
            item.copyWith(
              status: DownloadStatus.downloading,
              progress: progress,
            ));

        // Save progress periodically (every 10%)
        if (progress % 10 < 1) {
          _saveDownloadHistory();
        }

        // Emit state update for UI refresh
        emit(DownloaderSaveVideoProgress(progress: progress, path: path));
      }
    }

    SaveVideoParams params = SaveVideoParams(
      savePath: path,
      videoLink: link,
      onReceiveProgress: onProgressUpdate,
    );

    final result = await saveVideoUseCase.call(params);
    result.fold(
      (failure) {
        _updateItem(
            index,
            item.copyWith(
              status: DownloadStatus.error,
              progress: 0.0,
            ));
        _saveDownloadHistory(); // Save error state
        emit(DownloaderSaveVideoFailure(failure.message));
      },
      (right) {
        _updateItem(
            index,
            item.copyWith(
              status: DownloadStatus.success,
              progress: 100.0,
            ));
        _saveDownloadHistory(); // Save success state
        emit(DownloaderSaveVideoSuccess(message: right, path: path));
      },
    );
  }

  String _processLink(String link) {
    // Check if it's an image link (for RedNote)
    if (_isImageUrl(link)) {
      return link; // Don't add .mp4 for images
    }

    bool isCorrectLink = link.endsWith(".mp4");
    if (!isCorrectLink) link += ".mp4";
    return link;
  }

  Future<String> _getPathById(String id,
      {String? quality, String? originalLink}) async {
    final appPath = await DirHelper.getAppPath();

    // Determine file extension based on content type
    String extension = ".mp4"; // default for videos

    if (originalLink != null && _isImageUrl(originalLink)) {
      // For RedNote images, use appropriate extension
      if (originalLink.toLowerCase().contains('.jpg') ||
          originalLink.toLowerCase().contains('.jpeg')) {
        extension = ".jpg";
      } else if (originalLink.toLowerCase().contains('.png')) {
        extension = ".png";
      } else if (originalLink.toLowerCase().contains('.webp')) {
        extension = ".webp";
      } else {
        extension = ".jpg"; // default for images
      }
    }

    // Add quality suffix for multiple files from same source (RedNote galleries)
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

  _updateItem(int index, DownloadItem item) {
    if (index == -1) {
      newDownloads.last = item;
    } else {
      newDownloads[index] = item;
    }
  }

  _addItem(int index, DownloadItem item) {
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
    // Clean and extract meaningful title from video metadata
    if (title.isEmpty) return "Downloaded Video";

    // Remove common social media patterns
    String cleanTitle = title
        .replaceAll(RegExp(r'#\w+'), '') // Remove hashtags
        .replaceAll(RegExp(r'@\w+'), '') // Remove mentions
        .replaceAll(RegExp(r'https?://\S+'), '') // Remove URLs
        .trim();

    // Limit title length for UI
    if (cleanTitle.length > 50) {
      cleanTitle = "${cleanTitle.substring(0, 47)}...";
    }

    return cleanTitle.isNotEmpty ? cleanTitle : "Downloaded Video";
  }

  /// Load download history from persistent storage
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

        // Verify files still exist and update statuses
        for (int i = 0; i < newDownloads.length; i++) {
          final file = File(newDownloads[i].path);
          if (!file.existsSync()) {
            // File was deleted externally, update status
            newDownloads[i] =
                newDownloads[i].copyWith(status: DownloadStatus.error);
          } else if (newDownloads[i].status == DownloadStatus.downloading) {
            // App was closed while downloading, mark as paused
            newDownloads[i] =
                newDownloads[i].copyWith(status: DownloadStatus.paused);
          }
        }

        await _saveDownloadHistory();
        emit(DownloadHistoryLoaded(downloads: newDownloads));
      }
    } catch (e) {
      // Handle error silently - start with empty history
      newDownloads = [];
    }
  }

  /// Save download history to persistent storage
  Future<void> _saveDownloadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          json.encode(newDownloads.map((item) => item.toJson()).toList());
      await prefs.setString(_downloadHistoryKey, historyJson);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Pause video download
  Future<void> _pauseVideo(
    DownloaderPauseVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    final index = newDownloads.indexWhere((item) => item.path == event.path);
    if (index != -1 &&
        newDownloads[index].status == DownloadStatus.downloading) {
      pausedDownloads[event.path] = true;
      _updateItem(
          index, newDownloads[index].copyWith(status: DownloadStatus.paused));
      await _saveDownloadHistory();
      emit(DownloaderVideoPaused(path: event.path));
    }
  }

  /// Resume video download
  Future<void> _resumeVideo(
    DownloaderResumeVideo event,
    Emitter<DownloaderState> emit,
  ) async {
    final index = newDownloads.indexWhere((item) => item.path == event.path);
    if (index != -1 && newDownloads[index].status == DownloadStatus.paused) {
      pausedDownloads.remove(event.path);

      // Restart download from current progress
      final item = newDownloads[index];
      add(DownloaderSaveVideo(
          video: item.video, selectedLink: item.selectedLink));
    }
  }

  /// Delete download from history and optionally from disk
  Future<void> _deleteDownload(
    DownloaderDeleteDownload event,
    Emitter<DownloaderState> emit,
  ) async {
    try {
      final index = newDownloads.indexWhere((item) => item.path == event.path);
      if (index != -1) {
        final item = newDownloads[index];

        // Remove from list
        newDownloads.removeAt(index);

        // Delete file if requested and exists
        if (event.deleteFile) {
          final file = File(event.path);
          if (file.existsSync()) {
            await file.delete();
          }
        }

        // Cancel if currently downloading
        if (item.status == DownloadStatus.downloading) {
          pausedDownloads[event.path] =
              true; // This will signal download to stop
        }

        await _saveDownloadHistory();
        emit(DownloaderVideoDeleted(path: event.path));
      }
    } catch (e) {
      emit(DownloaderSaveVideoFailure(
          "Failed to delete download: ${e.toString()}"));
    }
  }

  /// Retry failed download
  Future<void> _retryDownload(
    DownloaderRetryDownload event,
    Emitter<DownloaderState> emit,
  ) async {
    final index = newDownloads.indexWhere((item) => item.path == event.path);
    if (index != -1) {
      final item = newDownloads[index];

      // Reset progress and status
      _updateItem(index,
          item.copyWith(status: DownloadStatus.downloading, progress: 0.0));
      await _saveDownloadHistory();

      // Restart download
      add(DownloaderSaveVideo(
          video: item.video, selectedLink: item.selectedLink));
    }
  }
}
