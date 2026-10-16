import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/data/data_sources/catalog_asset_data_source.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';

/// Reads the bundled catalog once and keeps it in memory.
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._asset);
  final CatalogAssetDataSource _asset;
  List<Piece>? _pieces;

  @override
  Future<Either<Failure, List<Piece>>> pieces() async {
    try {
      return Right(_pieces ??= await _asset.pieces());
    } on FormatException {
      return const Left(CacheFailure());
    }
  }
}
