import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video_link.dart';

import '../../../../../../core/common_widgets/custom_elevated_button.dart';
import '../../../../../../core/utils/app_strings.dart';
import '../../../bloc/downloader_bloc/downloader_bloc.dart';
import 'bottom_sheet_header.dart';
import 'count_view.dart';

Future<dynamic> buildDownloadBottomSheet(
  BuildContext context,
  Video video,
) {
  var selectedQuality =
      video.videoLinks.isNotEmpty ? video.videoLinks.first.quality : "";
  return showModalBottomSheet(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BottomSheetHeader(videoData: video),
                    const SizedBox(height: 12),
                    BottomSheetCountItems(
                      videoData: video,
                      onChanged: (newQuality) {
                        selectedQuality = newQuality;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomElevatedBtn(
                      width: double.infinity,
                      label: AppStrings.download,
                      onPressed: () {
                        String actualQuality = selectedQuality;

                        // Extract actual quality from unique display name if it has parentheses
                        if (selectedQuality.contains('(') &&
                            selectedQuality.contains(')')) {
                          actualQuality = selectedQuality
                              .substring(
                                  0, selectedQuality.lastIndexOf('(') - 1)
                              .trim();
                        }

                        VideoLink? selectedVideoLink;

                        // Find the video link that matches
                        // First try to find by exact match with unique name
                        for (int i = 0; i < video.videoLinks.length; i++) {
                          String uniqueName =
                              _getUniqueQualityName(video.videoLinks, i);
                          if (uniqueName == selectedQuality) {
                            selectedVideoLink = video.videoLinks[i];
                            break;
                          }
                        }

                        // Fallback: find by actual quality name
                        if (selectedVideoLink == null) {
                          for (var link in video.videoLinks) {
                            if (link.quality == actualQuality) {
                              selectedVideoLink = link;
                              break;
                            }
                          }
                        }

                        Navigator.pop(context);
                        context.read<DownloaderBloc>().add(DownloaderSaveVideo(
                              video: video,
                              selectedLink: selectedVideoLink?.quality ??
                                  video.videoLinks.first.quality,
                            ));
                      },
                    ),
                    SizedBox(
                        height:
                            MediaQuery.of(context).padding.bottom > 0 ? 8 : 8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

String _getUniqueQualityName(List<VideoLink> videoLinks, int index) {
  String quality = videoLinks[index].quality;

  // Count total occurrences of this quality
  int totalCount = videoLinks.where((l) => l.quality == quality).length;

  // Get current occurrence index
  int currentIndex =
      videoLinks.take(index + 1).where((l) => l.quality == quality).length;

  if (totalCount > 1) {
    return "$quality ($currentIndex)";
  } else {
    return quality;
  }
}
