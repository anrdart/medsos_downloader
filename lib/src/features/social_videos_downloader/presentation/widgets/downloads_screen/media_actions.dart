import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../../../../core/helpers/dir_helper.dart';
import '../../../../../core/utils/app_colors.dart';
import 'view_video_screen.dart';

enum MediaOpenTarget { videoPlayer, imageViewer, systemViewer }

MediaOpenTarget mediaOpenTargetOf(String filePath) {
  return switch (DirHelper.mediaTypeOf(filePath)) {
    MediaFileType.video => MediaOpenTarget.videoPlayer,
    MediaFileType.image => MediaOpenTarget.imageViewer,
    MediaFileType.audio ||
    MediaFileType.unsupported =>
      MediaOpenTarget.systemViewer,
  };
}

Future<void> openDownloadedMedia(BuildContext context, String filePath) async {
  if (!File(filePath).existsSync()) {
    _showError(context, 'File not found.');
    return;
  }

  switch (mediaOpenTargetOf(filePath)) {
    case MediaOpenTarget.videoPlayer:
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ViewVideoScreen(videoPath: filePath),
      ));
    case MediaOpenTarget.imageViewer:
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DownloadedImageViewer(imagePath: filePath),
      ));
    case MediaOpenTarget.systemViewer:
      final result = await OpenFile.open(filePath);
      if (context.mounted && result.type != ResultType.done) {
        _showError(
          context,
          result.message.isEmpty
              ? 'No app can open this file.'
              : result.message,
        );
      }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class DownloadedImageViewer extends StatelessWidget {
  final String imagePath;

  const DownloadedImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Close image viewer',
        ),
        title: const Text('Image preview'),
      ),
      body: SafeArea(
        child: Semantics(
          image: true,
          label: 'Downloaded image preview',
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to display this image.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
