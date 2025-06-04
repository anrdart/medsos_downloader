// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anr_saver/src/core/utils/app_colors.dart';
import 'package:anr_saver/src/features/social_videos_downloader/presentation/bloc/theme_bloc/theme_event.dart';

import '../../bloc/theme_bloc/theme_bloc.dart';

class AnimatedToggleButton extends StatefulWidget {
  const AnimatedToggleButton({super.key});

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => toggleState(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.primaryColor,
                size: 20,
                key: ValueKey(isDark),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isDark ? "Dark" : "Light",
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                key: ValueKey(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void toggleState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    BlocProvider.of<ThemeBloc>(context).add(ThemeEventChange(
        isDark ? ThemeEventType.toggleLight : ThemeEventType.toggleDark));
  }
}
