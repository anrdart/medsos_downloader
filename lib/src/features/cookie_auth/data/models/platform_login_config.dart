import '../../../../core/utils/app_constants.dart';

class PlatformLoginConfig {
  final SocialPlatform platform;
  final String name;
  final String loginUrl;
  final List<String> successDomains;
  final List<String> requiredCookieKeys;
  final List<String> cookieDomains;
  final bool manualCompletion;

  /// Optional per-platform user-agent override. Some platforms (Bilibili.tv's
  /// Google OAuth) reject the default Android WebView UA with a whitescreen,
  /// so we present a full browser UA that Google accepts.
  final String? userAgent;

  const PlatformLoginConfig({
    required this.platform,
    required this.name,
    required this.loginUrl,
    required this.successDomains,
    required this.requiredCookieKeys,
    required this.cookieDomains,
    this.manualCompletion = false,
    this.userAgent,
  });

  static const List<PlatformLoginConfig> supported = [
    // YouTube + YouTube Music share the same Google login session.
    PlatformLoginConfig(
      platform: SocialPlatform.youtube,
      name: "YouTube & YouTube Music",
      loginUrl:
          "https://accounts.google.com/ServiceLogin?hl=id&continue=https://m.youtube.com/",
      successDomains: [
        "m.youtube.com",
        "youtube.com",
        "www.youtube.com",
        "music.youtube.com"
      ],
      requiredCookieKeys: [
        "SID",
        "HSID",
        "SSID",
        "APISID",
        "SAPISID",
        "__Secure-1PSID"
      ],
      cookieDomains: [".youtube.com", ".google.com"],
    ),
    // Instagram + Threads share the same Meta login session.
    PlatformLoginConfig(
      platform: SocialPlatform.instagram,
      name: "Instagram & Threads",
      loginUrl: "https://www.instagram.com/accounts/login/",
      successDomains: [
        "www.instagram.com",
        "instagram.com",
        "threads.net",
        "www.threads.net",
        "threads.com",
        "www.threads.com",
      ],
      requiredCookieKeys: ["sessionid", "ds_user_id"],
      cookieDomains: [".instagram.com", ".threads.net", ".threads.com"],
    ),
    PlatformLoginConfig(
      platform: SocialPlatform.facebook,
      name: "Facebook",
      loginUrl: "https://m.facebook.com/login/",
      successDomains: ["www.facebook.com", "facebook.com", "m.facebook.com"],
      requiredCookieKeys: ["c_user", "xs"],
      cookieDomains: [".facebook.com"],
    ),
    PlatformLoginConfig(
      platform: SocialPlatform.twitter,
      name: "Twitter/X",
      loginUrl: "https://x.com/i/flow/login",
      successDomains: ["twitter.com", "x.com", "mobile.twitter.com"],
      requiredCookieKeys: ["auth_token", "ct0"],
      cookieDomains: [".twitter.com", ".x.com"],
    ),
    PlatformLoginConfig(
      platform: SocialPlatform.tiktok,
      name: "TikTok",
      loginUrl: "https://www.tiktok.com/login",
      successDomains: ["www.tiktok.com", "tiktok.com"],
      requiredCookieKeys: ["sessionid"],
      cookieDomains: [".tiktok.com"],
    ),
    // Bilibili/Bstation login is hidden until the Google OAuth whitescreen is
    // solved. Keep the config here (commented) so it's easy to re-enable.
    // PlatformLoginConfig(
    //   platform: SocialPlatform.bilibili,
    //   name: "Bilibili Global / Bstation",
    //   loginUrl: "https://www.bilibili.tv/id",
    //   successDomains: [
    //     "www.bilibili.tv",
    //     "bilibili.tv",
    //     "passport.bilibili.tv",
    //   ],
    //   requiredCookieKeys: ["SESSDATA", "DedeUserID"],
    //   cookieDomains: [".bilibili.tv", "passport.bilibili.tv"],
    //   manualCompletion: true,
    //   userAgent:
    //       "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
    // ),
  ];

  static PlatformLoginConfig? getConfig(SocialPlatform platform) {
    try {
      return supported.firstWhere((c) => c.platform == platform);
    } catch (_) {
      return null;
    }
  }

  /// Platform key sent to the Cobalt cookie-sync backend.
  String get cobaltPlatformName {
    switch (platform) {
      case SocialPlatform.youtube:
        return "youtube";
      case SocialPlatform.instagram:
        return "instagram";
      case SocialPlatform.facebook:
        return "facebook";
      case SocialPlatform.twitter:
        return "twitter";
      case SocialPlatform.tiktok:
        return "tiktok";
      case SocialPlatform.bilibili:
        return "bilibili";
      default:
        return platform.name;
    }
  }
}
