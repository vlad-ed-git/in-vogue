import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/colours/domain/repositories/skin_analysis_repository.dart';

/// The skin-tone analysis in a build without access to it: nothing starts.
class UnavailableSkinAnalysisRepository implements SkinAnalysisRepository {
  const UnavailableSkinAnalysisRepository();

  static const _unavailable = Left<Failure, Never>(
    AnalysisFailure(AnalysisProblem.unavailable),
  );

  @override
  bool get available => false;

  @override
  Future<Either<Failure, String>> uploadFace(String path) async => _unavailable;

  @override
  Future<Either<Failure, String>> start(String fileId) async => _unavailable;

  @override
  Future<Either<Failure, AnalysisTask>> check(String taskId) async =>
      _unavailable;

  @override
  Future<void> discard(String taskId) async {}
}
