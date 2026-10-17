import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/day_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:path/path.dart' as p;

/// Days and suggestions in Firestore, which keeps a copy on the phone and
/// syncs it; pictures in Storage, with a copy of each on the phone.
class DayRepositoryImpl implements DayRepository {
  DayRepositoryImpl({
    required DayRemoteDataSource remoteDataSource,
    required OutfitPictureRemoteDataSource pictureRemoteDataSource,
    required OutfitPictureLocalDataSource pictureLocalDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _pictures = pictureRemoteDataSource,
       _phone = pictureLocalDataSource,
       _logger = logMessages;

  final DayRemoteDataSource _remote;
  final OutfitPictureRemoteDataSource _pictures;
  final OutfitPictureLocalDataSource _phone;
  final LogMessages _logger;

  /// How long a call may take before it counts as offline.
  static const timeLimit = Duration(seconds: 30);

  /// How long moving a picture to or from the account may take.
  static const pictureTimeLimit = Duration(minutes: 2);

  /// Where the picture [name] of [accountId]'s days is in Storage.
  static String picturePath(String accountId, String name) =>
      'users/$accountId/days/$name';

  @override
  Stream<Either<Failure, Day?>> watch(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  }) => _remote
      .watch(accountId, Day.keyFor(date, occasion))
      .map<Either<Failure, Day?>>(Right.new)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stack, sink) {
            _log('watch', error, stack);
            sink.add(
              Left(
                error is NetworkException
                    ? const NetworkFailure()
                    : const ServerFailure(),
              ),
            );
          },
        ),
      );

  @override
  Future<Either<Failure, Day?>> day(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  }) => _guard('day', () => _remote.day(accountId, Day.keyFor(date, occasion)));

  @override
  Future<Either<Failure, Map<String, DateTime?>>> suggested(
    String accountId,
    List<String> signatures,
  ) => _guard('suggested', () => _remote.suggested(accountId, signatures));

  @override
  Future<Either<Failure, Unit>> refuse(
    String accountId,
    String signature,
    String piece,
  ) => _guard('refuse', () async {
    await _remote.refuse(accountId, signature, piece);
    return unit;
  });

  @override
  Future<Either<Failure, Set<String>>> refusedPieces(String accountId) =>
      _guard('refusedPieces', () => _remote.refusedPieces(accountId));

  @override
  Future<Either<Failure, DayClaim>> claim(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
    required Day? proposal,
    required Map<String, DateTime?> suggested,
    required String device,
    String? replacing,
  }) => _guard(
    'claim',
    () => _remote.claim(
      accountId,
      Day.keyFor(date, occasion),
      proposal: proposal,
      seen: proposal == null
          ? (known: false, lastAt: null)
          : (
              known: suggested.containsKey(proposal.signature),
              lastAt: suggested[proposal.signature],
            ),
      device: device,
      now: clock.now(),
      replacing: replacing,
    ),
  );

  @override
  Future<Either<Failure, bool>> progress(
    String accountId,
    Day day, {
    required int piece,
    required int pieces,
    required String device,
  }) => _guard(
    'progress',
    () => _remote.change(
      accountId,
      day.key,
      device: device,
      change: (current) => current.progressing(piece, pieces),
    ),
  );

  @override
  Future<Either<Failure, String?>> finish(
    String accountId,
    Day day,
    List<int> picture, {
    required String device,
  }) => _guard('finish', limit: pictureTimeLimit, () async {
    final extension = DayModel.extensionOf(picture);
    final name = '${day.key}.$extension';
    final file = await _phone.keep(accountId, name, picture);
    final path = picturePath(accountId, name);
    await _pictures.upload(
      path,
      picture,
      contentType: DayModel.contentType(extension),
    );
    final made = await _remote.change(
      accountId,
      day.key,
      device: device,
      change: (current) => current.readyAt(path),
    );
    return made ? file : null;
  });

  @override
  Future<Either<Failure, bool>> fail(
    String accountId,
    Day day,
    TryOnProblem problem, {
    required String device,
  }) => _guard(
    'fail',
    () => _remote.change(
      accountId,
      day.key,
      device: device,
      change: (current) => current.failedWith(problem),
    ),
  );

  @override
  Future<Either<Failure, String>> picture(String accountId, Day day) =>
      _guard('picture', limit: pictureTimeLimit, () async {
        final path = day.picturePath;
        if (path == null) {
          throw ServerException(
            StateError('The day has no picture'),
            StackTrace.current,
          );
        }
        final name = p.basename(path);
        return _phone.kept(accountId, name) ??
            await _phone.keep(accountId, name, await _pictures.download(path));
      });

  @override
  Future<Either<Failure, Unit>> forgetPictures(String accountId) =>
      _guard('forgetPictures', () async {
        await _phone.forget(accountId);
        return unit;
      });

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
    } on CacheException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, Object error, StackTrace? stackTrace) =>
      _logger.logError(
        callerClass: 'DayRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
