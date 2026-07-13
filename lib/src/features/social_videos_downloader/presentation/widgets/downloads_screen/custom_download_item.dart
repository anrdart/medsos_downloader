import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_assets.dart';
import '../../../domain/entities/download_item.dart';
import 'download_item_status.dart';

class CustomDownloadsItem extends StatelessWidget {
  final DownloadItem item;
  const CustomDownloadsItem({super.key, required this.item});

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
              child: _buildThumbnail(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DownloadItemStatus(item: item),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    // 1. Local thumbnail file (generated after download)
    if (item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()) {
      return Image.file(
        File(item.thumbnailPath!),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // 2. Network thumbnail from API (TikWM provides cover images)
    final picture = item.video.picture;
    if (picture != null && picture.isNotEmpty && _isValidUrl(picture)) {
      return FadeInImage(
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholderFit: BoxFit.cover,
        image: NetworkImage(picture),
        placeholder: const AssetImage(AppAssets.noInternetImage),
        imageErrorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // 3. Image and GIF files can render their own thumbnail.
    if (DirHelper.mediaTypeOf(item.path) == MediaFileType.image &&
        File(item.path).existsSync()) {
      return Image.file(
        File(item.path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final type = DirHelper.mediaTypeOf(item.path);
    if (type == MediaFileType.audio) {
      return const Icon(Icons.audio_file_rounded, size: 36);
    }
    if (type == MediaFileType.unsupported) {
      return const Icon(Icons.insert_drive_file_rounded, size: 36);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Image.asset(
      AppAssets.noInternetImage,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    );
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme.isNotEmpty &&
        uri.host.isNotEmpty &&
        ['http', 'https'].contains(uri.scheme);
  }
}
