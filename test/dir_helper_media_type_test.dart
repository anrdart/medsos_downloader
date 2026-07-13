import 'package:el_saver/src/core/helpers/dir_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirHelper.mediaTypeOf', () {
    test('classifies video extensions case-insensitively', () {
      expect(DirHelper.mediaTypeOf('/downloads/clip.MP4'), MediaFileType.video);
      expect(
          DirHelper.mediaTypeOf('/downloads/clip.webm'), MediaFileType.video);
    });

    test('classifies images including GIF', () {
      expect(
          DirHelper.mediaTypeOf('/downloads/photo.jpeg'), MediaFileType.image);
      expect(DirHelper.mediaTypeOf('/downloads/animation.GIF'),
          MediaFileType.image);
    });

    test('classifies common audio extensions', () {
      expect(DirHelper.mediaTypeOf('/downloads/song.mp3'), MediaFileType.audio);
      expect(DirHelper.mediaTypeOf('/downloads/song.m4a'), MediaFileType.audio);
      expect(
          DirHelper.mediaTypeOf('/downloads/song.opus'), MediaFileType.audio);
    });

    test('does not infer media from partial or unknown extensions', () {
      expect(DirHelper.mediaTypeOf('/downloads/clip.mp4.part'),
          MediaFileType.unsupported);
      expect(DirHelper.mediaTypeOf('/downloads/archive.bin'),
          MediaFileType.unsupported);
    });
  });
}
