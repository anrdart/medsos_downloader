part of 'theme_bloc.dart';

@immutable
class ThemeState {
  final ThemeData themeData;

  const ThemeState(this.themeData);

  static ThemeState get darkTheme => ThemeState(getAppTheme(true).copyWith(
        colorScheme: const ColorScheme.dark(),
      ));

  static ThemeState get lightTheme => ThemeState(getAppTheme(false).copyWith(
        colorScheme: const ColorScheme.light(),
      ));

  static ThemeData getAppTheme(bool isDark) {
    return ThemeData(
      fontFamily: 'Poppins',
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark
          ? AppColors.scaffoldBackgroundColorDark
          : AppColors.scaffoldBackgroundColorLight,
      primaryColor: AppColors.primaryColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0.0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
      ),
      textTheme: TextTheme(
        headlineLarge: getBlackTitleStyle(
            fontSize: FontSize.title, color: AppColors.white),
        headlineMedium:
            getBoldStyle(fontSize: FontSize.subTitle, color: AppColors.white),
        titleLarge: getBoldStyle(color: AppColors.white),
        // titleMedium Used in text form field
        titleMedium: getRegularStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark),
        bodyLarge: getMediumStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark),
        bodyMedium: getRegularStyle(
            color: isDark ? AppColors.textLight : AppColors.textDark),
        bodySmall: getLightStyle(
            color: isDark
                ? AppColors.whiteWithOpacity
                : AppColors.blackWithOpacity),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: getRegularStyle(color: AppColors.white),
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          elevation: 0.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: getRegularStyle(
            color: isDark ? AppColors.textLight : AppColors.blackWithOpacity),
        hintStyle: getRegularStyle(
            color: isDark
                ? AppColors.whiteWithOpacity
                : AppColors.blackWithOpacity),
        errorStyle: getLightStyle(color: AppColors.red),
        fillColor: isDark ? Colors.grey[800] : AppColors.white,
        filled: true,
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.red, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.red, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 1.0),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primaryColor),
    );
  }
}
