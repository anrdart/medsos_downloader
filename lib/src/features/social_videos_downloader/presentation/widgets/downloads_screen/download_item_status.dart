// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_constants.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../domain/entities/download_item.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';
import 'media_actions.dart';
import 'save_to_gallery_dialog.dart';
import 'video_status_widget.dart';

class DownloadItemStatus extends StatelessWidget {
  final DownloadItem item;

  const DownloadItemStatus({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloaderBloc, DownloaderState>(
      buildWhen: (previous, current) {
        // Listen for progress updates for this specific download
        if (current is DownloaderSaveVideoProgress) {
          return current.path == item.path;
        }
        // Listen for other download state changes
        return current is DownloaderSaveVideoSuccess ||
            current is DownloaderSaveVideoFailure ||
            current is DownloaderSaveVideoLoading;
      },
      builder: (context, state) {
        // Get the latest item from the bloc
        final downloaderBloc = context.read<DownloaderBloc>();
        final currentItem = downloaderBloc.newDownloads
                .where((download) => download.path == item.path)
                .firstOrNull ??
            item;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video title
            Text(
              currentItem.videoTitle.isNotEmpty
                  ? currentItem.videoTitle
                  : currentItem.video.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Platform and time info
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(currentItem.platform),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "● ${_getPlatformName(currentItem.platform)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDownloadTime(currentItem.downloadTime),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  _getFileSize(currentItem.path),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status and Actions
            _buildStatusWidget(context, currentItem),
          ],
        );
      },
    );
  }

  Widget _buildStatusWidget(BuildContext context, DownloadItem currentItem) {
    switch (currentItem.status) {
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VideoStatusWidget(
                  label: AppStrings.downloading,
                  icon: Icons.cloud_download,
                  color: AppColors.primaryColor,
                ),
                Text(
                  "${currentItem.progress.toInt()}%",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: currentItem.progress / 100,
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 8),
            // Control buttons for downloading state
            Row(
              children: [
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.pause,
                    color: Colors.orange,
                    onPressed: () {
                      context.read<DownloaderBloc>().add(
                            DownloaderPauseVideo(path: currentItem.path),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.delete,
                    color: AppColors.red,
                    onPressed: () =>
                        _showDeleteConfirmation(context, currentItem),
                  ),
                ),
              ],
            ),
          ],
        );
      case DownloadStatus.paused:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const VideoStatusWidget(
                  label: "Download Paused",
                  icon: Icons.pause_circle,
                  color: Colors.orange,
                ),
                Text(
                  "${currentItem.progress.toInt()}%",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: currentItem.progress / 100,
              backgroundColor: Colors.orange.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 8),
            // Control buttons for paused state
            Row(
              children: [
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.play_arrow,
                    color: AppColors.primaryColor,
                    onPressed: () {
                      context.read<DownloaderBloc>().add(
                            DownloaderResumeVideo(path: currentItem.path),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.delete,
                    color: AppColors.red,
                    onPressed: () =>
                        _showDeleteConfirmation(context, currentItem),
                  ),
                ),
              ],
            ),
          ],
        );
      case DownloadStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VideoStatusWidget(
                  label: AppStrings.downloadSuccess,
                  icon: Icons.cloud_done,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.open_in_new_rounded,
                    color: AppColors.primaryColor,
                    tooltip: 'Open downloaded file',
                    onPressed: () =>
                        openDownloadedMedia(context, currentItem.path),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.save_alt_rounded,
                    color: AppColors.green,
                    onPressed: () => _saveToGallery(context, currentItem.path),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.delete,
                    color: AppColors.red,
                    onPressed: () =>
                        _showDeleteConfirmation(context, currentItem),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VideoStatusWidget(
                  label: AppStrings.downloadFall,
                  icon: Icons.cloud_off,
                  color: AppColors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.restart_alt,
                    color: AppColors.red,
                    onPressed: () {
                      context.read<DownloaderBloc>().add(
                            DownloaderRetryDownload(path: currentItem.path),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IconOnlyButton(
                    icon: Icons.delete,
                    color: AppColors.red,
                    onPressed: () =>
                        _showDeleteConfirmation(context, currentItem),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  static const Map<SocialPlatform, Color> _platformColors = {
    SocialPlatform.facebook: Color(0xFF1877F2),
    SocialPlatform.instagram: Color(0xFFE4405F),
    SocialPlatform.threads: Colors.black,
    SocialPlatform.twitter: Color(0xFF1DA1F2),
    SocialPlatform.youtube: Color(0xFFFF0000),
    SocialPlatform.youtubeMusic: Color(0xFFFF0000),
    SocialPlatform.tiktok: Colors.black,
    SocialPlatform.bilibili: Color(0xFF00A1D6),
    SocialPlatform.unknown: Colors.grey,
  };

  Color _getPlatformColor(SocialPlatform platform) {
    return _platformColors[platform] ?? Colors.grey;
  }

  String _getPlatformName(SocialPlatform platform) {
    return DownloadItem.platformNameOf(platform);
  }

  String _formatDownloadTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else {
      return "${time.day}/${time.month}/${time.year}";
    }
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        if (bytes < 1073741824) {
          return '${(bytes / 1048576).toStringAsFixed(1)} MB';
        }
        return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
      }
    } catch (e) {
      // File might not exist yet during download
    }
    return 'Calculating...';
  }

  void _saveToGallery(BuildContext context, String videoPath) {
    SaveToGalleryDialog.show(context, videoPath);
  }

  void _showDeleteConfirmation(BuildContext context, DownloadItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Download'),
          content: const Text(
              'Do you want to delete this download from history and remove the file?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Delete only from history, keep file
                context.read<DownloaderBloc>().add(
                      DownloaderDeleteDownload(
                          path: item.path, deleteFile: false),
                    );
              },
              child: const Text('Remove from History'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Delete from history and remove file
                context.read<DownloaderBloc>().add(
                      DownloaderDeleteDownload(
                          path: item.path, deleteFile: true),
                    );
              },
              child: const Text('Delete File',
                  style: TextStyle(color: AppColors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  const _IconOnlyButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
