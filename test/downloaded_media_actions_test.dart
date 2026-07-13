import 'package:el_saver/src/features/social_videos_downloader/presentation/widgets/downloads_screen/media_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects open target from the actual file extension', () {
    expect(
        mediaOpenTargetOf('/downloads/clip.mp4'), MediaOpenTarget.videoPlayer);
    expect(
        mediaOpenTargetOf('/downloads/photo.GIF'), MediaOpenTarget.imageViewer);
    expect(
        mediaOpenTargetOf('/downloads/song.mp3'), MediaOpenTarget.systemViewer);
    expect(
        mediaOpenTargetOf('/downloads/data.bin'), MediaOpenTarget.systemViewer);
  });

  testWidgets('image viewer keeps accessible controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DownloadedImageViewer(imagePath: '/missing/image.gif'),
    ));

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('Close image viewer'), findsOneWidget);
    expect(find.text('Image preview'), findsOneWidget);
  });
}
