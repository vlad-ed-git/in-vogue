import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:in_vogue/features/account/data/models/account_model.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/photos/data/photo_content_type.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountRemoteDataSource remoteDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _logger = logMessages;

  final AccountRemoteDataSource _remote;
  final LogMessages _logger;

  /// How long a save may take before it counts as offline.
  static const timeLimit = Duration(seconds: 30);

  @override
  Future<Either<Failure, bool>> exists(String accountId) async {
    try {
      return Right(
        await _remote.readAccount(accountId).timeout(timeLimit) != null,
      );
    } on TimeoutException catch (error, stack) {
      _log(error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AccountPlan?>> plan(String accountId) async {
    try {
      return Right(
        AccountModel.planFromJson(
          await _remote.readAccount(accountId).timeout(timeLimit),
        ),
      );
    } on TimeoutException catch (error, stack) {
      _log(error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(ServerFailure());
    }
  }

  /// How long deleting an account may take before it counts as offline.
  static const deleteTimeLimit = Duration(minutes: 1);

  @override
  Future<Either<Failure, Unit>> delete(String accountId) async {
    try {
      await _remote.deleteAccount(accountId).timeout(deleteTimeLimit);
      return const Right(unit);
    } on TimeoutException catch (error, stack) {
      _log(error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> save(
    String accountId,
    AccountSetup setup,
  ) async {
    try {
      await _save(accountId, setup).timeout(timeLimit);
      return const Right(unit);
    } on TimeoutException catch (error, stack) {
      _log(error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(error.cause, error.stackTrace);
      return const Left(ServerFailure());
    }
  }

  Future<void> _save(String accountId, AccountSetup setup) async {
    final saved = await _remote.readAccount(accountId);
    final savedPhotos = AccountModel.photosFromJson(saved);
    final photos = <PhotoRole, AccountPhoto>{};
    final replaced = <String>[];
    for (final photo in [setup.body, setup.face].nonNulls) {
      final path = AccountModel.photoPath(accountId, photo);
      final previous = savedPhotos[photo.role];
      final String url;
      if (previous?.path != path || previous?.revision != photo.revision) {
        url = await _remote.uploadPhoto(
          path: path,
          file: photo.path,
          contentType: photoContentType(photo.path),
        );
        if (previous != null && previous.path != path) {
          replaced.add(previous.path);
        }
      } else {
        url = previous?.url ?? await _remote.photoUrl(path);
      }
      photos[photo.role] = (path: path, revision: photo.revision, url: url);
    }
    final wishlist = await _remote.wishlist(accountId);
    final add = setup.picks.difference(wishlist);
    final remove = wishlist.difference(setup.picks);
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
        _log(error, stack);
      }
    }
  }

  void _log(Object error, StackTrace stackTrace) => _logger.logError(
    callerClass: 'AccountRepositoryImpl',
    callerMethod: 'save',
    error: error,
    stackTrace: stackTrace,
  );
}
