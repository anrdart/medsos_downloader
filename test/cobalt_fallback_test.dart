import 'package:flutter_test/flutter_test.dart';
import 'package:el_saver/src/core/utils/api_config.dart';

// Self-check: fallback chain is well-formed and timeouts stay short.
void main() {
  test('cobalt instances non-empty and free of the retired VPS', () {
    final list = ApiConfig.cobaltInstances;
    expect(list, isNotEmpty);
    // Old dead VPS must be gone everywhere.
    expect(list.any((u) => u.contains('34.128.84.130')), isFalse);
  });

  test('all service URLs point at the same HTTPS origin', () {
    const origin = 'api.ekalliptus.com';
    expect(ApiConfig.cookieSyncUrl.contains(origin), isTrue);
    expect(ApiConfig.ytdlpApiUrl.contains(origin), isTrue);
    expect(ApiConfig.cobaltInstances.any((u) => u.contains(origin)), isTrue);
    // No plaintext HTTP for backend services.
    expect(ApiConfig.cookieSyncUrl.startsWith('https://'), isTrue);
    expect(ApiConfig.ytdlpApiUrl.startsWith('https://'), isTrue);
  });

  test('connect timeout short, receive timeout sane', () {
    expect(ApiConfig.cobaltConnectTimeoutSeconds,
        lessThanOrEqualTo(ApiConfig.cobaltReceiveTimeoutSeconds));
    expect(ApiConfig.cobaltConnectTimeoutSeconds, inInclusiveRange(1, 10));
  });
}
