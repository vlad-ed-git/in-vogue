import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';

/// Try-ons in a build without access to the try-on service: none can start.
class UnavailableTryOnRepository implements TryOnRepository {
  const UnavailableTryOnRepository();

  static const _unavailable = Left<Failure, Never>(
    TryOnFailure(TryOnProblem.unavailable),
  );

  @override
  Future<Either<Failure, String>> upload(String path) async => _unavailable;

  @override
  Future<Either<Failure, String>> start(
    TryOnPass pass, {
    String? fileId,
    String? pictureUrl,
  }) async => _unavailable;

  @override
  Future<Either<Failure, TryOnTask>> check(String taskId) async => _unavailable;

  @override
  Future<Either<Failure, List<int>>> download(String url) async => _unavailable;

  @override
  Future<void> discard(String taskId) async {}
}
