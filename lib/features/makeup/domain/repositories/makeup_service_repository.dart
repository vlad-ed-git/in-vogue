import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';

/// A makeup service task as the service reports it.
sealed class MakeupTask<T> extends Equatable {
  const MakeupTask();

  @override
  List<Object?> get props => [];
}

final class MakeupTaskRunning<T> extends MakeupTask<T> {
  const MakeupTaskRunning();
}

/// Finished with its [result].
final class MakeupTaskDone<T> extends MakeupTask<T> {
  const MakeupTaskDone(this.result);
  final T result;

  @override
  List<Object?> get props => [result];
}

/// Failed; the service charges nothing for it.
final class MakeupTaskFailed<T> extends MakeupTask<T> {
  const MakeupTaskFailed(this.problem, {this.advice});
  final MakeupProblem problem;

  /// What to change about the photo, when it is the problem.
  final PhotoAdvice? advice;

  @override
  List<Object?> get props => [problem, advice];
}

/// The makeup service: analyses a face's colours and puts makeup on it.
///
/// A [MakeupFailure] from a start means the service refused and nothing
/// started; any other failure leaves unknown whether it started.
abstract interface class MakeupServiceRepository {
  /// Whether this build can reach the service at all.
  bool get available;

  /// The face photo at [path] as the service takes it: upright and small
  /// enough, as a PNG.
  Future<Either<Failure, List<int>>> prepareFace(String path);

  /// Puts the picture at [path] on the service; its file id.
  Future<Either<Failure, String>> upload(String path);

  /// Starts analysing the colours of the face in [fileId]; the task's id.
  Future<Either<Failure, String>> startAnalysis(String fileId);

  Future<Either<Failure, MakeupTask<FaceColours>>> checkAnalysis(String taskId);

  /// Starts putting [effects] on the face in [fileId]; the task's id.
  Future<Either<Failure, String>> startStep(
    String fileId,
    List<Map<String, Object?>> effects,
  );

  /// The task's result is the URL of the face after the step.
  Future<Either<Failure, MakeupTask<String>>> checkStep(String taskId);

  /// The picture at [url].
  Future<Either<Failure, List<int>>> download(String url);

  /// Deletes the task [taskId] and its files; failures are ignored.
  Future<void> discard(String taskId);
}
