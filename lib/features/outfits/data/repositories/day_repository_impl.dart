import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/day_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:path/path.dart' as p;

/// Days and suggestions in Firestore, which keeps a copy on the phone and
/// syncs it; pictures in Storage, with a copy of each on the phone.
///
/// Each picture made is also listed under its photo and outfit, on the
/// account and on the phone, so the same photo and outfit are tried on
/// once and a later day with them takes the picture at once.
class DayRepositoryImpl implements DayRepository {
  DayRepositoryImpl({
    required DayRemoteDataSource remoteDataSource,
    required OutfitPictureRemoteDataSource pictureRemoteDataSource,
    required OutfitPictureLocalDataSource pictureLocalDataSource,
    required this._fingerprints,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _pictures = pictureRemoteDataSource,
       _phone = pictureLocalDataSource,
       _logger = logMessages;

  final DayRemoteDataSource _remote;
  final OutfitPictureRemoteDataSource _pictures;
  final OutfitPictureLocalDataSource _phone;
  final PhotoFingerprints _fingerprints;
  final LogMessages _logger;

  /// How long a call may take before it counts as offline.
  static const timeLimit = Duration(seconds: 30);

  /// How long moving a picture to or from the account may take.
  static const pictureTimeLimit = Duration(minutes: 2);

  /// Where the picture [name] of [accountId]'s days is in Storage.
  static String picturePath(String accountId, String name) =>
      'users/$accountId/days/$name';

  /// Where the picture of the outfit [outfitId] on the photo with the
  /// fingerprint [photo] is listed.
  static String madeKey(String photo, String outfitId) =>
      '${photo.substring(0, 16)}-$outfitId';

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
  Future<Either<Failure, List<Day>>> since(String accountId, DateTime date) =>
      _guard('since', () => _remote.since(accountId, date));

  @override
  Future<Either<Failure, Map<String, DateTime?>>> suggested(
    String accountId,
    List<String> outfitIds,
  ) => _guard('suggested', () => _remote.suggested(accountId, outfitIds));

  @override
  Future<Either<Failure, Unit>> refuse(
    String accountId,
    String outfitId,
    String piece,
  ) => _guard('refuse', () async {
    await _remote.refuse(accountId, outfitId, piece);
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
              known: suggested.containsKey(proposal.outfitId),
              lastAt: suggested[proposal.outfitId],
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
    required String photo,
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
    // Listed even when another phone took the day: the try-on is paid for.
    final fingerprint = await _fingerprints.of(photo);
    final key = madeKey(fingerprint, day.outfitId);
    await _remote.keepMadePicture(
      accountId,
      key,
      photo: fingerprint,
      outfitId: day.outfitId,
      path: path,
    );
    await _phone.keepMadePicture(accountId, key, path);
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
  Future<Either<Failure, String?>> madePicture(
    String accountId, {
    required String photo,
    required String outfitId,
  }) => _guard('madePicture', () async {
    final key = madeKey(await _fingerprints.of(photo), outfitId);
    final known = _phone.madePicture(accountId, key);
    if (known != null) return known;
    final path = await _remote.madePicture(accountId, key);
    if (path != null) await _phone.keepMadePicture(accountId, key, path);
    return path;
  });

  @override
  Future<Either<Failure, String?>> reuse(
    String accountId,
    Day day,
    String picturePath, {
    required String device,
  }) => _guard('reuse', limit: pictureTimeLimit, () async {
    final made = await _remote.change(
      accountId,
      day.key,
      device: device,
      change: (current) => current.readyAt(picturePath),
    );
    return made ? _onPhone(accountId, picturePath) : null;
  });

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
        return _onPhone(accountId, path);
      });

  /// The picture at [path] on the account, on this phone: fetched when
  /// missing.
  Future<String> _onPhone(String accountId, String path) async {
    final name = p.basename(path);
    return _phone.kept(accountId, name) ??
        await _phone.keep(accountId, name, await _pictures.download(path));
  }

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
