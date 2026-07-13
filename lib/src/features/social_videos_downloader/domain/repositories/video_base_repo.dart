import 'package:el_saver/src/features/social_videos_downloader/domain/entities/video.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/video_link.dart';
import 'package:el_saver/src/features/social_videos_downloader/domain/entities/resolved_media.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import 'package:dartz/dartz.dart';

abstract class VideoBaseRepo {
  Future<Either<Failure, Video>> getVideo(String videoLink);

  Future<Either<Failure, String>> getAudioUrl(String videoLink);

  Future<Either<Failure, ResolvedMedia>> resolveMedia(
      String sourceUrl, VideoLink option);

  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    CancelToken? cancelToken,
    Function(int received, int total)? onReceiveProgress,
  });
}
