import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

/// The number a setup step shows in its "2 / 6" folio.
extension SetupStepFolio on SetupStep {
  static const total = 6;

  /// Null for Welcome, which has no folio, and once setup is done.
  int? get folio => switch (this) {
    SetupStep.welcome || SetupStep.done => null,
    SetupStep.photo => 2,
    SetupStep.firstOutfit => 3,
    SetupStep.picks => 4,
    SetupStep.signIn || SetupStep.name || SetupStep.facePhoto => 5,
    SetupStep.widget || SetupStep.widgetSteps => 6,
  };
}
