import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/domain/services/analyse_face.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';

sealed class ColoursEvent extends Equatable {
  const ColoursEvent();

  @override
  List<Object?> get props => [];
}

/// The Mirror tab came on screen, a face photo was kept, or the person
/// asked to try again: reads the face photo's colours.
final class ColoursShown extends ColoursEvent {
  const ColoursShown();
}

enum ColoursStatus { loading, noPhoto, reading, ready, failed }

class ColoursState extends Equatable {
  const ColoursState({
    this.status = ColoursStatus.loading,
    this.reading,
    this.failure,
  });

  final ColoursStatus status;
  final ColourReading? reading;
  final Failure? failure;

  @override
  List<Object?> get props => [status, reading, failure];
}

/// The colours that suit the person, read from their kept face photo; a
/// reading shown stays while the same photo is checked again.
class ColoursBloc extends Bloc<ColoursEvent, ColoursState> {
  ColoursBloc({
    required this._getCurrentAccount,
    required this._getKeptPhoto,
    required this._analyseFace,
  }) : super(const ColoursState()) {
    on<ColoursShown>(_show, transformer: restartable());
  }

  final GetCurrentAccount _getCurrentAccount;
  final GetKeptPhoto _getKeptPhoto;
  final AnalyseFace _analyseFace;

  /// The face photo the reading on screen comes from.
  int? _revision;

  Future<void> _show(ColoursShown event, Emitter<ColoursState> emit) async {
    final face = (await _getKeptPhoto(
      PhotoRole.face,
    )).fold<UserPhoto?>((_) => null, (photo) => photo);
    if (face == null) {
      _revision = null;
      return emit(const ColoursState(status: ColoursStatus.noPhoto));
    }
    final account = (await _getCurrentAccount(
      const NoParams(),
    )).fold<Account?>((_) => null, (account) => account);
    if (account == null) {
      return emit(
        const ColoursState(
          status: ColoursStatus.failed,
          failure: ServerFailure(),
        ),
      );
    }
    if (state.status != ColoursStatus.ready || _revision != face.revision) {
      emit(const ColoursState(status: ColoursStatus.reading));
    }
    final colours = await _analyseFace(account.id);
    colours.fold(
      (failure) =>
          emit(ColoursState(status: ColoursStatus.failed, failure: failure)),
      (colours) {
        _revision = face.revision;
        emit(
          ColoursState(
            status: ColoursStatus.ready,
            reading: SeasonRules.readingOf(colours),
          ),
        );
      },
    );
  }
}
