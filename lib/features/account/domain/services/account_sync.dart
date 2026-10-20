import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:in_vogue/features/stylist/domain/repositories/taste_repository.dart';

/// Keeps the phone and the account in step in the background, so no screen
/// waits on the network. Its steps run one at a time, in the order asked.
class AccountSync {
  AccountSync({
    required this._account,
    required this._profile,
    required this._photos,
    required this._picks,
    required this._taste,
    required this._saveSetupToAccount,
  });

  final AccountRepository _account;
  final ProfileRepository _profile;
  final PhotoRepository _photos;
  final PicksRepository _picks;
  final TasteRepository _taste;
  final SaveSetupToAccount _saveSetupToAccount;

  Future<void> _last = Future<void>.value();
  Future<void> _name = Future<void>.value();
  Future<void> _face = Future<void>.value();

  /// Done once the name of the account last signed in to is on the phone,
  /// or there is none to bring back.
  Future<void> get nameRestored => _name;

  /// Done once its face photo is on the phone, or there is none to bring
  /// back.
  Future<void> get faceRestored => _face;

  /// Brings back to the phone what the account [accountId] keeps: the name
  /// and the face photo when the phone has none, from one fetch of the
  /// profile, then the taste learnt on other phones and the favourites,
  /// added to the picks. Then saves the phone's setup on the account. A part
  /// that cannot be brought back is left out, and nothing stops the save.
  Future<void> signedIn(String accountId) async {
    final saved = _then(
      () async => (await _account.saved(accountId)).getOrElse(() => null),
    );
    _name = _then(() async {
      if ((await saved)?.name case final name?) {
        if (await _profile.name() case Right(value: null)) {
          await _profile.saveName(name);
        }
      }
    });
    _face = _then(() async {
      if ((await saved)?.face case final face?) {
        if (await _photos.kept(PhotoRole.face) case Right(value: null)) {
          final downloaded = await _account.downloadPhoto(face);
          // A face photo the person chose meanwhile stays.
          if (downloaded case Right(value: final file)) {
            if (await _photos.kept(PhotoRole.face) case Right(value: null)) {
              await _photos.keep(file, PhotoRole.face);
            }
          }
        }
      }
    });
    unawaited(
      _then(() async {
        if (await saved == null) return;
        await _taste.restore(accountId);
        await _restoreFavourites(accountId);
      }),
    );
    await save(accountId);
  }

  /// Saves the phone's setup on the account [accountId], after the steps
  /// asked before.
  Future<Either<Failure, Unit>> save(String accountId) =>
      _then(() => _saveSetupToAccount(accountId));

  Future<void> _restoreFavourites(String accountId) async {
    final favourites = (await _account.favourites(
      accountId,
    )).getOrElse(() => const {});
    if (favourites.isEmpty) return;
    if (await _picks.addPicks(favourites) case Right()) {
      // They are on the account: unloving one here removes it there.
      final synced = await _picks.synced(accountId);
      await _picks.markSynced(accountId, {
        ...synced.getOrElse(() => const {}),
        ...favourites,
      });
    }
  }

  /// Runs [step] once the steps before it are done.
  Future<T> _then<T>(Future<T> Function() step) {
    final next = _last.then((_) => step());
    _last = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
