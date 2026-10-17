import 'package:in_vogue/core/domain/errors/failures.dart';

/// A photo could not be chosen, read or used, for [problem]. Translated to
/// a PhotoFailure at repository boundaries.
class PhotoException implements Exception {
  const PhotoException(
    this.cause,
    this.stackTrace, [
    this.problem = PhotoProblem.unreadable,
  ]);

  final Object cause;
  final StackTrace stackTrace;
  final PhotoProblem problem;
}
