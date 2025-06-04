import 'package:flutter/material.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/utils/app_colors.dart';

class CountView extends StatelessWidget {
  final String count;
  final IconData icon;

  const CountView({
    super.key,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(color: AppColors.primaryColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 10),
          Text(count.toString(),
              style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}

class BottomSheetCountItems extends StatefulWidget {
  final Video videoData;
  final void Function(String)? onChanged;

  const BottomSheetCountItems(
      {super.key, required this.videoData, required this.onChanged});

  @override
  BottomSheetCountItemsState createState() => BottomSheetCountItemsState();
}

class BottomSheetCountItemsState extends State<BottomSheetCountItems> {
  String? selectedQuality;
  List<String> uniqueQualityNames = [];

  @override
  void initState() {
    super.initState();
    _generateUniqueQualityNames();
    // Set initial quality to first unique quality name
    if (uniqueQualityNames.isNotEmpty) {
      selectedQuality = uniqueQualityNames.first;
    }
  }

  void _generateUniqueQualityNames() {
    Map<String, int> qualityCount = {};
    Map<String, int> qualityCurrentIndex = {};

    uniqueQualityNames = widget.videoData.videoLinks.map((link) {
      String quality = link.quality;

      // Count how many times this quality appears
      qualityCount[quality] = (qualityCount[quality] ?? 0) + 1;

      // Track current index for this quality
      int currentIndex = (qualityCurrentIndex[quality] ?? 0) + 1;
      qualityCurrentIndex[quality] = currentIndex;

      // If it's the first occurrence and there will be more, add (1)
      // If it's a subsequent occurrence, add the appropriate number
      if (qualityCount[quality]! > 1 || currentIndex > 1) {
        return "$quality ($currentIndex)";
      } else {
        // Check if this quality will have duplicates later
        int totalCount = widget.videoData.videoLinks
            .where((l) => l.quality == quality)
            .length;
        if (totalCount > 1) {
          return "$quality ($currentIndex)";
        } else {
          return quality;
        }
      }
    }).toList();

    // Fix the count for qualities that have duplicates
    qualityCount.clear();
    qualityCurrentIndex.clear();

    for (int i = 0; i < widget.videoData.videoLinks.length; i++) {
      String quality = widget.videoData.videoLinks[i].quality;

      // Count total occurrences of this quality
      int totalCount =
          widget.videoData.videoLinks.where((l) => l.quality == quality).length;

      // Get current occurrence index
      int currentIndex = widget.videoData.videoLinks
          .take(i + 1)
          .where((l) => l.quality == quality)
          .length;

      if (totalCount > 1) {
        uniqueQualityNames[i] = "$quality ($currentIndex)";
      } else {
        uniqueQualityNames[i] = quality;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.videoData.stats != null)
          Row(
            children: [
              Expanded(
                child: CountView(
                  count: formatViewsCount(
                      int.tryParse(widget.videoData.stats?.viewsCount ?? "")),
                  icon: Icons.remove_red_eye,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: CountView(
                  count: formatVideoLength(
                      int.tryParse(widget.videoData.stats?.videoLenght ?? "")),
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        if (widget.videoData.videoLinks.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedQuality,
                      hint: const Text(
                        'Select Quality',
                        style: TextStyle(color: AppColors.white),
                      ),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.white),
                      dropdownColor: AppColors.primaryColor,
                      isExpanded: true,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      items: uniqueQualityNames.asMap().entries.map((entry) {
                        String uniqueQuality = entry.value;

                        return DropdownMenuItem<String>(
                          value: uniqueQuality,
                          child: Center(
                            child: Text(
                              uniqueQuality,
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedQuality = newValue;
                          // Pass the selected unique quality name to parent
                          widget.onChanged?.call(newValue ?? "");
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          )
      ],
    );
  }

  String formatViewsCount(int? viewsCount) {
    if (viewsCount == null) return "";
    final formatter = NumberFormat.compact();
    return formatter.format(viewsCount);
  }

  String formatVideoLength(int? videoLength) {
    if (videoLength == null) return "";
    final duration = Duration(seconds: videoLength);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return minutes > 0 ? "$minutes min $seconds sec" : "$seconds sec";
  }
}
