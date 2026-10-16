import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The domain describes the failure; presentation supplies localized wording.
extension FailureMessage on Failure {
  String uiFriendlyMessage(BuildContext context) => switch (this) {
    CacheFailure() => context.translated.cacheFailure,
    NetworkFailure() => context.translated.networkFailure,
    ServerFailure() => context.translated.serverFailure,
    PhotoFailure() => context.translated.photoUnreadable,
    SignInFailure() => context.translated.signInFailed,
    TryOnFailure(:final problem) => switch (problem) {
      TryOnProblem.failed => context.translated.tryOnFailed,
      TryOnProblem.photo => context.translated.tryOnPhotoProblem,
      TryOnProblem.budgetSpent => context.translated.tryOnBudgetSpent,
      TryOnProblem.unavailable => context.translated.tryOnUnavailable,
      TryOnProblem.everySeen => context.translated.everyLookSeen(
        ForecastDay.tomorrow.name,
      ),
    },
    MakeupFailure(:final problem) => switch (problem) {
      MakeupProblem.failed => context.translated.makeupFailed,
      MakeupProblem.photo => context.translated.makeupPhotoProblem,
      MakeupProblem.budgetSpent => context.translated.makeupBudgetSpent,
      MakeupProblem.unavailable => context.translated.makeupUnavailable,
    },
    LocationFailure(:final needsSettings) =>
      needsSettings
          ? context.translated.locationOff
          : context.translated.locationUnavailable,
  };
}
