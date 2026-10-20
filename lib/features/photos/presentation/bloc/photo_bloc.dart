import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/keep_photo.dart';

sealed class PhotoEvent extends Equatable {
  const PhotoEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the kept photo, if any, and once [after] is done, one brought back
/// meanwhile.
final class PhotoLoaded extends PhotoEvent {
  const PhotoLoaded({this.after});
  final Future<void>? after;

  @override
  List<Object?> get props => [after];
}

/// Work on the photo; one at a time.
sealed class PhotoAction extends PhotoEvent {
  const PhotoAction();
}

/// Opens the system picker.
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

  /// The person's chosen photo is on screen.
  chosen,

  /// The photo on screen is kept; setup moves on.
  confirmed,
}

class PhotoState extends Equatable {
  const PhotoState({
    this.status = PhotoStatus.empty,
    this.path,
    this.isKept = false,
    this.converted = false,
    this.busy = false,
    this.failure,
  });

  final PhotoStatus status;

  /// The photo on screen; null shows the example.
  final String? path;

  /// Whether [path] is the kept photo.
  final bool isKept;

  /// Whether [path]'s format was changed so YouCam takes it; it stays so
  /// once kept.
  final bool converted;

  /// Choosing or keeping.
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
    converted: converted,
    busy: busy,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, path, isKept, converted, busy, failure];
}

/// One photo of the person: chosen with the system picker, trusted as the
/// person's own, and kept privately on Continue.
class PhotoBloc extends Bloc<PhotoEvent, PhotoState> {
  PhotoBloc({
    required this._role,
    required this._choosePhoto,
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
  final KeepPhoto _keepPhoto;
  final GetKeptPhoto _getKeptPhoto;

  Future<void> _load(PhotoLoaded event, Emitter<PhotoState> emit) async {
    await _show(emit);
    if (event.after case final after?) {
      await after;
      // A photo the person chose, or is choosing, stays.
      if (state.status == PhotoStatus.empty && !state.busy) await _show(emit);
    }
  }

  Future<void> _show(Emitter<PhotoState> emit) async {
    final kept = await _getKeptPhoto(_role);
    kept.fold((failure) => emit(state._with(failure: failure)), (photo) {
      if (photo != null) {
        emit(
          PhotoState(
            status: PhotoStatus.chosen,
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
    final chosen = await _choosePhoto(_role);
    final failure = chosen.fold((failure) => failure, (_) => null);
    if (failure != null) return emit(before._with(failure: failure));
    final photo = chosen.getOrElse(() => null);
    if (photo == null) return emit(before);
    emit(
      PhotoState(
        status: PhotoStatus.chosen,
        path: photo.path,
        converted: photo.converted,
      ),
    );
  }

  Future<void> _confirm(Emitter<PhotoState> emit) async {
    final path = state.path;
    if (state.status == PhotoStatus.empty || path == null) return;
    final shown = state._with(status: PhotoStatus.chosen);
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
          converted: shown.converted,
        ),
      ),
    );
  }
}
