import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';

/// What making a makeup look reports.
sealed class MakeupUpdate extends Equatable {
  const MakeupUpdate();

  @override
  List<Object?> get props => [];
}

/// The look's [steps], those made so far with their pictures.
final class MakeupProgress extends MakeupUpdate {
  const MakeupProgress(this.steps);
  final List<LookStep> steps;

  @override
  List<Object?> get props => [steps];
}

/// The look is made.
final class MakeupDone extends MakeupUpdate {
  const MakeupDone(this.look);
  final MakeupLook look;

  @override
  List<Object?> get props => [look];
}

/// The look could not be made.
final class MakeupFailed extends MakeupUpdate {
  const MakeupFailed(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
