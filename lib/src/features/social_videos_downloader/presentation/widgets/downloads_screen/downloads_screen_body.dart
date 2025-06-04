import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../screens/downloads_screen.dart';
import '../../../domain/entities/download_item.dart';
import 'new_downloads_section.dart';
import 'old_downloads_section.dart';

class DownloadsScreenBody extends StatelessWidget {
  final SortOption selectedSort;
  final SocialPlatform? selectedPlatform;

  const DownloadsScreenBody({
    super.key,
    required this.selectedSort,
    required this.selectedPlatform,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          NewDownloadsSection(
            selectedSort: selectedSort,
            selectedPlatform: selectedPlatform,
          ),
          const Divider(
              color: AppColors.primaryColor, thickness: .1, height: 10),
          OldDownloadsSection(
            selectedSort: selectedSort,
            selectedPlatform: selectedPlatform,
          ),
        ],
      ),
    );
  }
}
