import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';

sealed class YourPicksEvent extends Equatable {
  const YourPicksEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the loved colourways, the latest first.
final class YourPicksLoaded extends YourPicksEvent {
  const YourPicksLoaded();
}

/// The person confirmed removing a loved colourway.
final class YourPickRemoved extends YourPicksEvent {
  const YourPickRemoved(this.colourwayId);
  final String colourwayId;

  @override
  List<Object?> get props => [colourwayId];
}

enum YourPicksStatus { loading, ready, failed }

class YourPicksState extends Equatable {
  const YourPicksState({
    this.status = YourPicksStatus.loading,
    this.picks = const [],
    this.failure,
  });

  final YourPicksStatus status;

  /// The loved colourways, with their pieces.
  final List<ShopPiece> picks;

  /// Why the last removal did not happen.
  final Failure? failure;

  @override
  List<Object?> get props => [status, picks, failure];
}

/// The person's loved colourways, and nothing else.
class YourPicksBloc extends Bloc<YourPicksEvent, YourPicksState> {
  YourPicksBloc({
    required this._getPicks,
    required this._getShopPieces,
    required this._setPick,
  }) : super(const YourPicksState()) {
    on<YourPicksLoaded>(_load, transformer: droppable());
    on<YourPickRemoved>(_remove, transformer: sequential());
  }

  final GetPicks _getPicks;
  final GetShopPieces _getShopPieces;
  final SetPick _setPick;

  Future<void> _load(
    YourPicksLoaded event,
    Emitter<YourPicksState> emit,
  ) async {
    final picks = await _getPicks(const NoParams());
    final ids = picks.fold<List<String>?>(
      (_) => null,
      (picks) => picks.toList().reversed.toList(),
    );
    if (ids == null) {
      return emit(const YourPicksState(status: YourPicksStatus.failed));
    }
    final found = await _getShopPieces(ids);
    emit(
      found.fold(
        (_) => const YourPicksState(status: YourPicksStatus.failed),
        (shop) =>
            YourPicksState(status: YourPicksStatus.ready, picks: shop.pieces),
      ),
    );
  }

  Future<void> _remove(
    YourPickRemoved event,
    Emitter<YourPicksState> emit,
  ) async {
    final removed = await _setPick(
      SetPickParams(event.colourwayId, loved: false),
    );
    emit(
      removed.fold(
        (failure) => YourPicksState(
          status: state.status,
          picks: state.picks,
          failure: failure,
        ),
        (_) => YourPicksState(
          status: state.status,
          picks: [
            for (final pick in state.picks)
              if (pick.colourway.id != event.colourwayId) pick,
          ],
        ),
      ),
    );
  }
}
