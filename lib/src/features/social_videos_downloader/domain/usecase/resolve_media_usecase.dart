import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/resolved_media.dart';
import '../entities/video_link.dart';
import '../repositories/video_base_repo.dart';

class ResolveMediaParams {
  final String sourceUrl;
  final VideoLink option;

  const ResolveMediaParams({required this.sourceUrl, required this.option});
}

class ResolveMediaUseCase {
  final VideoBaseRepo videoRepo;
  const ResolveMediaUseCase({required this.videoRepo});

  Future<Either<Failure, ResolvedMedia>> call(ResolveMediaParams params) =>
      videoRepo.resolveMedia(params.sourceUrl, params.option);
}
