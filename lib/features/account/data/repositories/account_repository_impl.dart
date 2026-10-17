import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:in_vogue/features/account/data/models/account_model.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/account/domain/entities/saved_account.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/photos/data/photo_content_type.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:path/path.dart' as p;

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountRemoteDataSource remoteDataSource,
    required String downloadsDirectory,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _downloads = downloadsDirectory,
       _logger = logMessages;

  final AccountRemoteDataSource _remote;

  /// Where downloaded photos are written on the phone.
  final String _downloads;
  final LogMessages _logger;

  /// How long a call to the account may take before it counts as offline.
  static const timeLimit = Duration(seconds: 30);

  /// How long deleting an account may take before it counts as offline.
  static const deleteTimeLimit = Duration(minutes: 1);

  @override
  Future<Either<Failure, bool>> exists(String accountId) => _guard(
    'exists',
    () async => await _remote.readAccount(accountId) != null,
  );

  @override
  Future<Either<Failure, AccountPlan?>> plan(String accountId) => _guard(
    'plan',
    () async => AccountModel.planFromJson(await _remote.readAccount(accountId)),
  );

  @override
  Future<Either<Failure, Unit>> delete(String accountId) =>
      _guard('delete', () async {
        await _remote.deleteAccount(accountId);
        return unit;
      }, limit: deleteTimeLimit);

  @override
  Future<Either<Failure, Unit>> save(String accountId, AccountSetup setup) =>
      _guard('save', () async {
        await _save(accountId, setup);
        return unit;
      });

  @override
  Future<Either<Failure, SavedAccount?>> saved(String accountId) =>
      _guard('saved', () async {
        final saved = await _remote.readAccount(accountId);
        if (saved == null) return null;
        return SavedAccount(
          name: AccountModel.nameFromJson(saved),
          face: AccountModel.photosFromJson(saved)[PhotoRole.face]?.path,
          favourites: await _remote.wishlist(accountId),
        );
      });

  @override
  Future<Either<Failure, String>> downloadPhoto(String path) =>
      _guard('downloadPhoto', () async {
        final photo = await _remote.downloadPhoto(path);
        final file = File(p.join(_downloads, p.basename(path)));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(photo, flush: true);
        return file.path;
      });

  Future<void> _save(String accountId, AccountSetup setup) async {
    final saved = await _remote.readAccount(accountId);
    final savedPhotos = AccountModel.photosFromJson(saved);
    final photos = <PhotoRole, AccountPhoto>{};
    final replaced = <String>[];
    for (final photo in [setup.body, setup.face].nonNulls) {
      final sha256 = await _fingerprint(photo.path);
      final previous = savedPhotos[photo.role];
      if (previous != null && previous.sha256 == sha256) {
        // The account holds this very photo, wherever it keeps it.
        photos[photo.role] = (
          path: previous.path,
          revision: previous.revision,
          url: previous.url ?? await _remote.photoUrl(previous.path),
          sha256: sha256,
        );
        continue;
      }
      final path = AccountModel.photoPath(accountId, photo);
      final url = await _remote.uploadPhoto(
        path: path,
        file: photo.path,
        contentType: photoContentType(photo.path),
      );
      if (previous != null && previous.path != path) {
        replaced.add(previous.path);
      }
      photos[photo.role] = (
        path: path,
        revision: photo.revision,
        url: url,
        sha256: sha256,
      );
    }
    final wishlist = await _remote.wishlist(accountId);
    final add = setup.picks.difference(wishlist);
    // Only a favourite this phone unloved since it last saved goes; one
    // the phone never had stays, as after a reinstall.
    final remove = setup.syncedPicks
        .difference(setup.picks)
        .intersection(wishlist);
    if (add.isNotEmpty || remove.isNotEmpty) {
      await _remote.writeWishlist(accountId, add: add, remove: remove);
    }
    final created = saved == null;
    await _remote.writeAccount(
      accountId,
      AccountModel.toJson(setup, photos: photos, created: created),
      created: created,
    );
    for (final path in replaced) {
      // The account no longer points at it; a leftover is only untidy.
      try {
        await _remote.deletePhoto(path);
      } on Exception catch (error, stack) {
        _log('save', error, stack);
      }
    }
  }

  static Future<String> _fingerprint(String path) async =>
      sha256.convert(await File(path).readAsBytes()).toString();

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call, {
    Duration limit = timeLimit,
  }) async {
    try {
      return Right(await call().timeout(limit));
    } on TimeoutException catch (error, stack) {
      _log(method, error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(ServerFailure());
    } on FileSystemException catch (error, stack) {
      _log(method, error, stack);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'AccountRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
