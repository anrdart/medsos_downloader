import 'package:flutter_test/flutter_test.dart';
import 'package:el_saver/src/core/error/failure.dart';
import 'package:el_saver/src/core/utils/app_constants.dart';
import 'package:el_saver/src/features/cookie_auth/data/models/platform_login_config.dart';
import 'package:el_saver/src/features/cookie_auth/data/services/cookie_extraction_service.dart';
import 'package:el_saver/src/features/social_videos_downloader/data/data_source/download_error_classifier.dart';

void main() {
  test('auth classifier routes genuine gated content to canonical login', () {
    final instagram = DownloadErrorClassifier.classify(
      'This content is only available for registered users who follow this account',
      'https://instagram.com/p/x',
    );
    expect(instagram, isA<AuthRequiredFailure>());
    expect(
        (instagram as AuthRequiredFailure).platform, SocialPlatform.instagram);

    final music = DownloadErrorClassifier.classify(
      'Sign in to confirm your age',
      'https://music.youtube.com/watch?v=x',
    );
    expect((music as AuthRequiredFailure).platform, SocialPlatform.youtube);
  });

  test(
      'bot challenge, geo restriction, and unsupported Threads do not open login',
      () {
    expect(
      DownloadErrorClassifier.classify(
        'youtube asked the processing instance to prove that it is not a bot',
        'https://youtube.com/watch?v=x',
      ),
      isNot(isA<AuthRequiredFailure>()),
    );
    expect(
      DownloadErrorClassifier.classify(
        'This content is not available in your country',
        'https://bilibili.tv/id/video/1',
      ),
      isNot(isA<AuthRequiredFailure>()),
    );
    expect(
      DownloadErrorClassifier.classify(
        'Unsupported URL',
        'https://threads.net/@x/post/y',
      ),
      isNot(isA<AuthRequiredFailure>()),
    );
  });

  test('Meta login covers threads.com and requires complete cookie sets', () {
    final config = PlatformLoginConfig.getConfig(SocialPlatform.instagram)!;
    expect(
        config.successDomains, containsAll(['threads.com', 'www.threads.com']));
    expect(config.cookieDomains, contains('.threads.com'));

    final extraction = CookieExtractionService();
    expect(
      extraction.isLoginSuccessful(
        {'sessionid': 's'},
        SocialPlatform.instagram,
      ),
      isFalse,
    );
    expect(
      extraction.isLoginSuccessful(
        {'sessionid': 's', 'ds_user_id': '1'},
        SocialPlatform.instagram,
      ),
      isTrue,
    );
    expect(
      extraction.isLoginSuccessful(
        {'c_user': '1'},
        SocialPlatform.facebook,
      ),
      isFalse,
    );
    expect(
      extraction.isLoginSuccessful(
        {'c_user': '1', 'xs': 'x'},
        SocialPlatform.facebook,
      ),
      isTrue,
    );
  });
}
