const String _imageBasePath = 'assets/images';
const String _launcherBasePath = 'assets/launcher';
const String _splashBasePath = 'assets/splash';

class AppAssets {
  static const String logo = "$_launcherBasePath/el_logo.png";
  static const String splashLogo = "$_splashBasePath/el_logo.png";
  static const String noInternetImage = "$_launcherBasePath/el_logo.png";

  // Supported platform icons (8 target platforms)
  static const String facebook = "$_imageBasePath/facebook.svg";
  static const String instagram = "$_imageBasePath/instagram.svg";
  static const String threads = "$_imageBasePath/threads.svg";
  static const String twitter = "$_imageBasePath/twitter.svg";
  static const String youtube = "$_imageBasePath/youtube.svg";
  static const String youtubeMusic = "$_imageBasePath/youtube_music.svg";
  static const String tiktok = "$_imageBasePath/tiktok.svg";
  static const String bilibili = "$_imageBasePath/bilibili.svg";

  static const Map<String, String> _iconByName = {
    'facebook': facebook,
    'instagram': instagram,
    'threads': threads,
    'twitter': twitter,
    'youtube': youtube,
    'youtubeMusic': youtubeMusic,
    'tiktok': tiktok,
    'bilibili': bilibili,
  };

  static String getIconbyName(String iconName) => _iconByName[iconName] ?? '';
}
