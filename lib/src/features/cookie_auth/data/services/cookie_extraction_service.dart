import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/utils/app_constants.dart';
import '../models/platform_login_config.dart';

class CookieExtractionService {
  /// Extract cookies using Android native CookieManager (gets httpOnly cookies)
  Future<Map<String, String>> extractCookies(
    WebViewController controller,
    SocialPlatform platform,
  ) async {
    final config = PlatformLoginConfig.getConfig(platform);
    if (config == null) return {};

    final allCookies = <String, String>{};
    final androidCookieManager = AndroidWebViewCookieManager(
      const PlatformWebViewCookieManagerCreationParams(),
    );

    // Get cookies from all relevant domains
    for (final domain in config.cookieDomains) {
      final cleanDomain = domain.replaceAll(RegExp(r'^\.'), '');
      final urls = [
        Uri.parse("https://$cleanDomain/"),
        Uri.parse("https://www.$cleanDomain/"),
      ];

      for (final url in urls) {
        try {
          final cookies = await androidCookieManager.getCookies(url);
          for (final cookie in cookies) {
            allCookies[cookie.name] = cookie.value;
          }
        } catch (_) {}
      }
    }

    // Fallback: try JavaScript extraction for non-httpOnly cookies
    if (allCookies.isEmpty) {
      try {
        final result =
            await controller.runJavaScriptReturningResult('document.cookie');
        final cookieStr = result.toString().replaceAll('"', '');
        _parseCookieString(cookieStr, allCookies);
      } catch (_) {}
    }

    return allCookies;
  }

  void _parseCookieString(String cookieStr, Map<String, String> target) {
    if (cookieStr.isEmpty) return;
    for (final part in cookieStr.split(';')) {
      final trimmed = part.trim();
      final eq = trimmed.indexOf('=');
      if (eq > 0) {
        target[trimmed.substring(0, eq).trim()] =
            trimmed.substring(eq + 1).trim();
      }
    }
  }

  bool isLoginSuccessful(
    Map<String, String> cookies,
    SocialPlatform platform,
  ) {
    final config = PlatformLoginConfig.getConfig(platform);
    if (config == null) return false;

    // For manual-completion platforms that define required cookies (e.g.
    // Bilibili/Bstation), require those to be present — otherwise anonymous
    // cookies set on page load would look like a successful login. Fall back
    // to "any cookie" only when no keys are defined.
    if (config.requiredCookieKeys.isEmpty) {
      return config.manualCompletion ? cookies.isNotEmpty : false;
    }
    for (final key in config.requiredCookieKeys) {
      if (cookies.containsKey(key) && cookies[key]!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  String? extractUsername(
      Map<String, String> cookies, SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.instagram:
        return cookies['ds_user_id'];
      case SocialPlatform.facebook:
        return cookies['c_user'];
      case SocialPlatform.twitter:
        return cookies['twid']?.replaceAll('u%3D', '');
      case SocialPlatform.bilibili:
        return cookies['DedeUserID'];
      default:
        return null;
    }
  }
}
