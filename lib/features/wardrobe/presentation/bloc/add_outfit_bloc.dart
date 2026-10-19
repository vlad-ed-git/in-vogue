import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/stylist/domain/usecases/record_signal.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/domain/usecases/wardrobe_usecases.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

sealed class AddOutfitEvent extends Equatable {
  const AddOutfitEvent();

  @override
  List<Object?> get props => [];
}

/// Opens the system photo picker.
final class AddOutfitPhotoRequested extends AddOutfitEvent {
  const AddOutfitPhotoRequested();
}

final class AddOutfitNameChanged extends AddOutfitEvent {
  const AddOutfitNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class AddOutfitColourToggled extends AddOutfitEvent {
  const AddOutfitColourToggled(this.colour);
  final OutfitColour colour;

  @override
  List<Object?> get props => [colour];
}

final class AddOutfitBandToggled extends AddOutfitEvent {
  const AddOutfitBandToggled(this.band);
  final WarmthBand band;

  @override
  List<Object?> get props => [band];
}

final class AddOutfitRainToggled extends AddOutfitEvent {
  const AddOutfitRainToggled();
}

final class AddOutfitOccasionToggled extends AddOutfitEvent {
  const AddOutfitOccasionToggled(this.occasion);
  final Occasion occasion;

  @override
  List<Object?> get props => [occasion];
}

/// Saves the outfit to the wardrobe.
final class AddOutfitSaved extends AddOutfitEvent {
  const AddOutfitSaved();
}

class AddOutfitState extends Equatable {
  const AddOutfitState({
    this.photo,
    this.converted = false,
    this.choosing = false,
    this.name = '',
    this.colours = const {},
    this.bands = const {},
    this.rain = false,
    this.occasions = const {},
    this.saving = false,
    this.saved = false,
    this.failure,
  });

  /// The chosen photo, not yet kept.
  final String? photo;

  /// Whether its format was changed so it works.
  final bool converted;
  final bool choosing;
  final String name;
  final Set<OutfitColour> colours;
  final Set<WarmthBand> bands;
  final bool rain;
  final Set<Occasion> occasions;
  final bool saving;
  final bool saved;
  final Failure? failure;

  /// What was entered.
  OutfitDetails get details => OutfitDetails(
    name: name.trim(),
    colours: colours,
    bands: bands,
    rain: rain,
    occasions: occasions,
  );

  bool get canSave => photo != null && details.complete && !saving && !saved;

  AddOutfitState copyWith({
    String? Function()? photo,
    bool? converted,
    bool? choosing,
    String? name,
    Set<OutfitColour>? colours,
    Set<WarmthBand>? bands,
    bool? rain,
    Set<Occasion>? occasions,
    bool? saving,
    bool? saved,
    Failure? Function()? failure,
  }) => AddOutfitState(
    photo: photo == null ? this.photo : photo(),
    converted: converted ?? this.converted,
    choosing: choosing ?? this.choosing,
    name: name ?? this.name,
    colours: colours ?? this.colours,
    bands: bands ?? this.bands,
    rain: rain ?? this.rain,
    occasions: occasions ?? this.occasions,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [
    photo,
    converted,
    choosing,
    name,
    colours,
    bands,
    rain,
    occasions,
    saving,
    saved,
    failure,
  ];
}

/// Adding an outfit the person owns: its photo, chosen from Photos or
/// Gallery, its name and what recommendations need.
class AddOutfitBloc extends Bloc<AddOutfitEvent, AddOutfitState> {
  AddOutfitBloc({
    required this._getCurrentAccount,
    required this._choosePhoto,
    required this._addToWardrobe,
    required this._recordSignal,
  }) : super(const AddOutfitState()) {
    on<AddOutfitPhotoRequested>(_choose, transformer: droppable());
    on<AddOutfitNameChanged>(
      (event, emit) => emit(state.copyWith(name: event.name)),
    );
    on<AddOutfitColourToggled>(
      (event, emit) =>
          emit(state.copyWith(colours: _toggle(state.colours, event.colour))),
    );
    on<AddOutfitBandToggled>(
      (event, emit) =>
          emit(state.copyWith(bands: _toggle(state.bands, event.band))),
    );
    on<AddOutfitRainToggled>(
      (event, emit) => emit(state.copyWith(rain: !state.rain)),
    );
    on<AddOutfitOccasionToggled>(
      (event, emit) => emit(
        state.copyWith(occasions: _toggle(state.occasions, event.occasion)),
      ),
    );
    on<AddOutfitSaved>(_save, transformer: droppable());
  }

  final GetCurrentAccount _getCurrentAccount;
  final ChoosePhoto _choosePhoto;
  final AddToWardrobe _addToWardrobe;
  final RecordSignal _recordSignal;

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  Future<void> _choose(
    AddOutfitPhotoRequested event,
    Emitter<AddOutfitState> emit,
  ) async {
    emit(state.copyWith(choosing: true, failure: () => null));
    final chosen = await _choosePhoto(PhotoRole.body);
    emit(
      chosen.fold(
        (failure) => state.copyWith(choosing: false, failure: () => failure),
        (photo) => switch (photo) {
          ChosenPhoto(:final path, :final converted) => state.copyWith(
            photo: () => path,
            converted: converted,
            choosing: false,
          ),
          null => state.copyWith(choosing: false),
        },
      ),
    );
  }

  Future<void> _save(AddOutfitSaved event, Emitter<AddOutfitState> emit) async {
    final photo = state.photo;
    final details = state.details;
    if (!state.canSave || photo == null) return;
    emit(state.copyWith(saving: true, failure: () => null));
    final account = (await _getCurrentAccount(
      const NoParams(),
    )).fold<Account?>((_) => null, (account) => account);
    if (account == null) {
      return emit(
        state.copyWith(saving: false, failure: () => const ServerFailure()),
      );
    }
    final added = await _addToWardrobe(
      account.id,
      photo: photo,
      details: details,
    );
    if (added case Right(value: final outfit)) {
      await _recordSignal(
        TasteSignal(
          id: 'wardrobe-${outfit.id}',
          kind: TasteSignalKind.wardrobe,
          at: clock.now(),
          families: {
            for (final colour in details.colours)
              if (colour != OutfitColour.mixed) colour.name,
          },
        ),
      );
    }
    emit(
      added.fold(
        (failure) => state.copyWith(saving: false, failure: () => failure),
        (_) => state.copyWith(saving: false, saved: true),
      ),
    );
  }
}
