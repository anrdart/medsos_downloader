import '../../../../core/utils/app_constants.dart';

class PlatformCookie {
  final SocialPlatform platform;
  final Map<String, String> cookies;
  final String? username;
  final DateTime loginTime;

  PlatformCookie({
    required this.platform,
    required this.cookies,
    this.username,
    DateTime? loginTime,
  }) : loginTime = loginTime ?? DateTime.now();

  String get cookieString =>
      cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");

  bool get hasCookies => cookies.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'cookies': cookies,
        'username': username,
        'loginTime': loginTime.toIso8601String(),
      };

  factory PlatformCookie.fromJson(Map<String, dynamic> json) {
    return PlatformCookie(
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.unknown,
      ),
      cookies: Map<String, String>.from(json['cookies'] ?? {}),
      username: json['username'],
      loginTime: DateTime.parse(json['loginTime']),
    );
  }
}
