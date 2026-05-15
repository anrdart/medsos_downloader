import '../../../../core/utils/app_constants.dart';

abstract class AccountEvent {}

class LoadAccounts extends AccountEvent {}

class LoginToPlatform extends AccountEvent {
  final SocialPlatform platform;
  LoginToPlatform(this.platform);
}

class CookiesExtracted extends AccountEvent {
  final SocialPlatform platform;
  final Map<String, String> cookies;
  CookiesExtracted({required this.platform, required this.cookies});
}

class LogoutFromPlatform extends AccountEvent {
  final SocialPlatform platform;
  LogoutFromPlatform(this.platform);
}
