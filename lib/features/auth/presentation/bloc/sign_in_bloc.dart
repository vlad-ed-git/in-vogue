import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/sign_in.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

/// The person chose a provider.
final class SignInRequested extends SignInEvent {
  const SignInRequested(this.method);
  final SignInMethod method;

  @override
  List<Object?> get props => [method];
}

enum SignInStatus { idle, signingIn, signedIn }

class SignInState extends Equatable {
  const SignInState({
    this.status = SignInStatus.idle,
    this.account,
    this.failure,
  });

  final SignInStatus status;
  final Account? account;
  final Failure? failure;

  @override
  List<Object?> get props => [status, account, failure];
}

/// One sign-in at a time; cancelling is not a failure.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({required this._signIn}) : super(const SignInState()) {
    on<SignInRequested>(_request, transformer: droppable());
  }

  final SignIn _signIn;

  Future<void> _request(
    SignInRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInState(status: SignInStatus.signingIn));
    final result = await _signIn(event.method);
    emit(
      result.fold(
        (failure) => failure == const SignInFailure(SignInProblem.cancelled)
            ? const SignInState()
            : SignInState(failure: failure),
        (account) =>
            SignInState(status: SignInStatus.signedIn, account: account),
      ),
    );
  }
}
