import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/components/actions/text_link.dart';
import 'package:in_vogue/core/presentation/components/feedback/notice.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/kicker.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// The kind of photo a [PhotoPicker] asks for.
enum PhotoKind { body, face }

/// The check result of a chosen photo.
enum PhotoCheck { passed, notFullLength }

/// An example photo beside a checklist, with a button that opens the
/// system photo picker.
///
/// With a [chosen] photo that passed, it offers Continue and a link to
/// choose again; a rejected photo shows why, with a button to choose again.
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    required this.kind,
    required this.example,
    required this.onChoose,
    this.chosen,
    this.check = PhotoCheck.passed,
    this.onContinue,
    super.key,
  });

  final PhotoKind kind;
  final ImageProvider example;

  /// Opens the system photo picker.
  final VoidCallback onChoose;
  final ImageProvider? chosen;

  /// Result for [chosen]; ignored without a chosen photo.
  final PhotoCheck check;
  final VoidCallback? onContinue;

  /// Space between the photo row and the buttons.
  static const double actionsGap = InVogueSpace.s6;

  List<String> _checklist(AppLocalizations l10n) => switch (kind) {
    PhotoKind.body => [
      l10n.photoHeadToToe,
      l10n.photoStanding,
      l10n.photoGoodLight,
      l10n.photoJustYou,
    ],
    PhotoKind.face => [
      l10n.photoCloseUp,
      l10n.photoFacingForward,
      l10n.photoDaylight,
      l10n.photoHairOff,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final chooseLabel = context.isApplePlatform
        ? l10n.chooseFromPhotos
        : l10n.chooseFromGallery;
    final hasPhoto = chosen != null;
    final rejected = hasPhoto && check == PhotoCheck.notFullLength;
    final passed = hasPhoto && !rejected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhotoSlot(
                    image: chosen ?? example,
                    semanticLabel: hasPhoto
                        ? l10n.yourPhoto
                        : (kind == PhotoKind.body
                              ? l10n.exampleBodySpoken
                              : l10n.exampleFaceSpoken),
                    overlay: passed
                        ? CheckBadgeOverlay(semanticLabel: l10n.photoPasses)
                        : null,
                  ),
                  const SizedBox(height: InVogueSpace.s2),
                  Kicker(hasPhoto ? l10n.yourPhoto : l10n.example),
                ],
              ),
            ),
            const SizedBox(width: InVogueLayout.gutter),
            Expanded(
              child: rejected
                  ? Notice.notFullLength(context: context)
                  : _Checklist(items: _checklist(l10n)),
            ),
          ],
        ),
        const SizedBox(height: actionsGap),
        if (passed) ...[
          InVogueButton.primary(
            label: l10n.continueAction,
            onPressed: onContinue,
          ),
          const SizedBox(height: InVogueSpace.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextLink(label: l10n.chooseDifferentPhoto, onTap: onChoose),
          ),
        ] else
          InVogueButton.primary(
            label: rejected ? l10n.chooseAnotherPhoto : chooseLabel,
            icon: InVogueIcons.image,
            onPressed: onChoose,
          ),
        if (!hasPhoto && kind == PhotoKind.body) ...[
          const SizedBox(height: InVogueSpace.s3),
          Text(
            l10n.bodyPhotoPrivacy,
            style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
          ),
        ],
      ],
    );
  }
}

/// Hairline rows, each a check and a short phrase.
class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: InVogueColors.rule)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: InVogueColors.rule)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: InVogueLayout.strokeHairline),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 44 - InVogueLayout.strokeHairline,
                ),
                child: Row(
                  children: [
                    const InVogueIcon(InVogueIcons.check, size: 16),
                    const SizedBox(width: InVogueSpace.s2),
                    Expanded(child: Text(item, style: InVogueType.body)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: InVogueLayout.strokeHairline),
      ],
    ),
  );
}
