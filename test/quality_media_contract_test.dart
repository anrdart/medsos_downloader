import 'package:flutter_test/flutter_test.dart';
import 'package:el_saver/src/core/utils/app_constants.dart';
import 'package:el_saver/src/features/social_videos_downloader/data/models/video_model.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/download_item.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/video_link.dart';

void main() {
  test('yt-dlp info preserves all quality options as deferred video links', () {
    final video = VideoModel.fromYtdlpInfo({
      'status': 'ok',
      'title': 'Example',
      'thumbnail': 'https://x/thumb.jpg',
      'formats': [
        {'quality': '1080p', 'height': 1080, 'ext': 'mp4', 'filesize': 300},
        {'quality': '720p', 'height': 720, 'ext': 'mp4', 'filesize': 200},
        {'quality': '480p', 'height': 480, 'ext': 'mp4', 'filesize': 100},
      ],
      'audio': {'quality': 'Audio (MP3)', 'ext': 'mp3', 'mode': 'audio'},
    }, 'https://youtube.com/watch?v=x');

    expect(video.videoLinks, hasLength(4));
    expect(video.videoLinks.take(3).map((e) => e.height), [1080, 720, 480]);
    expect(video.videoLinks.take(3).every((e) => e.isDeferred), isTrue);
    expect(video.videoLinks.last.mediaKind, MediaKind.audio);
    expect(video.videoLinks.last.extension, '.mp3');
  });

  test('Cobalt metadata keeps audio and picker media kinds', () {
    final audio = VideoModel.fromCobalt({
      'status': 'tunnel',
      'url': 'https://x/signed',
      'filename': 'song.mp3',
    }, 'https://music.youtube.com/watch?v=x');
    expect(audio.videoLinks.single.mediaKind, MediaKind.audio);
    expect(audio.videoLinks.single.extension, '.mp3');

    final picker = VideoModel.fromCobalt({
      'status': 'picker',
      'picker': [
        {'type': 'photo', 'url': 'https://x/no-extension'},
        {'type': 'gif', 'url': 'https://x/animated'},
        {'type': 'video', 'url': 'https://x/video'},
      ],
    }, 'https://instagram.com/p/x');
    expect(picker.videoLinks.map((e) => e.mediaKind), [
      MediaKind.image,
      MediaKind.gif,
      MediaKind.video,
    ]);
    expect(picker.videoLinks.map((e) => e.extension), ['.jpg', '.gif', '.mp4']);
  });

  test('VideoLink JSON remains backward compatible while preserving metadata', () {
    final link = VideoLink.fromJson({
      'quality': '720p',
      'link': '',
      'height': 720,
      'extension': '.webm',
      'mediaKind': 'video',
      'isDeferred': true,
      'id': '720-video',
    });
    expect(VideoLink.fromJson(link.toJson()), link);

    final old = VideoLink.fromJson({'quality': 'Best', 'link': 'https://x/v'});
    expect(old.mediaKind, MediaKind.video);
    expect(old.extension, '.mp4');
    expect(old.isDeferred, isFalse);
  });

  test('target platform detection includes Bilibili Global and aliases', () {
    expect(DownloadItem.detectPlatform('https://www.bilibili.tv/id/video/123'),
        SocialPlatform.bilibili);
    expect(DownloadItem.detectPlatform('https://biliintl.com/en/play/1/2'),
        SocialPlatform.bilibili);
    expect(DownloadItem.platformNameOf(SocialPlatform.bilibili),
        'Bilibili Global / Bstation');
  });
}
