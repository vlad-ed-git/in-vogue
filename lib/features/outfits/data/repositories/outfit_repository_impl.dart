import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/outfits_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';

/// The bundled outfits, read once and kept in memory.
class OutfitRepositoryImpl implements OutfitRepository {
  OutfitRepositoryImpl({
    required OutfitAssetDataSource assetDataSource,
    required LogMessages logMessages,
  }) : _asset = assetDataSource,
       _logger = logMessages;

  final OutfitAssetDataSource _asset;
  final LogMessages _logger;

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

  Future<Either<Failure, T>> _guard<T>(
    String method,
    Future<T> Function() call,
  ) async {
    try {
      return Right(await call());
    } on FormatException catch (error, stack) {
      _logger.logError(
        callerClass: 'OutfitRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stack,
      );
      return const Left(CacheFailure());
    }
  }
}
