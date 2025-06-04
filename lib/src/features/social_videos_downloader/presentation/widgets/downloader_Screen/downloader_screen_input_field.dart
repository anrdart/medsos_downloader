import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anr_saver/src/core/media_query.dart';
import 'package:anr_saver/src/core/utils/app_colors.dart';

import '../../../../../core/common_widgets/container_with_shadows.dart';
import '../../../../../core/common_widgets/custom_elevated_button.dart';
import '../../../../../core/utils/app_strings.dart';
import '../../bloc/downloader_bloc/downloader_bloc.dart';

class DownloaderScreenInputField extends StatelessWidget {
  final TextEditingController videoLinkController;
  final GlobalKey<FormState> formKey;
  const DownloaderScreenInputField({
    super.key,
    required this.videoLinkController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return ContainerWithShadows(
      widthMultiplier: 0.9,
      heightMultiplier: 0.22,
      applyGradient: false,
      child: Padding(
        padding: EdgeInsets.all(context.height * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildInputField(context),
            SizedBox(height: context.height * 0.02),
            Row(
              children: [
                Expanded(
                  flex: 9,
                  child: CustomElevatedBtn(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        context.read<DownloaderBloc>().add(
                              DownloaderGetVideo(videoLinkController.text),
                            );
                      }
                    },
                    label: AppStrings.download,
                  ),
                ),
                Expanded(child: Container()),
                Expanded(
                  flex: 9,
                  child: CustomElevatedBtn(
                    onPressed: () {
                      Clipboard.getData(Clipboard.kTextPlain).then((value) =>
                          videoLinkController.text = value?.text! ?? "");
                    },
                    label: AppStrings.paste,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildInputField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: TextFormField(
        controller: videoLinkController,
        keyboardType: TextInputType.url,
        style: TextStyle(
          color: isDark ? AppColors.textLight : AppColors.textDark,
          fontSize: 16,
        ),
        validator: (String? value) {
          if (value!.isEmpty) return AppStrings.videoLinkRequired;
          return null;
        },
        decoration: InputDecoration(
          hintText: AppStrings.inputLinkFieldText,
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.whiteWithOpacity
                : AppColors.blackWithOpacity,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              width: 2.0,
              color: AppColors.primaryColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: AppColors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(
              color: AppColors.red,
              width: 2.0,
            ),
          ),
          fillColor: isDark ? Colors.grey[800] : Colors.white,
          filled: true,
        ),
      ),
    );
  }
}
