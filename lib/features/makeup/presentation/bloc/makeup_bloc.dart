import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_update.dart';
import 'package:in_vogue/features/makeup/domain/services/make_look.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_latest_makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_makeup_look.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

/// The day an outfit is shown for, and the outfit, when there is one.
class MakeupDay extends Equatable {
  const MakeupDay({
    required this.day,
    this.occasion,
    this.outfit,
    this.weather,
    this.outfitPending = false,
  });

  final ForecastDay day;
  final Occasion? occasion;
  final DayOutfit? outfit;

  /// The day's weather in the occasion's hours.
  final WeatherClass? weather;

  /// Whether the outfit is still being looked up or made.
  final bool outfitPending;

  String? get signature => outfit?.outfit.signature;

  @override
  List<Object?> get props => [day, occasion, outfit, weather, outfitPending];
}

sealed class MakeupEvent extends Equatable {
  const MakeupEvent();

  @override
  List<Object?> get props => [];
}

/// The outfit's day to make up for changed to [day].
final class MakeupDayShown extends MakeupEvent {
  const MakeupDayShown(this.day);
  final MakeupDay day;

  @override
  List<Object?> get props => [day];
}

/// A face photo was kept, or the person asked to try again.
final class MakeupRequested extends MakeupEvent {
  const MakeupRequested();
}

/// Follows the making of a look.
final class _MakingFollowed extends MakeupEvent {
  const _MakingFollowed(this.params);
  final MakeLookParams params;

  @override
  List<Object?> get props => [params];
}

enum MakeupStatus { loading, ready }

class MakeupState extends Equatable {
  const MakeupState({
    this.day = const MakeupDay(day: ForecastDay.tomorrow),
    this.status = MakeupStatus.loading,
    this.look,
    this.lastLook,
    this.making,
    this.failure,
  });

  final MakeupDay day;
  final MakeupStatus status;

  /// The look made for the day's outfit.
  final MakeupLook? look;

  /// The look made last, for another outfit; null when there is a [look].
  final MakeupLook? lastLook;

  /// The steps of the look being made, those made with their pictures.
  final List<LookStep>? making;
  final Failure? failure;

  MakeupState _with({
    MakeupLook? look,
    MakeupLook? lastLook,
    List<LookStep>? making,
    Failure? failure,
  }) => MakeupState(
    day: day,
    status: status,
    look: look,
    lastLook: lastLook,
    making: making,
    failure: failure,
  );

  @override
  List<Object?> get props => [day, status, look, lastLook, making, failure];
}

/// The makeup look for the outfit of the day shown: the look made for it,
/// or the one being made, with the last look below until then.
/// A look is made by itself once there is a face photo and an outfit,
/// and one cut short goes on; one that failed is made again only when
/// asked.
class MakeupBloc extends Bloc<MakeupEvent, MakeupState> {
  MakeupBloc({
    required this._getCurrentAccount,
    required this._getMakeupLook,
    required this._getLatestMakeupLook,
    required this._getKeptPhoto,
    required this._makeLook,
  }) : super(const MakeupState()) {
    on<MakeupDayShown>(_show, transformer: restartable());
    on<MakeupRequested>(_request, transformer: droppable());
    on<_MakingFollowed>(_follow, transformer: restartable());
  }

  final GetCurrentAccount _getCurrentAccount;
  final GetMakeupLook _getMakeupLook;
  final GetLatestMakeupLook _getLatestMakeupLook;
  final GetKeptPhoto _getKeptPhoto;
  final MakeLook _makeLook;

  String? _accountId;

  Future<String?> _account() async => _accountId ??= (await _getCurrentAccount(
    const NoParams(),
  )).fold<Account?>((_) => null, (account) => account)?.id;

  Future<bool> _hasFace() async => (await _getKeptPhoto(
    PhotoRole.face,
  )).fold((_) => false, (photo) => photo != null);

  MakeLookParams _params(String accountId, DayOutfit outfit) => MakeLookParams(
    accountId: accountId,
    outfit: outfit,
    weather: state.day.weather,
  );

  Future<void> _show(MakeupDayShown event, Emitter<MakeupState> emit) async {
    final day = event.day;
    if (day.signature == state.day.signature &&
        state.status == MakeupStatus.ready) {
      return emit(
        MakeupState(
          day: day,
          status: MakeupStatus.ready,
          look: state.look,
          lastLook: state.lastLook,
          making: state.making,
          failure: state.failure,
        ),
      );
    }
    emit(MakeupState(day: day, lastLook: state.lastLook ?? state.look));
    final accountId = await _account();
    final outfit = day.outfit;
    if (accountId == null) {
      return emit(
        MakeupState(
          day: day,
          status: MakeupStatus.ready,
          failure: const ServerFailure(),
        ),
      );
    }
    MakeupLook? look;
    if (outfit != null) {
      final found = await _getMakeupLook(
        MakeupLookParams(
          accountId: accountId,
          outfitSignature: outfit.outfit.signature,
        ),
      );
      if (found case Left(value: final failure)) {
        return emit(
          MakeupState(
            day: day,
            status: MakeupStatus.ready,
            lastLook: state.lastLook,
            failure: failure,
          ),
        );
      }
      look = found.getOrElse(() => null);
    }
    final last = look != null
        ? null
        : (await _getLatestMakeupLook(
            accountId,
          )).fold<MakeupLook?>((_) => null, (look) => look);
    emit(
      MakeupState(
        day: day,
        status: MakeupStatus.ready,
        look: look,
        lastLook: last,
      ),
    );
    if (outfit != null && look == null) {
      final params = _params(accountId, outfit);
      if (await _makeLook.underway(params) || await _hasFace()) {
        add(_MakingFollowed(params));
      }
    }
  }

  Future<void> _request(
    MakeupRequested event,
    Emitter<MakeupState> emit,
  ) async {
    final outfit = state.day.outfit;
    final accountId = await _account();
    if (outfit == null ||
        accountId == null ||
        state.status != MakeupStatus.ready ||
        state.look != null ||
        state.making != null ||
        !await _hasFace()) {
      return;
    }
    add(_MakingFollowed(_params(accountId, outfit)));
  }

  Future<void> _follow(_MakingFollowed event, Emitter<MakeupState> emit) async {
    final signature = event.params.outfit.outfit.signature;
    bool shown() => state.day.signature == signature;
    if (shown()) {
      emit(state._with(lastLook: state.lastLook, making: state.making ?? []));
    }
    await emit.forEach<MakeupUpdate>(
      _makeLook(event.params),
      onData: (update) {
        // The day may have moved on to another outfit.
        if (!shown()) return state;
        return switch (update) {
          MakeupProgress(:final steps) => state._with(
            lastLook: state.lastLook,
            making: steps,
          ),
          MakeupDone(:final look) => state._with(look: look),
          MakeupFailed(:final failure) => state._with(
            lastLook: state.lastLook,
            failure: failure,
          ),
        };
      },
    );
  }
}
