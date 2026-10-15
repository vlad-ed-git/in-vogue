import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/usecases/save_setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:mockito/mockito.dart';

import 'setup_repository_test.mocks.dart';

void main() {
  late MockSetupRepository repository;
  SetupBloc buildBloc({SetupStep initialStep = SetupStep.welcome}) => SetupBloc(
    saveSetupStep: SaveSetupStep(repository),
    initialStep: initialStep,
  );

  setUp(() {
    repository = MockSetupRepository();
  });

  blocTest<SetupBloc, SetupState>(
    'saves and announces each step the person reaches',
    build: () {
      when(
        repository.saveStep(SetupStep.photo),
      ).thenAnswer((_) async => const Right(SetupStep.photo));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SetupStepReached(SetupStep.photo)),
    expect: () => [const SetupState(step: SetupStep.photo)],
    verify: (_) => verify(repository.saveStep(SetupStep.photo)).called(1),
  );

  blocTest<SetupBloc, SetupState>(
    'keeps the step on screen when it cannot be saved',
    build: () {
      when(
        repository.saveStep(any),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      return buildBloc(initialStep: SetupStep.photo);
    },
    act: (bloc) => bloc.add(const SetupStepReached(SetupStep.picks)),
    expect: () => [const SetupState(step: SetupStep.picks)],
  );

  blocTest<SetupBloc, SetupState>(
    'does not save the step it is already on',
    build: () => buildBloc(initialStep: SetupStep.signIn),
    act: (bloc) => bloc.add(const SetupStepReached(SetupStep.signIn)),
    expect: () => <SetupState>[],
    verify: (_) => verifyNever(repository.saveStep(any)),
  );

  test('reports finished setup only for the done step', () {
    expect(const SetupState(step: SetupStep.widget).isFinished, isFalse);
    expect(const SetupState(step: SetupStep.done).isFinished, isTrue);
  });

  test('saves quick steps in order so the last one stays on disk', () async {
    final firstSave = Completer<Either<Failure, SetupStep>>();
    when(
      repository.saveStep(SetupStep.photo),
    ).thenAnswer((_) => firstSave.future);
    when(
      repository.saveStep(SetupStep.picks),
    ).thenAnswer((_) async => const Right(SetupStep.picks));
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc
      ..add(const SetupStepReached(SetupStep.photo))
      ..add(const SetupStepReached(SetupStep.picks));
    await Future<void>.delayed(Duration.zero);
    verifyNever(repository.saveStep(SetupStep.picks));
    final finished = bloc.stream.firstWhere(
      (state) => state.step == SetupStep.picks,
    );
    firstSave.complete(const Right(SetupStep.photo));
    await finished.timeout(const Duration(seconds: 2));
    verifyInOrder([
      repository.saveStep(SetupStep.photo),
      repository.saveStep(SetupStep.picks),
    ]);
  });
}
