import '../../../../core/utils/app_constants.dart';

class PlatformLoginConfig {
  final SocialPlatform platform;
  final String name;
  final String loginUrl;
  final List<String> successDomains;
  final List<String> requiredCookieKeys;
  final List<String> cookieDomains;
  final bool manualCompletion;

  const PlatformLoginConfig({
    required this.platform,
    required this.name,
    required this.loginUrl,
    required this.successDomains,
    required this.requiredCookieKeys,
    required this.cookieDomains,
    this.manualCompletion = false,
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
        "www.threads.net"
      ],
      requiredCookieKeys: ["sessionid", "ds_user_id"],
      cookieDomains: [".instagram.com", ".threads.net"],
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
    PlatformLoginConfig(
      platform: SocialPlatform.bilibili,
      name: "Bilibili Global / Bstation",
      loginUrl: "https://www.bilibili.tv/id",
      successDomains: [
        "www.bilibili.tv",
        "bilibili.tv",
        "passport.bilibili.tv",
      ],
      requiredCookieKeys: [],
      cookieDomains: [".bilibili.tv", "passport.bilibili.tv"],
      manualCompletion: true,
    ),
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
