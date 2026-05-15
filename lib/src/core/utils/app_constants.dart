class AppConstants {
  // Cobalt API - primary downloader (self-hostable, open-source)
  static const String cobaltBaseUrl = "https://api.cobalt.tools";
  static const String cobaltEndpoint = "/";

  // TikWM API - reliable TikTok/Douyin fallback (no auth needed)
  static const String tikwmBaseUrl = "https://www.tikwm.com";
  static const String tikwmEndpoint = "/api/";

  static const int navigateTime = 3000;
  static const int animationTime = 2000;
  static final int socialPlatformsCount = SocialPlatform.values.length;
}

enum SocialPlatform {
  tiktok,
  instagram,
  facebook,
  youtube,
  twitter,
  reddit,
  pinterest,
  snapchat,
  bluesky,
  twitch,
  vimeo,
  soundcloud,
  tumblr,
  bilibili,
  dailymotion,
  vk,
  ok,
  rutube,
  loom,
  streamable,
  newgrounds,
  unknown,
}
