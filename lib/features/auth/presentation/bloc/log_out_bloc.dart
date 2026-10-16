import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/usecases/log_out.dart';

sealed class LogOutEvent extends Equatable {
  const LogOutEvent();

  @override
  List<Object?> get props => [];
}

/// The person chose Log out.
final class LogOutRequested extends LogOutEvent {
  const LogOutRequested();
}

enum LogOutStatus { idle, loggingOut, loggedOut }

class LogOutState extends Equatable {
  const LogOutState({this.status = LogOutStatus.idle, this.failure});

  final LogOutStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}

/// Logs out once at a time.
class LogOutBloc extends Bloc<LogOutEvent, LogOutState> {
  LogOutBloc({required this._logOut}) : super(const LogOutState()) {
    on<LogOutRequested>(_request, transformer: droppable());
  }

  final LogOut _logOut;

  Future<void> _request(
    LogOutRequested event,
    Emitter<LogOutState> emit,
  ) async {
    emit(const LogOutState(status: LogOutStatus.loggingOut));
    final result = await _logOut(const NoParams());
    emit(
      result.fold(
        (failure) => LogOutState(failure: failure),
        (_) => const LogOutState(status: LogOutStatus.loggedOut),
      ),
    );
  }
}
