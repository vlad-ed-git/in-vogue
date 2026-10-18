import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/domain/usecases/wardrobe_usecases.dart';

sealed class WardrobeEvent extends Equatable {
  const WardrobeEvent();

  @override
  List<Object?> get props => [];
}

/// Follows the account's outfits.
final class WardrobeStarted extends WardrobeEvent {
  const WardrobeStarted();
}

/// The person removed [outfit], having confirmed it.
final class WardrobeOutfitRemoved extends WardrobeEvent {
  const WardrobeOutfitRemoved(this.outfit);
  final WardrobeOutfit outfit;

  @override
  List<Object?> get props => [outfit];
}

enum WardrobeStatus { loading, ready, failed }

class WardrobeState extends Equatable {
  const WardrobeState({
    this.status = WardrobeStatus.loading,
    this.outfits = const [],
    this.failure,
  });

  final WardrobeStatus status;

  /// Newest first.
  final List<WardrobeOutfit> outfits;
  final Failure? failure;

  @override
  List<Object?> get props => [status, outfits, failure];
}

/// The outfits the person owns, as they change on any phone.
class WardrobeBloc extends Bloc<WardrobeEvent, WardrobeState> {
  WardrobeBloc({
    required this._getCurrentAccount,
    required this._watchWardrobe,
    required this._removeFromWardrobe,
  }) : super(const WardrobeState()) {
    on<WardrobeStarted>(_start, transformer: restartable());
    on<WardrobeOutfitRemoved>(_remove, transformer: sequential());
  }

  final GetCurrentAccount _getCurrentAccount;
  final WatchWardrobe _watchWardrobe;
  final RemoveFromWardrobe _removeFromWardrobe;

  Future<String?> _account() async => (await _getCurrentAccount(
    const NoParams(),
  )).fold<Account?>((_) => null, (account) => account)?.id;

  Future<void> _start(
    WardrobeStarted event,
    Emitter<WardrobeState> emit,
  ) async {
    final accountId = await _account();
    if (accountId == null) {
      return emit(
        const WardrobeState(
          status: WardrobeStatus.failed,
          failure: ServerFailure(),
        ),
      );
    }
    await emit.forEach(
      _watchWardrobe(accountId),
      onData: (outfits) => outfits.fold(
        (failure) => WardrobeState(
          status: WardrobeStatus.failed,
          outfits: state.outfits,
          failure: failure,
        ),
        (outfits) =>
            WardrobeState(status: WardrobeStatus.ready, outfits: outfits),
      ),
    );
  }

  Future<void> _remove(
    WardrobeOutfitRemoved event,
    Emitter<WardrobeState> emit,
  ) async {
    final accountId = await _account();
    if (accountId == null) return;
    final removed = await _removeFromWardrobe(accountId, event.outfit);
    // The list follows the account; only a failure is said here.
    if (removed case Left(value: final failure)) {
      emit(
        WardrobeState(
          status: state.status,
          outfits: state.outfits,
          failure: failure,
        ),
      );
    }
  }
}
