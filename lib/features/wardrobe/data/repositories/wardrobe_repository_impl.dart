import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/photos/data/photo_content_type.dart';
import 'package:in_vogue/features/wardrobe/data/data_sources/wardrobe_photo_local_data_source.dart';
import 'package:in_vogue/features/wardrobe/data/data_sources/wardrobe_remote_data_source.dart';
import 'package:in_vogue/features/wardrobe/data/models/wardrobe_outfit_model.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/domain/repositories/wardrobe_repository.dart';

/// Outfits live on the account; each photo is uploaded to Storage and
/// copied to the phone, so the phone that added it shows it at once.
class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({
    required WardrobeRemoteDataSource remoteDataSource,
    required WardrobePhotoLocalDataSource photoDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _photos = photoDataSource,
       _logger = logMessages;

  final WardrobeRemoteDataSource _remote;
  final WardrobePhotoLocalDataSource _photos;
  final LogMessages _logger;

  @override
  Stream<Either<Failure, List<WardrobeOutfit>>> watch(String accountId) =>
      _remote
          .watch(accountId)
          .map<Either<Failure, List<WardrobeOutfit>>>(
            (records) => Right([
              for (final (id, json) in records)
                ?WardrobeOutfitModel.fromJson(
                  id,
                  json,
                  photo: _photos.photo(accountId, id),
                ),
            ]),
          )
          .transform(
            StreamTransformer.fromHandlers(
              handleError: (error, stack, sink) {
                _log('watch', error, stack);
                sink.add(Left(_failureOf(error)));
              },
            ),
          );

  @override
  Future<Either<Failure, WardrobeOutfit>> add(
    String accountId, {
    required String photo,
    required OutfitDetails details,
  }) async {
    final id = _remote.newId(accountId);
    String? kept;
    try {
      kept = await _photos.keep(accountId, id, photo);
      final (path, url) = await _remote.uploadPhoto(
        accountId,
        id,
        file: kept,
        contentType: photoContentType(kept),
      );
      final createdAt = clock.now();
      await _remote.save(
        accountId,
        id,
        WardrobeOutfitModel.toJson(
          details: details,
          photoPath: path,
          photoUrl: url,
          createdAt: createdAt,
        ),
      );
      return Right(
        WardrobeOutfit(
          id: id,
          details: details,
          photoUrl: url,
          photoPath: kept,
          createdAt: createdAt,
        ),
      );
    } on Exception catch (error, stack) {
      _log('add', error, stack);
      // Nothing stays half-added on the phone.
      if (kept != null) await _forgetPhoto(accountId, id);
      return Left(_failureOf(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> remove(
    String accountId,
    WardrobeOutfit outfit,
  ) async {
    try {
      await _remote.delete(accountId, outfit.id);
      await _photos.delete(accountId, outfit.id);
      return const Right(unit);
    } on Exception catch (error, stack) {
      _log('remove', error, stack);
      return Left(_failureOf(error));
    }
  }

  @override
  Future<void> forgetPhotos(String accountId) async {
    try {
      await _photos.forget(accountId);
    } on CacheException catch (error) {
      _log('forgetPhotos', error.cause, error.stackTrace);
    }
  }

  Future<void> _forgetPhoto(String accountId, String id) async {
    try {
      await _photos.delete(accountId, id);
    } on CacheException catch (error) {
      _log('add', error.cause, error.stackTrace);
    }
  }

  static Failure _failureOf(Object error) => switch (error) {
    NetworkException() => const NetworkFailure(),
    CacheException() => const CacheFailure(),
    _ => const ServerFailure(),
  };

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'WardrobeRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
