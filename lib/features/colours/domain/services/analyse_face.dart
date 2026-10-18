import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/repositories/analysis_job_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/colour_profile_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/skin_analysis_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

/// The person's colours, read by the skin-tone analysis once per person
/// (owner, October 18): a new face photo keeps the colours already read,
/// since the person is the same, and is read only when they ask to redo
/// it. Readings are kept on the account under the photo's content, the one
/// saved last being the person's. A reading cut short is checked again
/// rather than paid for twice; a failed one costs nothing.
class AnalyseFace {
  AnalyseFace({
    required this._service,
    required this._profiles,
    required this._jobs,
    required this._photos,
    required this._saveSetupToAccount,
    this._checkEvery = const Duration(seconds: 3),
    this._taskTimeLimit = const Duration(minutes: 2),
  });

  final SkinAnalysisRepository _service;
  final ColourProfileRepository _profiles;
  final AnalysisJobRepository _jobs;
  final PhotoRepository _photos;
  final SaveSetupToAccount _saveSetupToAccount;
  final Duration _checkEvery;
  final Duration _taskTimeLimit;

  /// [accountId]'s colours: the reading kept on the account, or, when
  /// there is none or the person asks to [redo] it, the kept face photo's.
  Future<Either<Failure, FaceColours>> call(
    String accountId, {
    bool redo = false,
  }) async {
    if (!redo) {
      final latest = await _profiles.latest(accountId);
      if (latest case Left(value: final failure)) return Left(failure);
      if (latest.getOrElse(() => null) case final FaceColours colours) {
        return Right(colours);
      }
    }
    final face = (await _photos.kept(
      PhotoRole.face,
    )).fold<UserPhoto?>((_) => null, (photo) => photo);
    if (face == null) {
      return const Left(AnalysisFailure(AnalysisProblem.photo));
    }
    final known = await _profiles.colours(accountId, face.path);
    if (known case Left(value: final failure)) return Left(failure);
    if (known.getOrElse(() => null) case final FaceColours colours) {
      // Read before: saved again, it becomes the reading at no cost.
      final saved = await _profiles.save(accountId, face.path, colours);
      if (saved case Left(value: final failure)) return Left(failure);
      return Right(colours);
    }
    if (!_service.available) {
      return const Left(AnalysisFailure(AnalysisProblem.unavailable));
    }
    // So the face photo is on the account; a failed save never blocks.
    await _saveSetupToAccount(accountId);
    final key = '$accountId/${face.revision}';
    var task = await _jobs.task(key);
    if (task == null) {
      final uploaded = await _service.uploadFace(face.path);
      if (uploaded case Left(value: final failure)) return Left(failure);
      final started = await _service.start(
        uploaded.getOrElse(() => throw StateError('uploaded')),
      );
      if (started case Left(value: final failure)) return Left(failure);
      task = started.getOrElse(() => throw StateError('started'));
      await _jobs.save(key, task);
    }
    final deadline = clock.now().add(_taskTimeLimit);
    while (true) {
      final checked = await _service.check(task);
      if (checked case Left(value: final failure)) return Left(failure);
      switch (checked.getOrElse(() => const AnalysisRunning())) {
        case AnalysisDone(:final colours):
          final saved = await _profiles.save(accountId, face.path, colours);
          if (saved case Left(value: final failure)) return Left(failure);
          await _jobs.clear(key);
          unawaited(_service.discard(task));
          return Right(colours);
        case AnalysisFailed(:final problem, :final advice):
          await _jobs.clear(key);
          return Left(AnalysisFailure(problem, advice: advice));
        case AnalysisRunning():
          if (!clock.now().isBefore(deadline)) {
            return const Left(ServerFailure());
          }
          await Future<void>.delayed(_checkEvery);
      }
    }
  }
}
