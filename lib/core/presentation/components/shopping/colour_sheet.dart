import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/components/feedback/in_vogue_sheet.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/foundations/swatch.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// One colour of a product.
@immutable
class PieceColour {
  const PieceColour({
    required this.name,
    required this.color,
    this.wornPhoto,
    this.flatPhoto,
  });

  final String name;
  final Color color;
  final ImageProvider? wornPhoto;
  final ImageProvider? flatPhoto;
}

/// Opens a [ColourSheet] in an [InVogueSheet].
Future<void> showColourSheet({
  required BuildContext context,
  required String pieceName,
  required List<PieceColour> colours,
  required Set<int> lovedIndexes,
  required void Function(int index, bool loved) onLoveChanged,
  int initialIndex = 0,
}) => showInVogueSheet<void>(
  context: context,
  builder: (context) => InVogueSheet(
    child: ColourSheet(
      pieceName: pieceName,
      colours: colours,
      lovedIndexes: lovedIndexes,
      onLoveChanged: onLoveChanged,
      initialIndex: initialIndex,
    ),
  ),
);

/// A product's colours: photos of the chosen one, colour swatches, and a
/// button to love the chosen colour.
class ColourSheet extends StatefulWidget {
  const ColourSheet({
    required this.pieceName,
    required this.colours,
    required this.lovedIndexes,
    required this.onLoveChanged,
    this.initialIndex = 0,
    super.key,
  }) : assert(colours.length > 0, 'a piece has at least one colour');

  final String pieceName;
  final List<PieceColour> colours;

  /// Indexes of the loved colours when the sheet opens.
  final Set<int> lovedIndexes;
  final void Function(int index, bool loved) onLoveChanged;
  final int initialIndex;

  @override
  State<ColourSheet> createState() => _ColourSheetState();
}

class _ColourSheetState extends State<ColourSheet> {
  late int _selected = widget.initialIndex;
  late final Set<int> _loved = {...widget.lovedIndexes};

  void _toggleLove() {
    final loved = !_loved.contains(_selected);
    if (loved) InVogueHaptic.light.play();
    setState(() => loved ? _loved.add(_selected) : _loved.remove(_selected));
    widget.onLoveChanged(_selected, loved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final colour = widget.colours[_selected];
    final loved = _loved.contains(_selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PhotoSlot(
                image: colour.wornPhoto,
                showLoading: true,
                semanticLabel: '${widget.pieceName}, ${colour.name}',
              ),
            ),
            const SizedBox(width: InVogueLayout.gutter),
            Expanded(
              child: PhotoSlot(image: colour.flatPhoto, showLoading: true),
            ),
          ],
        ),
        const SizedBox(height: InVogueSpace.s4),
        Text(widget.pieceName, style: InVogueType.item),
        Text(
          '${colour.name} · ${l10n.colourCount(widget.colours.length)}',
          style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
        ),
        // 28-point swatches 16 apart, each centred in a 44-point tap area
        // that reaches 8 points past them; extra colours wrap.
        LayoutBuilder(
          builder: (context, constraints) => OverflowBox(
            alignment: AlignmentDirectional.topStart,
            fit: OverflowBoxFit.deferToChild,
            maxWidth: constraints.maxWidth + 16,
            child: Transform.translate(
              offset: const Offset(-8, 0),
              child: Wrap(
                children: [
                  for (var i = 0; i < widget.colours.length; i++)
                    _SwatchButton(
                      colour: widget.colours[i],
                      selected: i == _selected,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: InVogueSpace.s3),
        InVogueButton.secondary(
          label: loved ? l10n.loved : l10n.loveThisColour,
          icon: loved ? InVogueIcons.heartFill : InVogueIcons.heart,
          iconColor: loved ? InVogueColors.signal : null,
          onPressed: _toggleLove,
        ),
      ],
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final PieceColour colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: selected ? () {} : onTap,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    haptic: selected ? InVogueHaptic.none : InVogueHaptic.selection,
    semanticLabel: colour.name,
    excludeSemantics: true,
    expandTapTarget: false,
    builder: (context, state) => SizedBox.square(
      dimension: 44,
      child: Center(
        child: Swatch(
          color: colour.color,
          size: Swatch.large,
          selected: selected,
        ),
      ),
    ),
  );
}
