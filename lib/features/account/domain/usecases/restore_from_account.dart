import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// Brings back to the phone what the account with the given id keeps: the
/// name and the face photo when the phone has none, and the favourites,
/// added to the picks. Does nothing for an account never saved. A part
/// that cannot be brought back is left out.
class RestoreFromAccount implements UseCase<Unit, String> {
  const RestoreFromAccount({
    required this._account,
    required this._profile,
    required this._photos,
    required this._picks,
  });

  final AccountRepository _account;
  final ProfileRepository _profile;
  final PhotoRepository _photos;
  final PicksRepository _picks;

  @override
  Future<Either<Failure, Unit>> call(String accountId) async {
    final saved = await _account.saved(accountId);
    if (saved case Left(value: final failure)) return Left(failure);
    final account = saved.getOrElse(() => null);
    if (account == null) return const Right(unit);
    if (account.name case final name?) {
      if (await _profile.name() case Right(value: null)) {
        await _profile.saveName(name);
      }
    }
    if (account.face case final face?) {
      if (await _photos.kept(PhotoRole.face) case Right(value: null)) {
        final downloaded = await _account.downloadPhoto(face);
        if (downloaded case Right(value: final file)) {
          await _photos.keep(file, PhotoRole.face);
        }
      }
    }
    if (account.favourites.isNotEmpty) {
      if (await _picks.addPicks(account.favourites) case Right()) {
        // They are on the account: unloving one here removes it there.
        final synced = await _picks.synced(accountId);
        await _picks.markSynced(accountId, {
          ...synced.getOrElse(() => const {}),
          ...account.favourites,
        });
      }
    }
    return const Right(unit);
  }
}
