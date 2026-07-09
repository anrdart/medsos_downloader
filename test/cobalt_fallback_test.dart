import 'package:flutter_test/flutter_test.dart';
import 'package:anr_saver/src/core/utils/api_config.dart';

// Self-check: fallback chain must prefer live public instances over the
// (currently down) self-hosted VPS, and timeouts must stay short.
void main() {
  test('cobalt instances non-empty and public-first', () {
    final list = ApiConfig.cobaltInstances;
    expect(list, isNotEmpty);
    // First instance must not be the dead VPS IP.
    expect(list.first.contains('34.128.84.130'), isFalse,
        reason: 'Dead VPS must not be first in the fallback chain');
    // VPS may remain as a later fallback; just ensure a public one precedes it.
    final vpsIdx = list.indexWhere((u) => u.contains('34.128.84.130'));
    if (vpsIdx != -1) {
      expect(vpsIdx, greaterThan(0));
    }
  });

  test('connect timeout short, receive timeout sane', () {
    expect(ApiConfig.cobaltConnectTimeoutSeconds,
        lessThanOrEqualTo(ApiConfig.cobaltReceiveTimeoutSeconds));
    expect(ApiConfig.cobaltConnectTimeoutSeconds, inInclusiveRange(1, 10));
  });
}
