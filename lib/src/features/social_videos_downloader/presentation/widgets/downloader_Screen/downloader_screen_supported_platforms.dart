// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anr_saver/src/core/media_query.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../core/common_widgets/container_with_shadows.dart';
import '../../../../../core/utils/app_assets.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/styles_manager.dart';
import '../../../../../core/providers/language_provider.dart';

class DownloaderScreenSupportedPlatforms extends StatefulWidget {
  const DownloaderScreenSupportedPlatforms({super.key});

  @override
  State<DownloaderScreenSupportedPlatforms> createState() =>
      _DownloaderScreenSupportedPlatformsState();
}

class _DownloaderScreenSupportedPlatformsState
    extends State<DownloaderScreenSupportedPlatforms> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return ContainerWithShadows(
          widthMultiplier: 0.9,
          heightMultiplier: 0.3,
          applyGradient: false,
          child: Padding(
            padding: EdgeInsets.all(context.height * 0.02),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    AppStrings.supportedPlatforms,
                    textAlign: TextAlign.center,
                    style: getTitleStyle(
                      fontSize: context.width * 0.05,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: SvgPicture.asset(
                                AppAssets.facebook,
                                fit: BoxFit.contain,
                                width: context.width * 0.2,
                              ),
                            ),
                            Flexible(
                              child: SvgPicture.asset(
                                AppAssets.instagram,
                                fit: BoxFit.contain,
                                width: context.width * 0.2,
                              ),
                            ),
                            Flexible(
                              child: SvgPicture.asset(
                                AppAssets.tiktok,
                                fit: BoxFit.contain,
                                width: context.width * 0.2,
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: SvgPicture.asset(
                                AppAssets.youtube,
                                fit: BoxFit.contain,
                                width: context.width * 0.2,
                              ),
                            ),
                            Flexible(
                              child: SvgPicture.asset(
                                AppAssets.shorts,
                                fit: BoxFit.contain,
                                width: context.width * 0.2,
                              ),
                            ),
                            Flexible(
                              child: Container(
                                width: context.width * 0.15,
                                height: context.width * 0.15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.shade600,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(context.width * 0.035),
                                  child: SvgPicture.asset(
                                    AppAssets.rednote,
                                    fit: BoxFit.contain,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
