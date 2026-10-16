import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/sign_in.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_in_bloc_test.mocks.dart';

const _maya = Account(id: 'uid-1', name: 'Maya');

@GenerateMocks([AuthRepository, SaveSetupToAccount])
void main() {
  late MockAuthRepository auth;
  late MockSaveSetupToAccount saveSetup;
  SignInBloc buildBloc() =>
      SignInBloc(signIn: SignIn(auth), saveSetupToAccount: saveSetup);

  setUp(() {
    auth = MockAuthRepository();
    saveSetup = MockSaveSetupToAccount();
    when(auth.signIn(any)).thenAnswer((_) async => const Right(_maya));
    when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
  });

  test('starts ready to sign in', () {
    expect(buildBloc().state, const SignInState());
  });

  blocTest<SignInBloc, SignInState>(
    'signs in with the chosen provider',
    build: buildBloc,
    act: (bloc) => bloc.add(const SignInRequested(SignInMethod.apple)),
    expect: () => [
      const SignInState(status: SignInStatus.signingIn),
      const SignInState(status: SignInStatus.signedIn, account: _maya),
    ],
    verify: (_) => verify(auth.signIn(SignInMethod.apple)).called(1),
  );

  test('saves the setup on the account before it is signed in', () async {
    final saved = Completer<Either<Failure, Unit>>();
    when(saveSetup(any)).thenAnswer((_) => saved.future);
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc.add(const SignInRequested(SignInMethod.google));
    await untilCalled(saveSetup('uid-1'));
    expect(bloc.state.status, SignInStatus.signingIn);
    saved.complete(const Right(unit));
    await bloc.stream.firstWhere((s) => s.status == SignInStatus.signedIn);
  });

  blocTest<SignInBloc, SignInState>(
    'signs in even when the setup cannot be saved',
    build: () {
      when(
        saveSetup(any),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SignInRequested(SignInMethod.apple)),
    expect: () => [
      const SignInState(status: SignInStatus.signingIn),
      const SignInState(status: SignInStatus.signedIn, account: _maya),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'says why sign-in failed',
    build: () {
      when(auth.signIn(any)).thenAnswer(
        (_) async => const Left(SignInFailure(SignInProblem.failed)),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SignInRequested(SignInMethod.google)),
    expect: () => [
      const SignInState(status: SignInStatus.signingIn),
      const SignInState(failure: SignInFailure(SignInProblem.failed)),
    ],
  );

  blocTest<SignInBloc, SignInState>(
    'goes back quietly when the person cancels',
    build: () {
      when(auth.signIn(any)).thenAnswer(
        (_) async => const Left(SignInFailure(SignInProblem.cancelled)),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const SignInRequested(SignInMethod.google)),
    expect: () => [
      const SignInState(status: SignInStatus.signingIn),
      const SignInState(),
    ],
    verify: (_) => verifyNever(saveSetup(any)),
  );

  test('ignores more taps while it is signing in', () async {
    final answer = Completer<Either<Failure, Account>>();
    when(auth.signIn(any)).thenAnswer((_) => answer.future);
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc
      ..add(const SignInRequested(SignInMethod.apple))
      ..add(const SignInRequested(SignInMethod.google));
    await Future<void>.delayed(Duration.zero);
    answer.complete(const Right(_maya));
    await bloc.stream.firstWhere((s) => s.status == SignInStatus.signedIn);
    verify(auth.signIn(SignInMethod.apple)).called(1);
    verifyNever(auth.signIn(SignInMethod.google));
  });
}
