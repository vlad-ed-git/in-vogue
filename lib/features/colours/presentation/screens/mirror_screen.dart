import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/presentation/bloc/colours_bloc.dart';
import 'package:in_vogue/features/colours/presentation/colours_text.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/photos/presentation/widgets/photo_notices.dart';
import 'package:in_vogue/features/wardrobe/presentation/widgets/wardrobe_section.dart';

/// The Mirror tab: the person's colour season, why, and the colours that
/// suit them, read from their face photo; then My Wardrobe, the outfits
/// they own. Without a face photo it asks for a selfie, kept as soon as it
/// is chosen.
///
/// Its [PhotoBloc] is the face photo's; a face photo newly kept, here or
/// in Settings, is read.
class MirrorScreen extends StatelessWidget {
  const MirrorScreen({
    required this.onAddOutfit,
    this.imageFor = WardrobeSection.networkImage,
    super.key,
  });

  /// Opens the screen that adds an outfit to the wardrobe.
  final VoidCallback onAddOutfit;

  /// The image at a URL.
  final ImageProvider Function(String url) imageFor;

  /// A catalogue close-up that shows what a good selfie looks like.
  static const example = AssetImage('assets/images/example_face.jpg');

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<PhotoBloc, PhotoState>(
        listenWhen: (previous, current) =>
            current.status == PhotoStatus.chosen &&
            !current.isKept &&
            !current.busy &&
            current.failure == null &&
            previous != current,
        listener: (context, photo) =>
            context.read<PhotoBloc>().add(const PhotoConfirmed()),
      ),
      BlocListener<PhotoBloc, PhotoState>(
        listenWhen: (previous, current) =>
            current.isKept &&
            current.path != null &&
            (!previous.isKept || previous.path != current.path),
        listener: (context, photo) =>
            context.read<ColoursBloc>().add(const ColoursShown()),
      ),
    ],
    child: BlocBuilder<ColoursBloc, ColoursState>(
      builder: (context, state) => BlocBuilder<PhotoBloc, PhotoState>(
        builder: (context, photo) => SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: PageMargin(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: InVogueSpace.s4),
                    child: ScreenTitle(context.translated.tabMirror),
                  ),
                  ..._colours(context, state, photo),
                  WardrobeSection(onAddOutfit: onAddOutfit, imageFor: imageFor),
                  const SizedBox(height: InVogueSpace.s10),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _colours(
    BuildContext context,
    ColoursState state,
    PhotoState photo,
  ) {
    final l10n = context.translated;
    return switch (state.status) {
      ColoursStatus.loading => const [RunningRule.content()],
      ColoursStatus.noPhoto => [
        SectionHeading(
          l10n.selfieTitle,
          padding: const EdgeInsets.only(
            top: InVogueSpace.s6,
            bottom: InVogueSpace.s2,
          ),
        ),
        Text(l10n.selfieLine, style: InVogueType.body),
        const SizedBox(height: InVogueSpace.s4),
        PhotoPicker(
          kind: PhotoKind.face,
          example: example,
          chosen: photo.path == null ? null : FileImage(File(photo.path!)),
          optional: true,
          onChoose: () =>
              context.read<PhotoBloc>().add(const PhotoChooseRequested()),
          busy: photo.busy,
        ),
        PhotoNotices(photo),
      ],
      ColoursStatus.reading => [
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s4),
          child: Text(
            l10n.readingColours,
            style: InVogueType.body.copyWith(color: InVogueColors.graphite),
          ),
        ),
        const RunningRule.content(),
      ],
      ColoursStatus.failed => [
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s4),
          child: _failed(context, state.failure ?? const ServerFailure()),
        ),
        PhotoNotices(photo),
      ],
      ColoursStatus.ready => _season(context, state.reading!),
    };
  }

  Widget _failed(BuildContext context, Failure failure) {
    final l10n = context.translated;
    final action = switch (failure) {
      AnalysisFailure(problem: AnalysisProblem.photo) =>
        InVogueButton.secondary(
          label: l10n.chooseDifferentPhoto,
          icon: InVogueIcons.image,
          onRose: true,
          onPressed: () =>
              context.read<PhotoBloc>().add(const PhotoChooseRequested()),
        ),
      AnalysisFailure(
        problem: AnalysisProblem.noCredit || AnalysisProblem.unavailable,
      ) =>
        null,
      _ => InVogueButton.secondary(
        label: l10n.retry,
        icon: InVogueIcons.retry,
        onRose: true,
        onPressed: () => context.read<ColoursBloc>().add(const ColoursShown()),
      ),
    };
    return Notice(
      icon: InVogueIcons.warning,
      alert: true,
      message: failure.uiFriendlyMessage(context),
      action: action,
    );
  }

  List<Widget> _season(BuildContext context, ColourReading reading) {
    final l10n = context.translated;
    return [
      const SizedBox(height: InVogueSpace.s6),
      Kicker(l10n.yourSeason),
      const SizedBox(height: InVogueSpace.s2),
      Text(reading.season.name(l10n), style: InVogueType.section),
      const SizedBox(height: InVogueSpace.s2),
      Text(reading.season.advice(l10n), style: InVogueType.body),
      const SizedBox(height: InVogueSpace.s2),
      Text(
        reading.facts(l10n),
        style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
      ),
      if (!reading.clear)
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s4),
          child: Notice(icon: InVogueIcons.image, message: l10n.coloursUnclear),
        ),
      SectionHeading(l10n.coloursSuit),
      _Swatches(reading.palette.suits),
      SectionHeading(l10n.coloursNeutrals),
      _Swatches(reading.palette.neutrals),
      SectionHeading(l10n.coloursGoEasy),
      _Swatches(reading.palette.avoid),
    ];
  }
}

/// Round swatches, six to a row across the content width.
class _Swatches extends StatelessWidget {
  const _Swatches(this.colours);

  final List<int> colours;

  static const _perRow = 6;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size =
          (constraints.maxWidth - InVogueLayout.gutter * (_perRow - 1)) /
          _perRow;
      return Wrap(
        spacing: InVogueLayout.gutter,
        runSpacing: InVogueLayout.gutter,
        children: [
          for (final colour in colours)
            Swatch(color: Color(colour), size: size),
        ],
      );
    },
  );
}
