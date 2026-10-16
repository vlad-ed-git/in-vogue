import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// The pieces worn in a feels-like band, or every piece when the band is
/// null, the categories taken in turn so a short look shows a bit of
/// everything.
class GetPiecesForWeather implements UseCase<List<Piece>, WarmthBand?> {
  const GetPiecesForWeather(this._repository);
  final CatalogRepository _repository;

  @override
  Future<Either<Failure, List<Piece>>> call(WarmthBand? band) async {
    final pieces = await _repository.pieces();
    return pieces.map((pieces) {
      final queues = {
        for (final category in PieceCategory.values)
          category: [
            for (final piece in pieces)
              if (piece.category == category &&
                  (band == null || piece.bands.contains(band)))
                piece,
          ],
      };
      final mixed = <Piece>[];
      for (var round = 0; ; round++) {
        final taken = [
          for (final queue in queues.values)
            if (round < queue.length) queue[round],
        ];
        if (taken.isEmpty) return mixed;
        mixed.addAll(taken);
      }
    });
  }
}
