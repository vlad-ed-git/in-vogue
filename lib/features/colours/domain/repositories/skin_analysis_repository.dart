import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';

/// A skin-tone analysis as the service reports it.
sealed class AnalysisTask extends Equatable {
  const AnalysisTask();

  @override
  List<Object?> get props => [];
}

final class AnalysisRunning extends AnalysisTask {
  const AnalysisRunning();
}

/// Finished with the face's [colours].
final class AnalysisDone extends AnalysisTask {
  const AnalysisDone(this.colours);
  final FaceColours colours;

  @override
  List<Object?> get props => [colours];
}

/// Failed; the service charges nothing for it.
final class AnalysisFailed extends AnalysisTask {
  const AnalysisFailed(this.problem, {this.advice});
  final AnalysisProblem problem;

  /// What to change about the photo, when it is the problem.
  final PhotoAdvice? advice;

  @override
  List<Object?> get props => [problem, advice];
}

/// The skin-tone analysis service.
///
/// An [AnalysisFailure] from a start means the service refused and nothing
/// started; any other failure leaves unknown whether it started.
abstract interface class SkinAnalysisRepository {
  /// Whether this build can reach the service at all.
  bool get available;

  /// Puts the face photo at [path] on the service, upright and small
  /// enough; its file id.
  Future<Either<Failure, String>> uploadFace(String path);

  /// Starts analysing the face in [fileId]; the task's id.
  Future<Either<Failure, String>> start(String fileId);

  Future<Either<Failure, AnalysisTask>> check(String taskId);

  /// Deletes the task [taskId] and its files; failures are ignored.
  Future<void> discard(String taskId);
}
