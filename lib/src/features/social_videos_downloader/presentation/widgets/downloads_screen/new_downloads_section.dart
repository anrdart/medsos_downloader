import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/downloader_bloc/downloader_bloc.dart';
import '../../screens/downloads_screen.dart';
import '../../../domain/entities/download_item.dart';
import 'custom_download_item.dart';

class NewDownloadsSection extends StatelessWidget {
  final SortOption selectedSort;
  final SocialPlatform? selectedPlatform;

  const NewDownloadsSection({
    super.key,
    required this.selectedSort,
    required this.selectedPlatform,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloaderBloc, DownloaderState>(
      builder: (context, state) {
        final newDownloads = context.read<DownloaderBloc>().newDownloads;

        // Apply filters and sorting
        final filteredDownloads = _applyFiltersAndSort(newDownloads);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: List.generate(
              filteredDownloads.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: CustomDownloadsItem(
                  item: filteredDownloads[index],
                ),
              ),
            ).toList(),
          ),
        );
      },
    );
  }

  List<DownloadItem> _applyFiltersAndSort(List<DownloadItem> downloads) {
    List<DownloadItem> filtered = List.from(downloads);

    // Apply platform filter
    if (selectedPlatform != null) {
      filtered =
          filtered.where((item) => item.platform == selectedPlatform).toList();
    }

    // Apply sorting
    switch (selectedSort) {
      case SortOption.newest:
        filtered.sort((a, b) => b.downloadTime.compareTo(a.downloadTime));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.downloadTime.compareTo(b.downloadTime));
        break;
      case SortOption.platform:
        filtered.sort((a, b) => a.platformName.compareTo(b.platformName));
        break;
    }

    return filtered;
  }
}
