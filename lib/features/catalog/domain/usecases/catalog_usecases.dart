import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// The onboarding sample, in catalog order.
class GetSampleOutfits implements UseCase<List<CatalogOutfit>, NoParams> {
  const GetSampleOutfits(this._repository);
  final OutfitCatalogRepository _repository;

  @override
  Future<Either<Failure, List<CatalogOutfit>>> call(NoParams params) =>
      _repository.sample();
}

/// Which outfits the catalog shows: all of them, those for one weather, or
/// those good in rain.
class CatalogFilter extends Equatable {
  const CatalogFilter.all() : weather = null, rain = false;
  const CatalogFilter.weather(WarmthBand this.weather) : rain = false;
  const CatalogFilter.rain() : weather = null, rain = true;

  final WarmthBand? weather;
  final bool rain;

  bool matches(CatalogOutfit outfit) => rain
      ? outfit.rain == RainFit.good
      : weather == null || outfit.weathers.contains(weather);

  @override
  List<Object?> get props => [weather, rain];
}

class CatalogPageParams extends Equatable {
  const CatalogPageParams({
    this.filter = const CatalogFilter.all(),
    this.offset = 0,
    this.limit = pageSize,
  });

  /// Outfits on a page.
  static const pageSize = 20;

  final CatalogFilter filter;
  final int offset;
  final int limit;

  @override
  List<Object?> get props => [filter, offset, limit];
}

/// A page of the catalog, and whether more follow.
class CatalogPage extends Equatable {
  const CatalogPage({required this.outfits, required this.hasMore});

  final List<CatalogOutfit> outfits;
  final bool hasMore;

  @override
  List<Object?> get props => [outfits, hasMore];
}

/// One page of the outfits that pass the filter, in catalog order.
class GetCatalogPage implements UseCase<CatalogPage, CatalogPageParams> {
  const GetCatalogPage(this._repository);
  final OutfitCatalogRepository _repository;

  @override
  Future<Either<Failure, CatalogPage>> call(CatalogPageParams params) async {
    final outfits = await _repository.outfits();
    return outfits.map((outfits) {
      final shown = outfits.where(params.filter.matches).toList();
      final end = (params.offset + params.limit).clamp(0, shown.length);
      return CatalogPage(
        outfits: params.offset >= shown.length
            ? const []
            : shown.sublist(params.offset, end),
        hasMore: end < shown.length,
      );
    });
  }
}

/// The outfits with the given ids, in that order. Ids the catalog no
/// longer has are left out.
class GetOutfits implements UseCase<List<CatalogOutfit>, List<String>> {
  const GetOutfits(this._repository);
  final OutfitCatalogRepository _repository;

  @override
  Future<Either<Failure, List<CatalogOutfit>>> call(List<String> ids) async {
    final outfits = await _repository.outfits();
    return outfits.map((outfits) {
      final byId = {for (final outfit in outfits) outfit.id: outfit};
      return [for (final id in ids) ?byId[id]];
    });
  }
}
