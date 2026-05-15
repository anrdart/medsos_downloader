import 'dart:io';
import 'package:flutter/material.dart';

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

    // 3. If it's an image file, show itself as thumbnail
    final path = item.path.toLowerCase();
    if (path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp')) {
      if (File(item.path).existsSync()) {
        return Image.file(
          File(item.path),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
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
