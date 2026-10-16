import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/profile/domain/usecases/get_profile_name.dart';
import 'package:in_vogue/features/profile/domain/usecases/save_profile_name.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Fills in the saved name, or the one the sign-in provider shared.
final class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

/// Saves the name the person typed.
final class ProfileNameSaved extends ProfileEvent {
  const ProfileNameSaved(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

enum ProfileStatus { loading, ready, saving, saved }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.name = '',
    this.failure,
  });

  final ProfileStatus status;
  final String name;
  final Failure? failure;

  @override
  List<Object?> get props => [status, name, failure];
}

/// The name In Vogue uses for the person. A saved name, and the face photo,
/// are saved on the signed-in account too; a failed account save does not
/// stop the person.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getProfileName,
    required this._saveProfileName,
    required this._getCurrentAccount,
    required this._saveSetupToAccount,
  }) : super(const ProfileState()) {
    on<ProfileLoaded>(_load);
    on<ProfileNameSaved>(_save, transformer: droppable());
  }

  final GetProfileName _getProfileName;
  final SaveProfileName _saveProfileName;
  final GetCurrentAccount _getCurrentAccount;
  final SaveSetupToAccount _saveSetupToAccount;

  Future<void> _load(ProfileLoaded event, Emitter<ProfileState> emit) async {
    final saved = (await _getProfileName(
      const NoParams(),
    )).getOrElse(() => null);
    final shared = saved == null
        ? (await _getCurrentAccount(
            const NoParams(),
          )).getOrElse(() => null)?.name
        : null;
    emit(
      ProfileState(status: ProfileStatus.ready, name: saved ?? shared ?? ''),
    );
  }

  Future<void> _save(ProfileNameSaved event, Emitter<ProfileState> emit) async {
    if (event.name.trim().isEmpty) return;
    emit(ProfileState(status: ProfileStatus.saving, name: event.name));
    final saved = await _saveProfileName(event.name);
    final name = saved.fold<String?>((_) => null, (name) => name);
    if (name == null) {
      return emit(
        ProfileState(
          status: ProfileStatus.ready,
          name: event.name,
          failure: saved.fold((failure) => failure, (_) => null),
        ),
      );
    }
    final account = (await _getCurrentAccount(
      const NoParams(),
    )).getOrElse(() => null);
    // The repository logs a failed save; the try-on saves again first.
    if (account != null) await _saveSetupToAccount(account.id);
    emit(ProfileState(status: ProfileStatus.saved, name: name));
  }
}
