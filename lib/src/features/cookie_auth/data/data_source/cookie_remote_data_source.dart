import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../../../../core/utils/api_config.dart';

class CookieRemoteDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  String get _baseUrl => ApiConfig.cookieSyncUrl;
  String get _apiKey => ApiConfig.cookieSyncApiKey;

  bool get isConfigured =>
      _baseUrl.isNotEmpty && _apiKey.isNotEmpty && _apiKey != "change-me";

  Future<bool> syncCookies(String platform, String cookieString) async {
    if (!isConfigured) return false;
    try {
      await _dio.post(
        "$_baseUrl/cookies",
        data: {"platform": platform, "cookies": cookieString},
        options: Options(headers: {"X-Api-Key": _apiKey}),
      );
      developer.log("Cookies synced for $platform", name: "CookieSync");
      return true;
    } catch (e) {
      developer.log("Cookie sync failed: $e", name: "CookieSync");
      return false;
    }
  }

  Future<bool> deleteCookies(String platform) async {
    if (!isConfigured) return false;
    try {
      await _dio.delete(
        "$_baseUrl/cookies/$platform",
        options: Options(headers: {"X-Api-Key": _apiKey}),
      );
      return true;
    } catch (e) {
      developer.log("Cookie delete failed: $e", name: "CookieSync");
      return false;
    }
  }

  Future<Map<String, dynamic>> listCookies() async {
    if (!isConfigured) return {};
    try {
      final response = await _dio.get(
        "$_baseUrl/cookies",
        options: Options(headers: {"X-Api-Key": _apiKey}),
      );
      return response.data?["platforms"] ?? {};
    } catch (e) {
      developer.log("Cookie list failed: $e", name: "CookieSync");
      return {};
    }
  }
}
