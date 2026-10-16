import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_service_repository.dart';

/// The makeup service in a build without access to it: nothing can start.
class UnavailableMakeupServiceRepository implements MakeupServiceRepository {
  const UnavailableMakeupServiceRepository();

  static const _unavailable = Left<Failure, Never>(
    MakeupFailure(MakeupProblem.unavailable),
  );

  @override
  bool get available => false;

  @override
  Future<Either<Failure, List<int>>> prepareFace(String path) async =>
      _unavailable;

  @override
  Future<Either<Failure, String>> upload(String path) async => _unavailable;

  @override
  Future<Either<Failure, String>> startAnalysis(String fileId) async =>
      _unavailable;

  @override
  Future<Either<Failure, MakeupTask<FaceColours>>> checkAnalysis(
    String taskId,
  ) async => _unavailable;

  @override
  Future<Either<Failure, String>> startStep(
    String fileId,
    List<Map<String, Object?>> effects,
  ) async => _unavailable;

  @override
  Future<Either<Failure, MakeupTask<String>>> checkStep(String taskId) async =>
      _unavailable;

  @override
  Future<Either<Failure, List<int>>> download(String url) async => _unavailable;

  @override
  Future<void> discard(String taskId) async {}
}
