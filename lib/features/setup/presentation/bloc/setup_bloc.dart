import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/usecases/save_setup_step.dart';

sealed class SetupEvent {
  const SetupEvent();
}

/// The person is on [step]'s screen.
final class SetupStepReached extends SetupEvent {
  const SetupStepReached(this.step);
  final SetupStep step;
}

class SetupState extends Equatable {
  const SetupState({required this.step});
  final SetupStep step;

  bool get isFinished => step == SetupStep.done;

  @override
  List<Object?> get props => [step];
}

/// The setup step on screen, saved so setup reopens there.
///
/// A failed save keeps the step: the person is already on that screen, and
/// the repository logs the failure.
class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc({
    required SaveSetupStep saveSetupStep,
    required SetupStep initialStep,
  }) : super(SetupState(step: initialStep)) {
    on<SetupStepReached>((event, emit) async {
      if (event.step == state.step) return;
      emit(SetupState(step: event.step));
      await saveSetupStep(event.step);
    }, transformer: sequential());
  }
}
