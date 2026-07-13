import 'package:flutter_test/flutter_test.dart';
import 'package:el_saver/src/core/helpers/media_file_utils.dart';

void main() {
  test('detects real media extension from magic bytes', () {
    expect(MediaFileUtils.detectExtension([
      0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70,
    ]), '.mp4');
    expect(MediaFileUtils.detectExtension([
      0x49, 0x44, 0x33, 4, 0, 0, 0, 0,
    ]), '.mp3');
    expect(MediaFileUtils.detectExtension([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    ]), '.png');
  });

  test('rejects HTML or JSON download bodies', () {
    expect(
      () => MediaFileUtils.validate(
        bytes: '<html>error</html>'.codeUnits,
        contentType: 'text/html',
        received: 18,
        expected: 18,
      ),
      throwsFormatException,
    );
    expect(
      () => MediaFileUtils.validate(
        bytes: '{"error":true}'.codeUnits,
        contentType: 'application/json',
        received: 14,
        expected: 14,
      ),
      throwsFormatException,
    );
  });

  test('rejects incomplete body when content length is known', () {
    expect(
      () => MediaFileUtils.validate(
        bytes: [0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70],
        contentType: 'video/mp4',
        received: 8,
        expected: 20,
      ),
      throwsFormatException,
    );
  });

  test('builds unique safe media filenames', () {
    expect(
      MediaFileUtils.filename('same-id', 'quality-720', '.mp4'),
      'same-id_quality-720.mp4',
    );
    expect(
      MediaFileUtils.filename('same-id', 'quality-1080', '.mp4'),
      'same-id_quality-1080.mp4',
    );
  });
}
