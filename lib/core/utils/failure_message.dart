import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The domain describes the failure; presentation supplies localized wording.
extension FailureMessage on Failure {
  String uiFriendlyMessage(BuildContext context) => switch (this) {
    CacheFailure() => context.translated.cacheFailure,
    NetworkFailure() => context.translated.networkFailure,
    ServerFailure() => context.translated.serverFailure,
    PhotoFailure() => context.translated.photoUnreadable,
    SignInFailure(problem: SignInProblem.unavailable) =>
      context.translated.signInUnavailable,
    SignInFailure() => context.translated.signInFailed,
    LocationFailure(:final needsSettings) =>
      needsSettings
          ? context.translated.locationOff
          : context.translated.locationUnavailable,
  };
}
