import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/components/actions/text_link.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/foundations/photo_slot.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

enum _Mode { ready, preparing, locked }

/// A row of 4:5 outfit tiles; three per row, two at large text sizes.
class OutfitTiles extends StatelessWidget {
  /// Selectable tiles; the selected one is outlined and checked.
  const OutfitTiles({
    required this.outfits,
    required this.selectedIndex,
    required this.onSelected,
    this.note,
    super.key,
  }) : _mode = _Mode.ready,
       onGoPro = null,
       placeholders = 0;

  /// Empty Rose tiles with a waiting line.
  const OutfitTiles.preparing({this.placeholders = 3, super.key})
    : _mode = _Mode.preparing,
      outfits = const [],
      selectedIndex = -1,
      onSelected = null,
      onGoPro = null,
      note = null;

  /// Faded, locked tiles with a Go Pro line.
  const OutfitTiles.locked({
    required this.outfits,
    required this.onGoPro,
    super.key,
  }) : _mode = _Mode.locked,
       selectedIndex = -1,
       onSelected = null,
       note = null,
       placeholders = 0;

  final List<ImageProvider> outfits;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  /// Line shown under the tiles.
  final String? note;
  final VoidCallback? onGoPro;

  /// Number of empty tiles in [OutfitTiles.preparing].
  final int placeholders;
  final _Mode _mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final columns = context.isLargeText ? 2 : 3;
    final count = _mode == _Mode.preparing ? placeholders : outfits.length;
    final line = switch (_mode) {
      _Mode.ready => note == null ? null : Text(note!, style: _lineStyle),
      _Mode.preparing => Text(l10n.otherOutfitsPreparing, style: _lineStyle),
      _Mode.locked => Text.rich(
        TextSpan(
          style: _lineStyle,
          children: [
            TextSpan(text: '${l10n.otherOutfitsLocked} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: TextLink(label: l10n.goPro, onTap: onGoPro),
            ),
          ],
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                (constraints.maxWidth - InVogueLayout.gutter * (columns - 1)) /
                columns;
            return Wrap(
              spacing: InVogueLayout.gutter,
              runSpacing: InVogueLayout.gutter,
              children: [
                for (var i = 0; i < count; i++)
                  SizedBox(width: width, child: _tile(context, i, count)),
              ],
            );
          },
        ),
        if (line != null) ...[const SizedBox(height: InVogueSpace.s3), line],
      ],
    );
  }

  static final _lineStyle = InVogueType.meta.copyWith(
    color: InVogueColors.graphite,
  );

  Widget _tile(BuildContext context, int index, int count) {
    final l10n = context.translated;
    switch (_mode) {
      case _Mode.preparing:
        return const PhotoSlot();
      case _Mode.locked:
        return PhotoSlot(
          image: outfits[index],
          opacity: InVogueLayout.opacityLocked,
          overlay: LockOverlay(semanticLabel: l10n.lockedSpoken),
        );
      case _Mode.ready:
        final selected = index == selectedIndex;
        return Pressable(
          onTap: selected ? () {} : () => onSelected?.call(index),
          selected: selected,
          haptic: selected ? InVogueHaptic.none : InVogueHaptic.selection,
          semanticLabel: selected
              ? l10n.outfitTileShownSpoken(index + 1, count)
              : l10n.outfitTileSpoken(index + 1, count),
          excludeSemantics: true,
          builder: (context, state) => CustomPaint(
            foregroundPainter: selected ? const _SelectedOutline() : null,
            child: PhotoSlot(
              image: outfits[index],
              overlay: selected ? const CheckBadgeOverlay() : null,
            ),
          ),
        );
    }
  }
}

/// A 2-point ink outline drawn 3 points outside the tile.
class _SelectedOutline extends CustomPainter {
  const _SelectedOutline();

  static const _offset = 3.0;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    (Offset.zero & size).inflate(_offset + InVogueLayout.strokeSelect / 2),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = InVogueLayout.strokeSelect
      ..color = InVogueColors.ink,
  );

  @override
  bool shouldRepaint(_SelectedOutline oldDelegate) => false;
}
