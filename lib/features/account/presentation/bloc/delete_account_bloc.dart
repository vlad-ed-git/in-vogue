import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/usecases/delete_account.dart';

sealed class DeleteAccountEvent extends Equatable {
  const DeleteAccountEvent();

  @override
  List<Object?> get props => [];
}

/// The person confirmed deleting their account.
final class DeleteAccountConfirmed extends DeleteAccountEvent {
  const DeleteAccountConfirmed();
}

enum DeleteAccountStatus { idle, deleting, deleted }

class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.status = DeleteAccountStatus.idle,
    this.failure,
  });

  final DeleteAccountStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}

/// Deletes the account once at a time; cancelling the provider's sheet is
/// not a failure.
class DeleteAccountBloc extends Bloc<DeleteAccountEvent, DeleteAccountState> {
  DeleteAccountBloc({required this._deleteAccount})
    : super(const DeleteAccountState()) {
    on<DeleteAccountConfirmed>(_delete, transformer: droppable());
  }

  final DeleteAccount _deleteAccount;

  Future<void> _delete(
    DeleteAccountConfirmed event,
    Emitter<DeleteAccountState> emit,
  ) async {
    emit(const DeleteAccountState(status: DeleteAccountStatus.deleting));
    final deleted = await _deleteAccount(const NoParams());
    emit(
      deleted.fold(
        (failure) => failure == const SignInFailure(SignInProblem.cancelled)
            ? const DeleteAccountState()
            : DeleteAccountState(failure: failure),
        (_) => const DeleteAccountState(status: DeleteAccountStatus.deleted),
      ),
    );
  }
}
