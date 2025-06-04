// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../domain/entities/download_item.dart';

enum SortOption { newest, oldest, platform }

class DownloadsFilterBar extends StatelessWidget {
  final SortOption selectedSort;
  final SocialPlatform? selectedPlatform;
  final Function(SortOption) onSortChanged;
  final Function(SocialPlatform?) onPlatformChanged;
  final int totalDownloads;

  const DownloadsFilterBar({
    super.key,
    required this.selectedSort,
    required this.selectedPlatform,
    required this.onSortChanged,
    required this.onPlatformChanged,
    required this.totalDownloads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with total count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloads ($totalDownloads)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => _showFilterBottomSheet(context),
                icon: const Icon(
                  Icons.filter_list,
                  color: AppColors.primaryColor,
                ),
                tooltip: 'Filter & Sort',
              ),
            ],
          ),
          // Quick filters
          if (selectedPlatform != null || selectedSort != SortOption.newest)
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Sort chip
                  if (selectedSort != SortOption.newest)
                    _buildFilterChip(
                      context,
                      label: _getSortLabel(selectedSort),
                      icon: Icons.sort,
                      onRemove: () => onSortChanged(SortOption.newest),
                    ),

                  // Platform chip
                  if (selectedPlatform != null) ...[
                    if (selectedSort != SortOption.newest)
                      const SizedBox(width: 8),
                    _buildPlatformChip(
                      context,
                      platform: selectedPlatform!,
                      onRemove: () => onPlatformChanged(null),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(
    BuildContext context, {
    required SocialPlatform platform,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getPlatformColor(platform).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getPlatformColor(platform).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            _getPlatformIcon(platform),
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              _getPlatformColor(platform),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getPlatformName(platform),
            style: TextStyle(
              fontSize: 12,
              color: _getPlatformColor(platform),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: _getPlatformColor(platform),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedSort: selectedSort,
        selectedPlatform: selectedPlatform,
        onSortChanged: onSortChanged,
        onPlatformChanged: onPlatformChanged,
      ),
    );
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.platform:
        return 'By Platform';
    }
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

  String _getPlatformIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return 'assets/images/tiktok.svg';
      case SocialPlatform.instagram:
        return 'assets/images/instagram.svg';
      case SocialPlatform.facebook:
        return 'assets/images/facebook.svg';
      case SocialPlatform.youtube:
        return 'assets/images/youtube.svg';
      case SocialPlatform.rednote:
        return 'assets/images/rednote.svg';
      case SocialPlatform.snapchat:
        return 'assets/images/snapchat.svg';
      case SocialPlatform.unknown:
        return 'assets/images/default_video.svg';
    }
  }

  String _getPlatformName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.rednote:
        return 'RedNote';
      case SocialPlatform.snapchat:
        return 'Snapchat';
      case SocialPlatform.unknown:
        return 'Unknown';
    }
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final SortOption selectedSort;
  final SocialPlatform? selectedPlatform;
  final Function(SortOption) onSortChanged;
  final Function(SocialPlatform?) onPlatformChanged;

  const _FilterBottomSheet({
    required this.selectedSort,
    required this.selectedPlatform,
    required this.onSortChanged,
    required this.onPlatformChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Filter & Sort Downloads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Sort Options
          const Text(
            'Sort by:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          ...SortOption.values.map((sort) => _buildSortOption(context, sort)),

          const SizedBox(height: 20),

          // Platform Filter
          const Text(
            'Filter by Platform:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          _buildPlatformOption(context, null, 'All Platforms'),
          ...SocialPlatform.values.map((platform) => _buildPlatformOption(
              context, platform, _getPlatformName(platform))),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, SortOption sort) {
    final isSelected = selectedSort == sort;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primaryColor : Colors.grey,
      ),
      title: Text(_getSortLabel(sort)),
      onTap: () {
        onSortChanged(sort);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildPlatformOption(
      BuildContext context, SocialPlatform? platform, String label) {
    final isSelected = selectedPlatform == platform;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primaryColor : Colors.grey,
      ),
      title: Text(label),
      onTap: () {
        onPlatformChanged(platform);
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.platform:
        return 'By Platform';
    }
  }

  String _getPlatformName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.rednote:
        return 'RedNote';
      case SocialPlatform.snapchat:
        return 'Snapchat';
      case SocialPlatform.unknown:
        return 'Unknown';
    }
  }
}
