import 'package:flutter/material.dart';

import '../../../../../core/utils/app_assets.dart';
import '../../../domain/entities/download_item.dart';
import 'download_item_status.dart';

class CustomDownloadsItem extends StatelessWidget {
  final DownloadItem item;
  const CustomDownloadsItem({super.key, required this.item});

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }

    try {
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
        return false;
      }
      return ['http', 'https'].contains(uri.scheme.toLowerCase());
    } catch (e) {
      return false;
    }
  }




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
              child: _isValidImageUrl(item.video.picture)
                  ? FadeInImage(
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholderFit: BoxFit.cover,
                      image: NetworkImage(item.video.picture!),
                      placeholder: const AssetImage(AppAssets.noInternetImage),
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          AppAssets.noInternetImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      AppAssets.noInternetImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
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
}
