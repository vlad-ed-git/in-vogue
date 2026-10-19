import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/usecases/get_plan.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_default_day.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_default_day.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the account, its plan, the place and the default day.
final class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

/// The person chose the day Home opens on.
final class SettingsDefaultDayChanged extends SettingsEvent {
  const SettingsDefaultDayChanged(this.day);
  final ForecastDay day;

  @override
  List<Object?> get props => [day];
}

/// Something setup keeps on the phone changed: it is saved on the account
/// and read again.
final class SettingsSetupChanged extends SettingsEvent {
  const SettingsSetupChanged();
}

class SettingsState extends Equatable {
  const SettingsState({
    this.account,
    this.plan,
    this.place,
    this.defaultDay = ForecastDay.tomorrow,
    this.failure,
  });

  final Account? account;
  final AccountPlan? plan;
  final UserLocation? place;
  final ForecastDay defaultDay;

  /// Why the last change could not be saved.
  final Failure? failure;

  SettingsState _with({
    AccountPlan? plan,
    UserLocation? place,
    ForecastDay? defaultDay,
    Failure? failure,
  }) => SettingsState(
    account: account,
    plan: plan ?? this.plan,
    place: place ?? this.place,
    defaultDay: defaultDay ?? this.defaultDay,
    failure: failure,
  );

  @override
  List<Object?> get props => [account, plan, place, defaultDay, failure];
}

/// What the Settings rows show, and the changes that are not a row's own.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required this._getCurrentAccount,
    required this._getPlan,
    required this._getSavedLocation,
    required this._getDefaultDay,
    required this._setDefaultDay,
    required this._saveSetupToAccount,
  }) : super(const SettingsState()) {
    on<SettingsLoaded>(_load, transformer: restartable());
    on<SettingsDefaultDayChanged>(_changeDay, transformer: sequential());
    on<SettingsSetupChanged>(_save, transformer: sequential());
  }

  final GetCurrentAccount _getCurrentAccount;
  final GetPlan _getPlan;
  final GetSavedLocation _getSavedLocation;
  final GetDefaultDay _getDefaultDay;
  final SetDefaultDay _setDefaultDay;
  final SaveSetupToAccount _saveSetupToAccount;

  Future<void> _load(SettingsLoaded event, Emitter<SettingsState> emit) async {
    final account = (await _getCurrentAccount(
      const NoParams(),
    )).fold<Account?>((_) => null, (account) => account);
    final place = (await _getSavedLocation(
      const NoParams(),
    )).fold<UserLocation?>((_) => null, (place) => place);
    final day = (await _getDefaultDay(
      const NoParams(),
    )).getOrElse(() => ForecastDay.tomorrow);
    emit(
      SettingsState(
        account: account,
        plan: state.plan,
        place: place,
        defaultDay: day,
      ),
    );
    if (account == null) return;
    final plan = (await _getPlan(
      account.id,
    )).fold<AccountPlan?>((_) => null, (plan) => plan);
    if (plan != null) emit(state._with(plan: plan));
  }

  Future<void> _changeDay(
    SettingsDefaultDayChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final saved = await _setDefaultDay(event.day);
    emit(
      saved.fold(
        (failure) => state._with(failure: failure),
        (day) => state._with(defaultDay: day),
      ),
    );
  }

  Future<void> _save(
    SettingsSetupChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final place = (await _getSavedLocation(
      const NoParams(),
    )).fold<UserLocation?>((_) => null, (place) => place);
    emit(state._with(place: place));
    final account = state.account;
    if (account == null) return;
    final saved = await _saveSetupToAccount(account.id);
    saved.fold((failure) => emit(state._with(failure: failure)), (_) {});
  }
}
