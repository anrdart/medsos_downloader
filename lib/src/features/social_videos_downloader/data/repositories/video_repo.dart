import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:anr_saver/src/features/social_videos_downloader/data/models/video_model.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/entities/video.dart';
import 'package:anr_saver/src/features/social_videos_downloader/domain/mappers.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/video_base_repo.dart';
import '../data_source/video_remote_data_source.dart';

class VideoRepo implements VideoBaseRepo {
  final VideoBaseRemoteDataSource remoteDataSource;
  //final NetworkInfo networkInfo;

  VideoRepo({required this.remoteDataSource /*, required this.networkInfo*/});

  @override
  Future<Either<Failure, Video>> getVideo(String videoLink) async {
    try {
      final VideoModel video = await remoteDataSource.getVideo(videoLink);
      return Right(video.toDomain());
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    } catch (error) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String>> getAudioUrl(String videoLink) async {
    try {
      final url = await remoteDataSource.getAudioUrl(videoLink);
      return Right(url);
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    } catch (error) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, String>> saveVideo({
    required String videoLink,
    required String savePath,
    CancelToken? cancelToken,
    Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      final String message = await remoteDataSource.saveVideo(
        savePath: savePath,
        videoLink: videoLink,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return Right(message);
    } on DioException catch (error) {
      return Left(ErrorHandler.handle(error).failure);
    } catch (error) {
      return Left(ServerFailure());
    }
  }
}
