import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/platform_cookie.dart';

class CookieLocalDataSource {
  final FlutterSecureStorage _storage;

  CookieLocalDataSource({required FlutterSecureStorage storage})
      : _storage = storage;

  String _key(SocialPlatform platform) => 'cookie_${platform.name}';

  Future<void> save(PlatformCookie cookie) async {
    await _storage.write(
      key: _key(cookie.platform),
      value: json.encode(cookie.toJson()),
    );
  }

  Future<PlatformCookie?> get(SocialPlatform platform) async {
    final data = await _storage.read(key: _key(platform));
    if (data == null) return null;
    return PlatformCookie.fromJson(json.decode(data));
  }

  Future<void> delete(SocialPlatform platform) async {
    await _storage.delete(key: _key(platform));
  }

  Future<List<PlatformCookie>> getAll() async {
    final results = <PlatformCookie>[];
    for (final platform in SocialPlatform.values) {
      final cookie = await get(platform);
      if (cookie != null) results.add(cookie);
    }
    return results;
  }
}
