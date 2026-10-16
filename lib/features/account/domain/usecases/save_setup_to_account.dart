import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// Saves the name, location, photos and picks kept on the phone on the
/// account with the given id. Saves nothing when the phone's setup cannot
/// be read, so a read failure never empties the account.
class SaveSetupToAccount implements UseCase<Unit, String> {
  const SaveSetupToAccount({
    required this._account,
    required this._profile,
    required this._location,
    required this._photos,
    required this._picks,
  });

  final AccountRepository _account;
  final ProfileRepository _profile;
  final LocationRepository _location;
  final PhotoRepository _photos;
  final PicksRepository _picks;

  @override
  Future<Either<Failure, Unit>> call(String accountId) async {
    final name = await _profile.name();
    final location = await _location.savedLocation();
    final body = await _photos.kept(PhotoRole.body);
    final face = await _photos.kept(PhotoRole.face);
    final picks = await _picks.picks();
    final failure = [name, location, body, face, picks]
        .map((read) => read.fold<Failure?>((failure) => failure, (_) => null))
        .nonNulls
        .firstOrNull;
    if (failure != null) return Left(failure);
    return _account.save(
      accountId,
      AccountSetup(
        name: name.getOrElse(() => null),
        location: location.getOrElse(() => null),
        body: body.getOrElse(() => null),
        face: face.getOrElse(() => null),
        picks: picks.getOrElse(() => const {}),
      ),
    );
  }
}
