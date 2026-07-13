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
    final primary =
        isDark ? AppColors.primaryColorLight : AppColors.primaryColor;
    return ThemeData(
      fontFamily: 'Poppins',
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark
          ? AppColors.scaffoldBackgroundColorDark
          : AppColors.scaffoldBackgroundColorLight,
      primaryColor: primary,
      cardColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      colorScheme:
          (isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
        primary: primary,
        secondary:
            isDark ? AppColors.accentVioletLight : AppColors.accentViolet,
        surface: isDark ? AppColors.cardDark : AppColors.cardLight,
        error: isDark ? AppColors.destructiveDark : AppColors.destructive,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.primaryColor,
        foregroundColor: AppColors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
        elevation: 0.0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.white),
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
          backgroundColor: primary,
          foregroundColor: AppColors.white,
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
        fillColor: isDark ? AppColors.inputDark : AppColors.white,
        filled: true,
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: isDark ? AppColors.destructiveDark : AppColors.red,
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: isDark ? AppColors.destructiveDark : AppColors.red,
              width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.0),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
