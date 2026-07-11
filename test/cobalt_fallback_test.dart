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

  test('all service URLs point at the same active VPS', () {
    const vps = '157.20.159.50';
    expect(ApiConfig.cookieSyncUrl.contains(vps), isTrue);
    expect(ApiConfig.ytdlpApiUrl.contains(vps), isTrue);
    expect(ApiConfig.cobaltInstances.any((u) => u.contains(vps)), isTrue);
  });

  test('connect timeout short, receive timeout sane', () {
    expect(ApiConfig.cobaltConnectTimeoutSeconds,
        lessThanOrEqualTo(ApiConfig.cobaltReceiveTimeoutSeconds));
    expect(ApiConfig.cobaltConnectTimeoutSeconds, inInclusiveRange(1, 10));
  });
}
