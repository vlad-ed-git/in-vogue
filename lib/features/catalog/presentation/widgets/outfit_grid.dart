import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';

/// [outfits] as tiles, two a row, each loved through the [PicksBloc] above
/// it; a tile opens the outfit's pieces.
class SliverOutfitGrid extends StatelessWidget {
  const SliverOutfitGrid({
    required this.outfits,
    required this.picks,
    required this.imageFor,
    required this.onOpen,
    super.key,
  });

  final List<CatalogOutfit> outfits;

  /// Ids of the loved outfits.
  final Set<String> picks;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;
  final ValueChanged<CatalogOutfit> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = (outfits.length / 2).ceil();
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
      sliver: SliverList.builder(
        itemCount: rows,
        itemBuilder: (context, index) {
          final row = outfits.skip(index * 2).take(2).toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: InVogueSpace.s6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _tile(context, row.first)),
                const SizedBox(width: InVogueLayout.gutter),
                Expanded(
                  child: row.length > 1
                      ? _tile(context, row.last)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, CatalogOutfit outfit) => ProductTile(
    photo: imageFor(outfit.imageUrl),
    name: outfit.name,
    colours: [for (final piece in outfit.pieces) Color(piece.hex)],
    loved: picks.contains(outfit.id),
    onLoveChanged: (loved) =>
        context.read<PicksBloc>().add(PickToggled(outfit.id, loved: loved)),
    onTap: () => onOpen(outfit),
  );
}
