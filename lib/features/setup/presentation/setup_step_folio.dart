import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

/// The number a setup step shows in its "2 / 6" folio.
extension SetupStepFolio on SetupStep {
  static const total = 6;

  /// Null for Welcome, which has no folio, and once setup is done.
  int? get folio => switch (this) {
    SetupStep.welcome || SetupStep.done => null,
    SetupStep.photo => 2,
    SetupStep.picks => 3,
    SetupStep.signIn => 4,
    SetupStep.profile => 5,
    SetupStep.widget => 6,
  };
}
