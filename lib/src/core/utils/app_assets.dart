const String _imageBasePath = 'assets/images';
const String _launcherBasePath = 'assets/launcher';
const String _splashBasePath = 'assets/splash';

class AppAssets {
  static const String logo = "$_launcherBasePath/el_logo.png";
  static const String splashLogo = "$_splashBasePath/el_logo.png";
  static const String facebook = "$_imageBasePath/facebook.svg";
  static const String instagram = "$_imageBasePath/instagram.svg";
  static const String youtube = "$_imageBasePath/youtube.svg";
  static const String tiktok = "$_imageBasePath/tiktok.svg";
  static const String shorts = "$_imageBasePath/youtube_shorts.svg";
  static const String rednote = "$_imageBasePath/rednote.svg";
  static const String noInternetImage = "$_launcherBasePath/el_logo.png";
  static List<Map<String, String>> assetPath = const [
    {
      'facebook': facebook,
      'instagram': instagram,
      'youtube': youtube,
      'tiktok': tiktok,
      'shorts': shorts,
      'rednote': rednote,
    },
  ];

  static String getIconbyName(String iconName) {
    for (final iconMap in assetPath) {
      if (iconMap.containsKey(iconName)) {
        return iconMap[iconName]!;
      }
    }
    return '';
  }
}
