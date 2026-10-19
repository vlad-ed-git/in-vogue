import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/stylist/domain/usecases/record_signal.dart';

sealed class PicksEvent extends Equatable {
  const PicksEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the onboarding sample, or the first page of the catalog's outfits
/// that pass [filter], with the saved picks.
final class PicksRequested extends PicksEvent {
  const PicksRequested.sample() : filter = null;
  const PicksRequested.catalog([
    CatalogFilter this.filter = const CatalogFilter.all(),
  ]);

  /// Null for the sample.
  final CatalogFilter? filter;

  @override
  List<Object?> get props => [filter];
}

/// Adds the catalog's next page.
final class PicksMoreRequested extends PicksEvent {
  const PicksMoreRequested();
}

/// Loves or unloves an outfit.
final class PickToggled extends PicksEvent {
  const PickToggled(this.outfitId, {required this.loved});
  final String outfitId;
  final bool loved;

  @override
  List<Object?> get props => [outfitId, loved];
}

enum PicksStatus { loading, ready, failed }

class PicksState extends Equatable {
  const PicksState({
    this.status = PicksStatus.loading,
    this.filter,
    this.outfits = const [],
    this.hasMore = false,
    this.picks = const {},
    this.loadFailure,
    this.failure,
  });

  final PicksStatus status;

  /// The catalog's filter; null for the sample.
  final CatalogFilter? filter;
  final List<CatalogOutfit> outfits;

  /// Whether the catalog has another page.
  final bool hasMore;

  /// Ids of the loved outfits.
  final Set<String> picks;

  /// Why the outfits could not be read.
  final Failure? loadFailure;

  /// Why the last pick could not be saved.
  final Failure? failure;

  PicksState copyWith({
    PicksStatus? status,
    List<CatalogOutfit>? outfits,
    bool? hasMore,
    Set<String>? picks,
    Failure? loadFailure,
    Failure? failure,
  }) => PicksState(
    status: status ?? this.status,
    filter: filter,
    outfits: outfits ?? this.outfits,
    hasMore: hasMore ?? this.hasMore,
    picks: picks ?? this.picks,
    loadFailure: loadFailure,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    filter,
    outfits,
    hasMore,
    picks,
    loadFailure,
    failure,
  ];
}

/// Outfits to love, so outfits made later lean towards the person's taste.
/// A heart shows at once and is taken back if it cannot be saved.
class PicksBloc extends Bloc<PicksEvent, PicksState> {
  PicksBloc({
    required this._getSampleOutfits,
    required this._getCatalogPage,
    required this._getPicks,
    required this._setPick,
    required this._recordSignal,
  }) : super(const PicksState()) {
    on<PicksRequested>(_load, transformer: restartable());
    on<PicksMoreRequested>(_more, transformer: droppable());
    on<PickToggled>(_toggle, transformer: sequential());
  }

  final GetSampleOutfits _getSampleOutfits;
  final GetCatalogPage _getCatalogPage;
  final GetPicks _getPicks;
  final SetPick _setPick;
  final RecordSignal _recordSignal;

  Future<void> _load(PicksRequested event, Emitter<PicksState> emit) async {
    final filter = event.filter;
    emit(PicksState(filter: filter, picks: state.picks));
    final picks = await _getPicks(const NoParams());
    final shown = picks.getOrElse(() => state.picks);
    if (filter == null) {
      final sample = await _getSampleOutfits(const NoParams());
      return emit(
        sample.fold(
          (failure) => PicksState(
            status: PicksStatus.failed,
            picks: shown,
            loadFailure: failure,
          ),
          (outfits) => PicksState(
            status: PicksStatus.ready,
            outfits: outfits,
            picks: shown,
          ),
        ),
      );
    }
    final page = await _getCatalogPage(CatalogPageParams(filter: filter));
    emit(
      page.fold(
        (failure) => PicksState(
          status: PicksStatus.failed,
          filter: filter,
          picks: shown,
          loadFailure: failure,
        ),
        (page) => PicksState(
          status: PicksStatus.ready,
          filter: filter,
          outfits: page.outfits,
          hasMore: page.hasMore,
          picks: shown,
        ),
      ),
    );
  }

  Future<void> _more(PicksMoreRequested event, Emitter<PicksState> emit) async {
    final filter = state.filter;
    if (filter == null || !state.hasMore || state.status != PicksStatus.ready) {
      return;
    }
    final page = await _getCatalogPage(
      CatalogPageParams(filter: filter, offset: state.outfits.length),
    );
    // A new filter chosen meanwhile wins.
    if (state.filter != filter) return;
    page.fold(
      (_) {},
      (page) => emit(
        state.copyWith(
          outfits: [...state.outfits, ...page.outfits],
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _toggle(PickToggled event, Emitter<PicksState> emit) async {
    final before = state.picks;
    final shown = {...before};
    event.loved ? shown.add(event.outfitId) : shown.remove(event.outfitId);
    emit(state.copyWith(picks: shown, loadFailure: state.loadFailure));
    final saved = await _setPick(
      SetPickParams(event.outfitId, loved: event.loved),
    );
    emit(
      saved.fold(
        (failure) => state.copyWith(
          picks: before,
          loadFailure: state.loadFailure,
          failure: failure,
        ),
        (picks) => state.copyWith(picks: picks, loadFailure: state.loadFailure),
      ),
    );
    if (saved.isLeft()) return;
    final kind = !event.loved
        ? TasteSignalKind.unloved
        : state.filter == null
        ? TasteSignalKind.picked
        : TasteSignalKind.loved;
    final now = clock.now();
    await _recordSignal(
      TasteSignal(
        id: '${kind.name}-${event.outfitId}-${now.microsecondsSinceEpoch}',
        kind: kind,
        at: now,
        outfitId: event.outfitId,
      ),
    );
  }
}
