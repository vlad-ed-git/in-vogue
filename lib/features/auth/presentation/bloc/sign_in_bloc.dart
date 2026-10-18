import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/usecases/restore_from_account.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
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
    this.method,
    this.account,
    this.failure,
  });

  final SignInStatus status;

  /// The provider signing in.
  final SignInMethod? method;
  final Account? account;
  final Failure? failure;

  @override
  List<Object?> get props => [status, method, account, failure];
}

/// One sign-in at a time; cancelling is not a failure. Before it is signed
/// in, what the account keeps is brought back to the phone, then the
/// phone's setup is saved on the account; neither failing stops sign-in.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({
    required this._signIn,
    required this._restoreFromAccount,
    required this._saveSetupToAccount,
  }) : super(const SignInState()) {
    on<SignInRequested>(_request, transformer: droppable());
  }

  final SignIn _signIn;
  final RestoreFromAccount _restoreFromAccount;
  final SaveSetupToAccount _saveSetupToAccount;

  Future<void> _request(
    SignInRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(SignInState(status: SignInStatus.signingIn, method: event.method));
    final result = await _signIn(event.method);
    final account = result.fold<Account?>((_) => null, (account) => account);
    if (account == null) {
      final failure = result.fold((failure) => failure, (_) => null);
      return emit(
        failure == const SignInFailure(SignInProblem.cancelled)
            ? const SignInState()
            : SignInState(failure: failure),
      );
    }
    // The repositories log a failure; the try-on saves again first.
    await _restoreFromAccount(account.id);
    await _saveSetupToAccount(account.id);
    emit(SignInState(status: SignInStatus.signedIn, account: account));
  }
}
