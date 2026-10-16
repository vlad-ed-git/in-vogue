import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_pieces_for_weather.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

sealed class PicksEvent extends Equatable {
  const PicksEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the pieces worn in [band], with the saved picks.
final class PicksRequested extends PicksEvent {
  const PicksRequested(this.band);
  final WarmthBand band;

  @override
  List<Object?> get props => [band];
}

/// Loves or unloves a colourway.
final class PickToggled extends PicksEvent {
  const PickToggled(this.colourwayId, {required this.loved});
  final String colourwayId;
  final bool loved;

  @override
  List<Object?> get props => [colourwayId, loved];
}

enum PicksStatus { loading, ready, failed }

class PicksState extends Equatable {
  const PicksState({
    this.status = PicksStatus.loading,
    this.pieces = const [],
    this.picks = const {},
    this.failure,
  });

  final PicksStatus status;
  final List<Piece> pieces;

  /// Ids of the loved colourways.
  final Set<String> picks;

  /// Why the last pick could not be saved.
  final Failure? failure;

  @override
  List<Object?> get props => [status, pieces, picks, failure];
}

/// Pieces to love, so outfits lean towards the person's taste. A heart shows
/// at once and is taken back if it cannot be saved.
class PicksBloc extends Bloc<PicksEvent, PicksState> {
  PicksBloc({
    required this._getPiecesForWeather,
    required this._getPicks,
    required this._setPick,
  }) : super(const PicksState()) {
    on<PicksRequested>(_load, transformer: restartable());
    on<PickToggled>(_toggle, transformer: sequential());
  }

  final GetPiecesForWeather _getPiecesForWeather;
  final GetPicks _getPicks;
  final SetPick _setPick;

  Future<void> _load(PicksRequested event, Emitter<PicksState> emit) async {
    final pieces = await _getPiecesForWeather(event.band);
    final picks = await _getPicks(const NoParams());
    emit(
      pieces.fold(
        (_) => PicksState(status: PicksStatus.failed, picks: state.picks),
        (pieces) => PicksState(
          status: PicksStatus.ready,
          pieces: pieces,
          picks: picks.getOrElse(() => state.picks),
        ),
      ),
    );
  }

  Future<void> _toggle(PickToggled event, Emitter<PicksState> emit) async {
    final before = state;
    final shown = {...before.picks};
    event.loved
        ? shown.add(event.colourwayId)
        : shown.remove(event.colourwayId);
    emit(
      PicksState(status: before.status, pieces: before.pieces, picks: shown),
    );
    final saved = await _setPick(
      SetPickParams(event.colourwayId, loved: event.loved),
    );
    emit(
      saved.fold(
        (failure) => PicksState(
          status: before.status,
          pieces: before.pieces,
          picks: before.picks,
          failure: failure,
        ),
        (picks) => PicksState(
          status: state.status,
          pieces: state.pieces,
          picks: picks,
        ),
      ),
    );
  }
}
