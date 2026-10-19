import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';

/// A colourway of a piece, to buy.
class ShopPiece extends Equatable {
  const ShopPiece({required this.piece, required this.colourway});

  final Piece piece;
  final Colourway colourway;

  @override
  List<Object?> get props => [piece, colourway];
}

/// The pieces to buy and the partner that sells them.
class ShopPieces extends Equatable {
  const ShopPieces({required this.brand, required this.pieces});

  final String brand;
  final List<ShopPiece> pieces;

  @override
  List<Object?> get props => [brand, pieces];
}

/// The colourways with the given ids, in that order, with their pieces.
/// Ids the collection no longer has are left out.
class GetShopPieces implements UseCase<ShopPieces, List<String>> {
  const GetShopPieces(this._repository);
  final CatalogRepository _repository;

  @override
  Future<Either<Failure, ShopPieces>> call(List<String> colourwayIds) async {
    final pieces = await _repository.pieces();
    if (pieces case Left(value: final failure)) return Left(failure);
    final brand = await _repository.brand();
    if (brand case Left(value: final failure)) return Left(failure);
    final byId = {
      for (final piece in pieces.getOrElse(() => const []))
        for (final colourway in piece.colourways)
          colourway.id: ShopPiece(piece: piece, colourway: colourway),
    };
    return Right(
      ShopPieces(
        brand: brand.getOrElse(() => ''),
        pieces: [for (final id in colourwayIds) ?byId[id]],
      ),
    );
  }
}

/// The pieces of a catalog outfit to buy, outer layer first, each in the
/// outfit's colour, with the shop's flat-lay photo and material where the
/// bundled collection has them.
class GetOutfitShop implements UseCase<ShopPieces, CatalogOutfit> {
  const GetOutfitShop(this._repository);
  final CatalogRepository _repository;

  @override
  Future<Either<Failure, ShopPieces>> call(CatalogOutfit outfit) async {
    final brand = await _repository.brand();
    if (brand case Left(value: final failure)) return Left(failure);
    final pieces = await _repository.pieces();
    final bundled = {
      for (final piece in pieces.getOrElse(() => const []))
        for (final colourway in piece.colourways) colourway.id: colourway,
    };
    return Right(
      ShopPieces(
        brand: brand.getOrElse(() => ''),
        pieces: [
          for (final piece in outfit.outsideIn)
            ShopPiece(
              piece: Piece(
                id: piece.style,
                name: piece.name,
                colourways: const [],
              ),
              colourway: Colourway(
                id: piece.colourway,
                name: piece.colour,
                hex: piece.hex,
                photoUrl: piece.photoUrl,
                productUrl: piece.productUrl,
                flatUrl: bundled[piece.colourway]?.flatUrl,
                material: bundled[piece.colourway]?.material,
              ),
            ),
        ],
      ),
    );
  }
}
