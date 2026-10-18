import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/colours/domain/services/analyse_face.dart';

sealed class SkinAnalysisEvent extends Equatable {
  const SkinAnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// The person asked to read their colours again from their face photo.
final class SkinAnalysisRedone extends SkinAnalysisEvent {
  const SkinAnalysisRedone();
}

enum SkinAnalysisStatus { idle, redoing, done, failed }

class SkinAnalysisState extends Equatable {
  const SkinAnalysisState({
    this.status = SkinAnalysisStatus.idle,
    this.failure,
  });

  final SkinAnalysisStatus status;
  final Failure? failure;

  @override
  List<Object?> get props => [status, failure];
}

/// Redoes the skin analysis, only when the person asks: a new face photo
/// keeps the colours already read.
class SkinAnalysisBloc extends Bloc<SkinAnalysisEvent, SkinAnalysisState> {
  SkinAnalysisBloc({
    required this._getCurrentAccount,
    required this._analyseFace,
  }) : super(const SkinAnalysisState()) {
    on<SkinAnalysisRedone>(_redo, transformer: droppable());
  }

  final GetCurrentAccount _getCurrentAccount;
  final AnalyseFace _analyseFace;

  Future<void> _redo(
    SkinAnalysisRedone event,
    Emitter<SkinAnalysisState> emit,
  ) async {
    emit(const SkinAnalysisState(status: SkinAnalysisStatus.redoing));
    final account = (await _getCurrentAccount(
      const NoParams(),
    )).fold<Account?>((_) => null, (account) => account);
    if (account == null) {
      return emit(
        const SkinAnalysisState(
          status: SkinAnalysisStatus.failed,
          failure: ServerFailure(),
        ),
      );
    }
    final redone = await _analyseFace(account.id, redo: true);
    emit(
      redone.fold(
        (failure) => SkinAnalysisState(
          status: SkinAnalysisStatus.failed,
          failure: failure,
        ),
        (_) => const SkinAnalysisState(status: SkinAnalysisStatus.done),
      ),
    );
  }
}
