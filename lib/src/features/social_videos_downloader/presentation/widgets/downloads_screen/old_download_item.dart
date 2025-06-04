// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../../../../core/utils/app_assets.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../config/routes_manager.dart';
import '../../../../../core/helpers/dir_helper.dart';
import '../../../domain/entities/video_item.dart';

class OldDownloadItem extends StatelessWidget {
  final VideoItem videoItem;

  const OldDownloadItem({super.key, required this.videoItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                AppAssets.noInternetImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced title extraction
                Text(
                  _extractTitleFromFilename(videoItem.path),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // File info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "● Downloaded",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getFileModifiedTime(videoItem.path),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getFileSize(videoItem.path),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons similar to new downloads success state
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.play_circle_fill_rounded,
                        color: AppColors.primaryColor,
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            Routes.viewVideo,
                            arguments: videoItem.path,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.save_alt_rounded,
                        color: AppColors.green,
                        onPressed: () =>
                            _saveToGallery(context, videoItem.path),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractTitleFromFilename(String filePath) {
    try {
      // Get filename without extension
      String filename = path.basenameWithoutExtension(filePath);

      // Remove timestamp patterns (if any)
      filename = filename.replaceAll(
          RegExp(r'_\d{13}'), ''); // Remove 13-digit timestamps
      filename = filename.replaceAll(
          RegExp(r'_\d{10}'), ''); // Remove 10-digit timestamps

      // Handle special filename patterns
      if (filename.contains('Image_')) {
        return "RedNote ${filename.replaceAll('_', ' ')}";
      }

      // Replace underscores with spaces and clean up
      filename = filename.replaceAll('_', ' ');

      // Limit length
      if (filename.length > 50) {
        filename = "${filename.substring(0, 47)}...";
      }

      return filename.isNotEmpty ? filename : "Downloaded Video";
    } catch (e) {
      return "Downloaded Video";
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
      // Handle error
    }
    return 'Unknown size';
  }

  String _getFileModifiedTime(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final lastModified = file.lastModifiedSync();
        return '${lastModified.toString().split(' ')[0]} ${lastModified.toString().split(' ')[1].substring(0, 5)}';
      }
    } catch (e) {
      // Handle error
    }
    return 'Unknown time';
  }

  void _saveToGallery(BuildContext context, String videoPath) async {
    try {
      await DirHelper.saveVideoToGallery(videoPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text("Video saved to gallery successfully!"),
              ],
            ),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 8),
                Text("Failed to save to gallery: ${e.toString()}"),
              ],
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return Material(
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
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
