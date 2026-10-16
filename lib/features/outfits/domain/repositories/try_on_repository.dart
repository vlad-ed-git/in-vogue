import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// A try-on task as the try-on service reports it.
sealed class TryOnTask extends Equatable {
  const TryOnTask();

  @override
  List<Object?> get props => [];
}

final class TryOnRunning extends TryOnTask {
  const TryOnRunning();
}

/// Finished; its picture can be downloaded from [pictureUrl] for a while.
final class TryOnSucceeded extends TryOnTask {
  const TryOnSucceeded(this.pictureUrl);
  final String pictureUrl;

  @override
  List<Object?> get props => [pictureUrl];
}

/// Failed; the service charges nothing for it.
final class TryOnErrored extends TryOnTask {
  const TryOnErrored(this.problem);
  final TryOnProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// The virtual try-on service.
abstract interface class TryOnRepository {
  /// Whether this build can reach the service at all.
  bool get available;

  /// Puts the photo at [path] on the service; its file id.
  Future<Either<Failure, String>> upload(String path);

  /// Starts [pass] on the uploaded [fileId] or on the previous pass's
  /// [pictureUrl]; the task's id.
  ///
  /// A [TryOnFailure] means the service refused it and nothing started.
  /// Any other failure leaves unknown whether it started.
  Future<Either<Failure, String>> start(
    TryOnPass pass, {
    String? fileId,
    String? pictureUrl,
  });

  /// How the task [taskId] stands.
  Future<Either<Failure, TryOnTask>> check(String taskId);

  /// The picture at [url].
  Future<Either<Failure, List<int>>> download(String url);

  /// Deletes the task [taskId] and its files; failures are ignored.
  Future<void> discard(String taskId);
}
