import '../../../../core/utils/app_constants.dart';

class PlatformLoginConfig {
  final SocialPlatform platform;
  final String name;
  final String loginUrl;
  final List<String> successDomains;
  final List<String> requiredCookieKeys;
  final List<String> cookieDomains;

  const PlatformLoginConfig({
    required this.platform,
    required this.name,
    required this.loginUrl,
    required this.successDomains,
    required this.requiredCookieKeys,
    required this.cookieDomains,
  });

  static const List<PlatformLoginConfig> supported = [
    PlatformLoginConfig(
      platform: SocialPlatform.youtube,
      name: "YouTube",
      loginUrl: "https://accounts.google.com/ServiceLogin?hl=id&continue=https://m.youtube.com/",
      successDomains: ["m.youtube.com", "youtube.com", "www.youtube.com"],
      requiredCookieKeys: ["SID", "HSID", "SSID", "APISID", "SAPISID", "__Secure-1PSID"],
      cookieDomains: [".youtube.com", ".google.com"],
    ),
    PlatformLoginConfig(
      platform: SocialPlatform.twitter,
      name: "Twitter/X",
      loginUrl: "https://mobile.twitter.com/i/flow/login",
      successDomains: ["twitter.com", "x.com", "mobile.twitter.com"],
      requiredCookieKeys: ["auth_token", "ct0"],
      cookieDomains: [".twitter.com", ".x.com"],
    ),
    PlatformLoginConfig(
      platform: SocialPlatform.reddit,
      name: "Reddit",
      loginUrl: "https://www.reddit.com/login/",
      successDomains: ["www.reddit.com"],
      requiredCookieKeys: ["reddit_session"],
      cookieDomains: [".reddit.com"],
    ),
    PlatformLoginConfig(
      platform: SocialPlatform.bilibili,
      name: "Bilibili",
      loginUrl: "https://www.bilibili.com/",
      successDomains: ["www.bilibili.com", "bilibili.com"],
      requiredCookieKeys: ["SESSDATA", "bili_jct"],
      cookieDomains: [".bilibili.com"],
    ),
  ];

  static PlatformLoginConfig? getConfig(SocialPlatform platform) {
    try {
      return supported.firstWhere((c) => c.platform == platform);
    } catch (_) {
      return null;
    }
  }

  String get cobaltPlatformName {
    switch (platform) {
      case SocialPlatform.youtube:
        return "youtube";
      case SocialPlatform.twitter:
        return "twitter";
      case SocialPlatform.reddit:
        return "reddit";
      case SocialPlatform.bilibili:
        return "bilibili";
      default:
        return platform.name;
    }
  }
}
