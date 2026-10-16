import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';

/// [pieces] as tiles, two a row, each loved through the [PicksBloc] above
/// it; a tile opens the piece's colours.
class SliverPieceGrid extends StatelessWidget {
  const SliverPieceGrid({
    required this.pieces,
    required this.picks,
    required this.imageFor,
    super.key,
  });

  final List<Piece> pieces;

  /// Ids of the loved colourways.
  final Set<String> picks;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  @override
  Widget build(BuildContext context) {
    final rows = (pieces.length / 2).ceil();
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
      sliver: SliverList.builder(
        itemCount: rows,
        itemBuilder: (context, index) {
          final row = pieces.skip(index * 2).take(2).toList();
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

  Widget _tile(BuildContext context, Piece piece) {
    final bloc = context.read<PicksBloc>();
    final loved = [
      for (final colourway in piece.colourways)
        if (picks.contains(colourway.id)) colourway,
    ];
    final shown = loved.isEmpty ? piece.colourways.first : loved.first;
    return ProductTile(
      photo: imageFor(shown.photoUrl),
      name: piece.name,
      colours: [for (final colourway in piece.colourways) Color(colourway.hex)],
      loved: loved.isNotEmpty,
      onLoveChanged: (love) {
        for (final colourway in love ? [shown] : loved) {
          bloc.add(PickToggled(colourway.id, loved: love));
        }
      },
      onTap: () => showColourSheet(
        context: context,
        pieceName: piece.name,
        colours: [
          for (final colourway in piece.colourways)
            PieceColour(
              name: colourway.name,
              color: Color(colourway.hex),
              wornPhoto: imageFor(colourway.photoUrl),
              flatPhoto: colourway.flatUrl == null
                  ? null
                  : imageFor(colourway.flatUrl!),
            ),
        ],
        lovedIndexes: {
          for (var i = 0; i < piece.colourways.length; i++)
            if (picks.contains(piece.colourways[i].id)) i,
        },
        onLoveChanged: (index, love) =>
            bloc.add(PickToggled(piece.colourways[index].id, loved: love)),
      ),
    );
  }
}
