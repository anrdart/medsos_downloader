// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../../core/services/pip_service.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_enums.dart';
import '../../../domain/entities/download_item.dart';
import 'custom_download_item.dart';

class ResponsiveDownloadWidget extends StatelessWidget {
  final List<DownloadItem> downloads;
  final ScrollController? scrollController;

  const ResponsiveDownloadWidget({
    super.key,
    required this.downloads,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPipMode = PipService.instance.isPipModeByDimensions(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        if (isPipMode) {
          return _buildPipModeLayout(context, constraints);
        } else {
          return _buildNormalLayout(context, constraints);
        }
      },
    );
  }

  Widget _buildPipModeLayout(BuildContext context, BoxConstraints constraints) {
    // Simplified layout for PIP mode with minimal UI
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Compact header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.download,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Downloads (${downloads.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          // Compact download list
          Expanded(
            child: downloads.isEmpty
                ? _buildEmptyStatePip()
                : ListView.builder(
                    controller: scrollController,
                    itemCount: downloads.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCompactDownloadItem(downloads[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalLayout(BuildContext context, BoxConstraints constraints) {
    // Normal layout for regular screen sizes
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: downloads.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              controller: scrollController,
              itemCount: downloads.length,
              padding: const EdgeInsets.symmetric(vertical: 16),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return CustomDownloadsItem(item: downloads[index]);
              },
            ),
    );
  }

  Widget _buildCompactDownloadItem(DownloadItem item) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Compact thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey[300],
              child: item.video.picture != null
                  ? Image.network(
                      item.video.picture!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.video_library,
                          size: 20,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.video_library,
                      size: 20,
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Compact info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.videoTitle.isNotEmpty
                      ? item.videoTitle
                      : item.video.title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(item.platform),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.platformName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildCompactStatusIndicator(item),
                  ],
                ),
              ],
            ),
          ),
          // Compact progress
          if (item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.paused)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: item.progress / 100,
                strokeWidth: 2,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(item.status),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusIndicator(DownloadItem item) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(item.status),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEmptyStatePip() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 24,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No downloads',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Download some videos to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return Colors.black;
      case SocialPlatform.instagram:
        return Colors.pink;
      case SocialPlatform.facebook:
        return Colors.blue;
      case SocialPlatform.youtube:
        return Colors.red;
      case SocialPlatform.rednote:
        return Colors.red.shade600;
      case SocialPlatform.snapchat:
        return Colors.yellow.shade600;
      case SocialPlatform.unknown:
        return Colors.grey;
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.primaryColor;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.success:
        return AppColors.green;
      case DownloadStatus.error:
        return AppColors.red;
    }
  }
}
