import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/usecases/check_full_length.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/keep_photo.dart';

sealed class PhotoEvent extends Equatable {
  const PhotoEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the kept photo, if any.
final class PhotoLoaded extends PhotoEvent {
  const PhotoLoaded();
}

/// Work on the photo; one at a time.
sealed class PhotoAction extends PhotoEvent {
  const PhotoAction();
}

/// Opens the system picker and checks the chosen photo.
final class PhotoChooseRequested extends PhotoAction {
  const PhotoChooseRequested();
}

/// Keeps the photo on screen and moves on.
final class PhotoConfirmed extends PhotoAction {
  const PhotoConfirmed();
}

enum PhotoStatus {
  /// No photo: the example shows.
  empty,

  /// A photo that can be used is on screen.
  passed,

  /// A body photo that is not full length is on screen.
  rejected,

  /// The photo on screen is kept; setup moves on.
  confirmed,
}

class PhotoState extends Equatable {
  const PhotoState({
    this.status = PhotoStatus.empty,
    this.path,
    this.isKept = false,
    this.busy = false,
    this.failure,
  });

  final PhotoStatus status;

  /// The photo on screen; null shows the example.
  final String? path;

  /// Whether [path] is the kept photo.
  final bool isKept;

  /// Choosing, checking or keeping.
  final bool busy;
  final Failure? failure;

  PhotoState _with({
    PhotoStatus? status,
    bool busy = false,
    Failure? failure,
  }) => PhotoState(
    status: status ?? this.status,
    path: path,
    isKept: isKept,
    busy: busy,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, path, isKept, busy, failure];
}

/// One photo of the person: chosen with the system picker, checked for full
/// length when it is the body photo, and kept privately on Continue.
class PhotoBloc extends Bloc<PhotoEvent, PhotoState> {
  PhotoBloc({
    required this._role,
    required this._choosePhoto,
    required this._checkFullLength,
    required this._keepPhoto,
    required this._getKeptPhoto,
  }) : super(const PhotoState()) {
    on<PhotoLoaded>(_load);
    on<PhotoAction>(
      (event, emit) => switch (event) {
        PhotoChooseRequested() => _choose(emit),
        PhotoConfirmed() => _confirm(emit),
      },
      transformer: droppable(),
    );
  }

  final PhotoRole _role;
  final ChoosePhoto _choosePhoto;
  final CheckFullLength _checkFullLength;
  final KeepPhoto _keepPhoto;
  final GetKeptPhoto _getKeptPhoto;

  Future<void> _load(PhotoLoaded event, Emitter<PhotoState> emit) async {
    final kept = await _getKeptPhoto(_role);
    kept.fold((failure) => emit(state._with(failure: failure)), (photo) {
      if (photo != null) {
        emit(
          PhotoState(
            status: PhotoStatus.passed,
            path: photo.path,
            isKept: true,
          ),
        );
      }
    });
  }

  Future<void> _choose(Emitter<PhotoState> emit) async {
    final before = state._with();
    emit(before._with(busy: true));
    final chosen = await _choosePhoto(const NoParams());
    final failure = chosen.fold((failure) => failure, (_) => null);
    if (failure != null) return emit(before._with(failure: failure));
    final path = chosen.getOrElse(() => null);
    if (path == null) return emit(before);
    if (_role != PhotoRole.body) {
      return emit(PhotoState(status: PhotoStatus.passed, path: path));
    }
    final fullLength = await _checkFullLength(path);
    emit(
      fullLength.fold(
        (failure) => before._with(failure: failure),
        (passes) => PhotoState(
          status: passes ? PhotoStatus.passed : PhotoStatus.rejected,
          path: path,
        ),
      ),
    );
  }

  Future<void> _confirm(Emitter<PhotoState> emit) async {
    final path = state.path;
    final usable =
        state.status == PhotoStatus.passed ||
        state.status == PhotoStatus.confirmed;
    if (!usable || path == null) return;
    final shown = state._with(status: PhotoStatus.passed);
    emit(shown._with(busy: true));
    if (shown.isKept) {
      return emit(shown._with(status: PhotoStatus.confirmed));
    }
    final kept = await _keepPhoto(KeepPhotoParams(path: path, role: _role));
    emit(
      kept.fold(
        (failure) => shown._with(failure: failure),
        (photo) => PhotoState(
          status: PhotoStatus.confirmed,
          path: photo.path,
          isKept: true,
        ),
      ),
    );
  }
}
