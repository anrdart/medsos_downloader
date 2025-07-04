import '../../../../core/base_usecase/base_usecase.dart';
import '../../../../core/error/failure.dart';
import 'package:dartz/dartz.dart';

import '../repositories/video_base_repo.dart';

class SaveVideoUseCase extends BaseUseCase<String, SaveVideoParams> {
  final VideoBaseRepo videoRepo;

  SaveVideoUseCase({required this.videoRepo});

  @override
  Future<Either<Failure, String>> call(SaveVideoParams params) async {
    return await videoRepo.saveVideo(
      videoLink: params.videoLink,
      savePath: params.savePath,
      onReceiveProgress: params.onReceiveProgress,
    );
  }
}

class SaveVideoParams {
  final String savePath;
  final String videoLink;
  final Function(int received, int total)? onReceiveProgress;

  SaveVideoParams({
    required this.savePath,
    required this.videoLink,
    this.onReceiveProgress,
  });
}
