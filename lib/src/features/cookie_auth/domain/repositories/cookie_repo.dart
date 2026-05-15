import '../../../../core/utils/app_constants.dart';
import '../entities/platform_cookie.dart';

abstract class CookieRepo {
  Future<PlatformCookie?> getCookies(SocialPlatform platform);
  Future<void> saveCookies(PlatformCookie cookie);
  Future<void> deleteCookies(SocialPlatform platform);
  Future<List<PlatformCookie>> getAllCookies();
  Future<bool> syncToServer(PlatformCookie cookie);
  Future<bool> deleteFromServer(SocialPlatform platform);
}
