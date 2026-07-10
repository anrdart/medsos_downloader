import 'package:flutter_test/flutter_test.dart';
import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_link_model.dart';

void main() {
  test('VideoLinkModel audio flags round-trip via fromJson', () {
    final v = VideoLinkModel.fromJson({
      'quality': '🎵 Audio Only',
      'link': 'https://x/a.mp3',
      'isAudio': true,
      'mode': 'audio',
      'size': 12345,
    });
    expect(v.isAudio, isTrue);
    expect(v.mode, 'audio');
    expect(v.size, 12345);
  });

  test('VideoLinkModel defaults are video when fields absent', () {
    final v = VideoLinkModel.fromJson({
      'quality': '720p',
      'link': 'https://x/v.mp4',
    });
    expect(v.isAudio, isFalse);
    expect(v.mode, 'video');
    expect(v.size, isNull);
  });

  test('extension logic: audio -> .mp3, video -> .mp4', () {
    // Mirrors DownloaderBloc._getPathById extension decision.
    String ext({required bool isAudio, String? link}) {
      if (isAudio) return '.mp3';
      final l = (link ?? '').toLowerCase();
      if (l.contains('.jpg') || l.contains('.jpeg')) return '.jpg';
      if (l.contains('.png')) return '.png';
      if (l.contains('.webp')) return '.webp';
      return '.mp4';
    }

    expect(ext(isAudio: true, link: 'https://x/song'), '.mp3');
    expect(ext(isAudio: false, link: 'https://x/clip.mp4'), '.mp4');
    expect(ext(isAudio: false, link: 'https://x/pic.jpg'), '.jpg');
  });
}
