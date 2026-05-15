import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/platform_cookie.dart';
import '../../domain/repositories/cookie_repo.dart';
import '../data_source/cookie_local_data_source.dart';
import '../data_source/cookie_remote_data_source.dart';
import '../models/platform_login_config.dart';

class CookieRepoImpl implements CookieRepo {
  final CookieLocalDataSource localDataSource;
  final CookieRemoteDataSource remoteDataSource;

  CookieRepoImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<PlatformCookie?> getCookies(SocialPlatform platform) {
    return localDataSource.get(platform);
  }

  @override
  Future<void> saveCookies(PlatformCookie cookie) {
    return localDataSource.save(cookie);
  }

  @override
  Future<void> deleteCookies(SocialPlatform platform) {
    return localDataSource.delete(platform);
  }

  @override
  Future<List<PlatformCookie>> getAllCookies() {
    return localDataSource.getAll();
  }

  @override
  Future<bool> syncToServer(PlatformCookie cookie) async {
    final config = PlatformLoginConfig.getConfig(cookie.platform);
    if (config == null) return false;
    return remoteDataSource.syncCookies(
      config.cobaltPlatformName,
      cookie.cookieString,
    );
  }

  @override
  Future<bool> deleteFromServer(SocialPlatform platform) async {
    final config = PlatformLoginConfig.getConfig(platform);
    if (config == null) return false;
    return remoteDataSource.deleteCookies(config.cobaltPlatformName);
  }
}
