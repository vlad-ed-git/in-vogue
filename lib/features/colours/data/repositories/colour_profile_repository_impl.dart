import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/colours/data/data_sources/colour_profile_remote_data_source.dart';
import 'package:in_vogue/features/colours/data/models/face_colours_model.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/repositories/colour_profile_repository.dart';

/// A face photo's colours are kept under its fingerprint, so they always
/// belong to that photo.
class ColourProfileRepositoryImpl implements ColourProfileRepository {
  ColourProfileRepositoryImpl({
    required ColourProfileRemoteDataSource remoteDataSource,
    required this._fingerprints,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _logger = logMessages;

  final ColourProfileRemoteDataSource _remote;
  final PhotoFingerprints _fingerprints;
  final LogMessages _logger;

  /// How long a read or write may take.
  static const timeLimit = Duration(seconds: 20);

  @override
  Future<Either<Failure, FaceColours?>> colours(
    String accountId,
    String facePhoto,
  ) => _guard('colours', () async {
    final json = await _remote.colours(
      accountId,
      await _fingerprints.of(facePhoto),
    );
    return json == null ? null : FaceColoursModel.fromJson(json);
  });

  @override
  Future<Either<Failure, FaceColours?>> latest(String accountId) =>
      _guard('latest', () async {
        final json = await _remote.latest(accountId);
        return json == null ? null : FaceColoursModel.fromJson(json);
      });

  @override
  Future<Either<Failure, Unit>> save(
    String accountId,
    String facePhoto,
    FaceColours colours,
  ) => _guard('save', () async {
    await _remote.save(
      accountId,
      await _fingerprints.of(facePhoto),
      FaceColoursModel.toJson(colours),
    );
    return unit;
  });

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call,
  ) async {
    try {
      return Right(await call().timeout(timeLimit));
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
        callerClass: 'ColourProfileRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
