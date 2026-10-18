import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The domain describes the failure; presentation supplies localized wording.
extension FailureMessage on Failure {
  String uiFriendlyMessage(BuildContext context) => switch (this) {
    CacheFailure() => context.translated.cacheFailure,
    NetworkFailure() => context.translated.networkFailure,
    ServerFailure() => context.translated.serverFailure,
    PhotoFailure(:final problem) => switch (problem) {
      PhotoProblem.unreadable => context.translated.photoUnreadable,
      PhotoProblem.tooSmall => context.translated.photoTooSmall,
      PhotoProblem.unusable => context.translated.photoUnusable,
    },
    SignInFailure() => context.translated.signInFailed,
    TryOnFailure(:final problem, :final advice) => switch (problem) {
      TryOnProblem.failed ||
      TryOnProblem.reference => context.translated.tryOnFailed,
      TryOnProblem.photo =>
        _advice(context, advice) ?? context.translated.tryOnPhotoProblem,
      TryOnProblem.noCredit => context.translated.tryOnNoCredit,
      TryOnProblem.unavailable => context.translated.tryOnUnavailable,
    },
    AnalysisFailure(:final problem, :final advice) => switch (problem) {
      AnalysisProblem.failed => context.translated.colourFailed,
      AnalysisProblem.photo =>
        _advice(context, advice) ?? context.translated.colourPhotoProblem,
      AnalysisProblem.noCredit => context.translated.colourNoCredit,
      AnalysisProblem.unavailable => context.translated.colourUnavailable,
    },
    LocationFailure(:final needsSettings) =>
      needsSettings
          ? context.translated.locationOff
          : context.translated.locationUnavailable,
  };
}

/// What to change about a photo, said to the person; null without advice.
String? _advice(BuildContext context, PhotoAdvice? advice) => switch (advice) {
  PhotoAdvice.lookStraight => context.translated.photoLookStraight,
  PhotoAdvice.moveCloser => context.translated.photoMoveCloser,
  PhotoAdvice.showWholeFace => context.translated.photoShowWholeFace,
  PhotoAdvice.onlyYou => context.translated.photoOnlyYou,
  PhotoAdvice.standHeadToToe => context.translated.photoStandHeadToToe,
  null => null,
};
