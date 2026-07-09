import 'package:flutter_test/flutter_test.dart';
import 'package:anr_saver/src/core/services/update_service.dart';

void main() {
  test('semver: remote newer', () {
    expect(isNewerVersionName('1.6.0', '1.5.0'), isTrue);
    expect(isNewerVersionName('1.5.1', '1.5.0'), isTrue);
    expect(isNewerVersionName('2.0.0', '1.9.9'), isTrue);
    // numeric, not lexicographic
    expect(isNewerVersionName('1.10.0', '1.9.0'), isTrue);
  });

  test('semver: not newer / equal', () {
    expect(isNewerVersionName('1.5.0', '1.5.0'), isFalse);
    expect(isNewerVersionName('1.5.0', '1.6.0'), isFalse);
    expect(isNewerVersionName('1.5', '1.5.0'), isFalse); // 1.5 == 1.5.0
  });

  test('semver: tolerates build suffix / stray chars', () {
    expect(isNewerVersionName('1.6.0+8', '1.5.0+7'), isTrue);
    expect(isNewerVersionName('v1.6.0', '1.5.0'), isTrue);
  });

  test('abi apk filename selection by priority', () {
    expect(abiApkFileName(['arm64-v8a', 'armeabi-v7a']),
        'app-arm64-v8a-release.apk');
    expect(abiApkFileName(['armeabi-v7a']), 'app-armeabi-v7a-release.apk');
    expect(abiApkFileName(['x86_64']), 'app-x86_64-release.apk');
    expect(abiApkFileName([]), 'app-arm64-v8a-release.apk'); // fallback
  });
}
