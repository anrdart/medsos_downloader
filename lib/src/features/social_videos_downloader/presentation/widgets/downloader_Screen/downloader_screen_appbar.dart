import 'package:flutter/material.dart';
import 'package:anr_saver/src/core/media_query.dart';
import 'package:anr_saver/src/core/common_widgets/container_with_shadows.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../../../../core/utils/styles_manager.dart';

class AppBarWithLogo extends StatelessWidget {
  const AppBarWithLogo({super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: ContainerWithShadows(
          widthMultiplier: 0.9,
          heightMultiplier: 0.15,
          applyGradient: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppStrings.appName.toUpperCase(),
                  style: getTitleStyle(
                      fontSize: context.width * 0.08,
                      color: AppColors.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(AppStrings.appSlogan,
                    style: getRegularStyle(
                        fontSize: context.width * 0.045,
                        // ignore: deprecated_member_use
                        color: AppColors.primaryColor.withOpacity(0.8)))
              ],
            ),
          )),
    );
  }
}
