import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/services/account_sync.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/sign_in.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_in_bloc_test.mocks.dart';

const _maya = Account(id: 'uid-1', name: 'Maya');

@GenerateMocks([AuthRepository, AccountSync, SaveSetupToAccount])
void main() {
  late MockAuthRepository auth;
  late MockAccountSync sync;
  SignInBloc buildBloc() => SignInBloc(signIn: SignIn(auth), accountSync: sync);

  setUp(() {
    auth = MockAuthRepository();
    sync = MockAccountSync();
    when(auth.signIn(any)).thenAnswer((_) async => const Right(_maya));
    when(sync.signedIn(any)).thenAnswer((_) async {});
  });

  test('starts ready to sign in', () {
    expect(buildBloc().state, const SignInState());
  });

  blocTest<SignInBloc, SignInState>(
    'signs in with the chosen provider',
    build: buildBloc,
    act: (bloc) => bloc.add(const SignInRequested(SignInMethod.apple)),
    expect: () => [
      const SignInState(
        status: SignInStatus.signingIn,
        method: SignInMethod.apple,
      ),
      const SignInState(status: SignInStatus.signedIn, account: _maya),
    ],
    verify: (_) => verify(auth.signIn(SignInMethod.apple)).called(1),
  );

  blocTest<SignInBloc, SignInState>(
    'syncs the account in the background',
    build: buildBloc,
    act: (bloc) => bloc.add(const SignInRequested(SignInMethod.google)),
    skip: 1,
    expect: () => [
      const SignInState(status: SignInStatus.signedIn, account: _maya),
    ],
    verify: (_) => verify(sync.signedIn('uid-1')).called(1),
  );

  test('moves on at once, without waiting for the account', () async {
    when(sync.signedIn(any)).thenAnswer((_) => Completer<void>().future);
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc.add(const SignInRequested(SignInMethod.google));
    await bloc.stream.firstWhere((s) => s.status == SignInStatus.signedIn);
  });

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
      const SignInState(
        status: SignInStatus.signingIn,
        method: SignInMethod.google,
      ),
      const SignInState(failure: SignInFailure(SignInProblem.failed)),
    ],
    verify: (_) => verifyNever(sync.signedIn(any)),
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
      const SignInState(
        status: SignInStatus.signingIn,
        method: SignInMethod.google,
      ),
      const SignInState(),
    ],
    verify: (_) => verifyNever(sync.signedIn(any)),
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
