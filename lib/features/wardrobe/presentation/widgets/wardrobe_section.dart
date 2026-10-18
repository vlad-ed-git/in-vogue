import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/wardrobe_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/wardrobe_text.dart';

/// My Wardrobe: the outfits the person owns in a grid, two a row, newest
/// first; a tile opens the outfit's details. Add an outfit opens
/// [onAddOutfit].
class WardrobeSection extends StatelessWidget {
  const WardrobeSection({
    required this.onAddOutfit,
    this.imageFor = networkImage,
    super.key,
  });

  final VoidCallback onAddOutfit;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// A photo from the web, cached on the phone.
  static ImageProvider networkImage(String url) =>
      CachedNetworkImageProvider(url);

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocBuilder<WardrobeBloc, WardrobeState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(l10n.wardrobeTitle),
          if (state.status == WardrobeStatus.loading)
            const RunningRule.content()
          else if (state.outfits.isEmpty && state.failure == null)
            Text(
              l10n.wardrobeEmpty,
              style: InVogueType.body.copyWith(color: InVogueColors.graphite),
            ),
          if (state.failure case final failure?) ...[
            Notice(
              icon: InVogueIcons.warning,
              alert: true,
              message: failure.uiFriendlyMessage(context),
            ),
            const SizedBox(height: InVogueSpace.s4),
          ],
          if (state.outfits.isNotEmpty) _grid(context, state.outfits),
          const SizedBox(height: InVogueSpace.s4),
          InVogueButton.secondary(
            label: l10n.addOutfit,
            icon: InVogueIcons.plus,
            onPressed: onAddOutfit,
          ),
        ],
      ),
    );
  }

  /// An outfit's photo: the phone's copy, else the account's.
  ImageProvider _photo(WardrobeOutfit outfit) => switch (outfit.photoPath) {
    final path? => FileImage(File(path)),
    null => imageFor(outfit.photoUrl),
  };

  Widget _grid(BuildContext context, List<WardrobeOutfit> outfits) => Column(
    children: [
      for (var row = 0; row < outfits.length; row += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: InVogueSpace.s6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _tile(context, outfits[row])),
              const SizedBox(width: InVogueLayout.gutter),
              Expanded(
                child: row + 1 < outfits.length
                    ? _tile(context, outfits[row + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _tile(BuildContext context, WardrobeOutfit outfit) => Pressable(
    onTap: () => showWardrobeOutfitSheet(
      context: context,
      outfit: outfit,
      photo: _photo(outfit),
    ),
    semanticLabel: outfit.details.name,
    excludeSemantics: true,
    expandTapTarget: false,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhotoSlot(image: _photo(outfit), showLoading: outfit.photoPath == null),
        const SizedBox(height: InVogueSpace.s2),
        Text(outfit.details.name, style: InVogueType.item),
      ],
    ),
  );
}

/// An outfit's details over the tabs: its photo, colour, weather and
/// occasions, and a way to remove it, which asks first.
Future<void> showWardrobeOutfitSheet({
  required BuildContext context,
  required WardrobeOutfit outfit,
  required ImageProvider photo,
}) {
  final bloc = context.read<WardrobeBloc>();
  return showInVogueSheet<void>(
    context: context,
    builder: (context) {
      final l10n = context.translated;
      final details = outfit.details;
      return InVogueSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InVogueSheetHeader(title: details.name),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.5,
              child: PhotoSlot(
                image: photo,
                fit: BoxFit.contain,
                background: InVogueColors.paper,
                semanticLabel: details.name,
              ),
            ),
            const SizedBox(height: InVogueSpace.s4),
            Row(
              children: [
                Swatch(color: Color(details.colour.argb)),
                const SizedBox(width: InVogueSpace.s2),
                Text(details.colour.label(l10n), style: InVogueType.body),
              ],
            ),
            const SizedBox(height: InVogueSpace.s1),
            Text(details.weather(l10n), style: InVogueType.body),
            const SizedBox(height: InVogueSpace.s1),
            Text(details.occasionList(l10n), style: InVogueType.body),
            const SizedBox(height: InVogueSpace.s6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextLink(
                label: l10n.removeOutfit,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  if (await _confirmRemove(context, details.name)) {
                    bloc.add(WardrobeOutfitRemoved(outfit));
                    navigator.pop();
                  }
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Asks whether to remove the outfit [name]; true when the person
/// confirms.
Future<bool> _confirmRemove(BuildContext context, String name) async {
  final remove = await showInVogueSheet<bool>(
    context: context,
    builder: (context) {
      final l10n = context.translated;
      return InVogueSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InVogueSheetHeader(title: l10n.removeOutfitTitle, subtitle: name),
            InVogueButton.primary(
              label: l10n.remove,
              icon: InVogueIcons.trash,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: InVogueSpace.s3),
            InVogueButton.secondary(
              label: l10n.keep,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return remove ?? false;
}
