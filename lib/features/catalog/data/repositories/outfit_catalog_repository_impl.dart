import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_remote_data_source.dart';
import 'package:in_vogue/features/catalog/data/models/catalog_outfit_model.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';

/// Answers from the catalog's copy on the phone, which is fetched again
/// only when the catalog's version changes. The version is read once a run;
/// while it can't be read, the copy kept is used.
class OutfitCatalogRepositoryImpl implements OutfitCatalogRepository {
  OutfitCatalogRepositoryImpl({
    required this._remote,
    required this._local,
    required this._logMessages,
  });

  final OutfitCatalogRemoteDataSource _remote;
  final OutfitCatalogLocalDataSource _local;
  final LogMessages _logMessages;

  int? _version;
  ({int version, bool whole, List<CatalogOutfit> outfits})? _copy;
  bool _copyRead = false;
  Future<void> _turn = Future.value();

  @override
  Future<Either<Failure, List<CatalogOutfit>>> sample() async {
    final outfits = await _inTurn(() => _load(whole: false));
    return outfits.map(
      (outfits) => [
        for (final outfit in outfits)
          if (outfit.sample) outfit,
      ],
    );
  }

  @override
  Future<Either<Failure, List<CatalogOutfit>>> outfits() =>
      _inTurn(() => _load(whole: true));

  /// Runs loads one at a time, so two screens never fetch the same catalog.
  Future<T> _inTurn<T>(Future<T> Function() load) {
    final result = _turn.then((_) => load());
    _turn = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<Either<Failure, List<CatalogOutfit>>> _load({
    required bool whole,
  }) async {
    final kept = await _kept();
    bool enough(int version) =>
        kept != null && kept.version == version && (kept.whole || !whole);
    Failure? unreachable;
    if (_version == null) {
      try {
        _version = await _remote.version();
      } on NetworkException {
        unreachable = const NetworkFailure();
      } on ServerException catch (error) {
        _log('version', error.cause, error.stackTrace);
        unreachable = const ServerFailure();
      }
    }
    final version = _version;
    if (version == null) {
      return kept != null && (kept.whole || !whole)
          ? Right(kept.outfits)
          : Left(unreachable!);
    }
    if (enough(version)) return Right(kept!.outfits);
    try {
      final documents = whole
          ? await _remote.outfits()
          : await _remote.sample();
      final outfits = _read(documents);
      _copy = (version: version, whole: whole, outfits: outfits);
      try {
        await _local.save((version: version, whole: whole, outfits: documents));
      } on CacheException catch (error) {
        _log('save', error.cause, error.stackTrace);
      }
      return Right(outfits);
    } on NetworkException {
      return kept != null && (kept.whole || !whole)
          ? Right(kept.outfits)
          : const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log('fetch', error.cause, error.stackTrace);
      return const Left(ServerFailure());
    }
  }

  /// The copy in memory, or else the one kept on the phone.
  Future<({int version, bool whole, List<CatalogOutfit> outfits})?>
  _kept() async {
    if (_copy != null || _copyRead) return _copy;
    _copyRead = true;
    final saved = await _local.read();
    if (saved == null) return null;
    return _copy = (
      version: saved.version,
      whole: saved.whole,
      outfits: _read(saved.outfits),
    );
  }

  /// The outfits in catalog order; a document that can't be read is left
  /// out and reported.
  List<CatalogOutfit> _read(List<Map<String, Object?>> documents) {
    final outfits = <CatalogOutfit>[];
    for (final document in documents) {
      try {
        outfits.add(CatalogOutfitModel.fromJson(document));
      } on FormatException catch (error, stack) {
        _log('read', error, stack);
      }
    }
    return outfits..sort((a, b) => a.order.compareTo(b.order));
  }

  void _log(String method, Object error, StackTrace stack) =>
      _logMessages.logError(
        callerClass: 'OutfitCatalogRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stack,
      );
}
