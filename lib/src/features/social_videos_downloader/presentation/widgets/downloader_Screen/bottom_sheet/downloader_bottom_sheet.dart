import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/video.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/video_link.dart';

import '../../../../../../core/common_widgets/custom_elevated_button.dart';
import '../../../../../../core/utils/app_strings.dart';
import '../../../bloc/downloader_bloc/downloader_bloc.dart';
import 'bottom_sheet_header.dart';
import 'count_view.dart';

Future<dynamic> buildDownloadBottomSheet(
  BuildContext context,
  Video video,
) {
  var selectedVideoLink = video.videoLinks.firstWhere(
    (link) => !link.isAudio,
    orElse: () => video.videoLinks.first,
  );
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
                      onChanged: (link) {
                        selectedVideoLink = link;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomElevatedBtn(
                      width: double.infinity,
                      label: AppStrings.download,
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<DownloaderBloc>().add(DownloaderSaveVideo(
                              video: video,
                              selectedLink: selectedVideoLink,
                            ));
                      },
                    ),
                    const SizedBox(height: 10),
                    // On-demand audio-only (MP3): resolved via yt-dlp when tapped.
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.music_note, color: Colors.white),
                      label: const Text(
                        "Audio (MP3)",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context
                            .read<DownloaderBloc>()
                            .add(DownloaderGetAudio(video: video));
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
