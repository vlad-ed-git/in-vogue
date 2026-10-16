import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/outfit_record_model.dart';
import 'package:in_vogue/features/outfits/data/models/outfits_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:path/path.dart' as p;

/// The bundled outfits, read once and kept in memory; the records and
/// pictures on the account, with a copy of each picture on the phone.
class OutfitRepositoryImpl implements OutfitRepository {
  OutfitRepositoryImpl({
    required OutfitAssetDataSource assetDataSource,
    required OutfitRemoteDataSource remoteDataSource,
    required OutfitPictureLocalDataSource pictureDataSource,
    required LogMessages logMessages,
  }) : _asset = assetDataSource,
       _remote = remoteDataSource,
       _pictures = pictureDataSource,
       _logger = logMessages;

  final OutfitAssetDataSource _asset;
  final OutfitRemoteDataSource _remote;
  final OutfitPictureLocalDataSource _pictures;
  final LogMessages _logger;

  /// How long a call to the account may take before it counts as offline.
  static const timeLimit = Duration(seconds: 30);

  Future<OutfitIndex>? _index;

  Future<OutfitIndex> _load() async {
    final loading = _index ??= _asset.index();
    try {
      return await loading;
    } on FormatException {
      // Read again next time.
      _index = null;
      rethrow;
    }
  }

  @override
  Future<Either<Failure, List<Outfit>>> outfitsFor(String cell) =>
      _guard('outfitsFor', () async {
        final index = await _load();
        return [...?index.cells[cell]?.map((id) => index.outfits[id]).nonNulls];
      });

  @override
  Future<Either<Failure, Outfit?>> outfit(String id) =>
      _guard('outfit', () async => (await _load()).outfits[id]);

  @override
  Future<Either<Failure, Set<String>>> shownSignatures(String accountId) =>
      _guard('shownSignatures', () => _remote.signatures(accountId));

  @override
  Future<Either<Failure, DayOutfit?>> dayOutfit(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  }) => _guard('dayOutfit', () async {
    final records = [
      for (final record in await _remote.recordsFor(
        accountId,
        TryOnJob.dateKey(date),
      ))
        if (record.occasion == occasion) record,
    ];
    if (records.isEmpty) return null;
    // The latest; one still being written has no time yet.
    final record = records.reduce(
      (a, b) =>
          b.createdAt == null ||
              (a.createdAt != null && b.createdAt!.isAfter(a.createdAt!))
          ? b
          : a,
    );
    final name = p.basename(record.imagePath);
    final picture =
        _pictures.kept(accountId, name) ??
        await _pictures.keep(
          accountId,
          name,
          await _remote.download(record.imagePath),
        );
    final outfit =
        (await _load()).outfits[record.outfitId] ??
        Outfit(
          id: record.outfitId,
          signature: record.signature,
          pieces: record.pieces,
          passes: const [],
        );
    return DayOutfit(
      outfit: outfit,
      date: record.date,
      occasion: record.occasion,
      cell: record.cell,
      picture: picture,
    );
  });

  @override
  Future<Either<Failure, DayOutfit>> record(
    String accountId, {
    required Outfit outfit,
    required String cell,
    required DateTime date,
    required Occasion occasion,
    required List<int> picture,
  }) => _guard('record', () async {
    final extension = OutfitRecordModel.extensionOf(picture);
    final imagePath = OutfitRecordModel.imagePath(
      accountId,
      outfit.signature,
      extension,
    );
    final file = await _pictures.keep(
      accountId,
      p.basename(imagePath),
      picture,
    );
    await _remote.upload(
      imagePath,
      picture,
      contentType: OutfitRecordModel.contentType(extension),
    );
    await _remote.write(accountId, (
      signature: outfit.signature,
      outfitId: outfit.id,
      pieces: outfit.pieces,
      cell: cell,
      date: date,
      occasion: occasion,
      imagePath: imagePath,
      createdAt: null,
    ));
    return DayOutfit(
      outfit: outfit,
      date: date,
      occasion: occasion,
      cell: cell,
      picture: file,
    );
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
    } on CacheException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(CacheFailure());
    } on FormatException catch (error, stack) {
      _log(method, error, stack);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'OutfitRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
