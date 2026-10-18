import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/presentation/bloc/makeup_bloc.dart';
import 'package:in_vogue/features/makeup/presentation/makeup_text.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/photos/presentation/widgets/photo_notices.dart';

/// The Makeup tab: the look for the outfit of the day shown, with its
/// steps on the person's own face; or the face photo, or the way to add
/// one, with the last look below.
///
/// Its [PhotoBloc] is the face photo's: a photo chosen here is kept at
/// once, and a face photo newly kept, here or elsewhere, asks for the
/// look.
class MakeupScreen extends StatelessWidget {
  const MakeupScreen({required this.onPicture, super.key});

  /// Shows [picture] full size; [label] says what it shows.
  final void Function(String picture, String label) onPicture;

  static const example = AssetImage('assets/images/example_face.jpg');

  /// Faces sit in the upper part of their square.
  static const _faceAlignment = Alignment(0, -0.4);

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
            context.read<MakeupBloc>().add(const MakeupRequested()),
      ),
    ],
    child: BlocBuilder<MakeupBloc, MakeupState>(
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
                    child: ScreenTitle(
                      context.translated.makeupFor(state.day.day.name),
                    ),
                  ),
                  if (state.day.outfit?.occasion ?? state.day.occasion
                      case final occasion?)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: InVogueSpace.s2,
                        bottom: InVogueSpace.s1,
                      ),
                      child: OccasionLine(occasion: occasion),
                    ),
                  ..._body(context, state, photo),
                  const SizedBox(height: InVogueSpace.s10),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _body(
    BuildContext context,
    MakeupState state,
    PhotoState photo,
  ) {
    if (state.status == MakeupStatus.loading) {
      return const [RunningRule.content()];
    }
    if (state.making case final steps?) return _making(context, steps);
    if (state.look case final look?) return _look(context, look);
    final last = state.lastLook;
    return [
      ..._ready(context, state, photo),
      if (last != null) ...[
        SectionHeading(context.translated.yourLastLook),
        Text(
          '${last.occasion.label(context.translated)} · '
          '${InVogueFormat.shortDate(last.date, Localizations.localeOf(context).languageCode)}',
          style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
        ),
        const SizedBox(height: InVogueSpace.s3),
        ..._look(context, last),
      ],
    ];
  }

  /// The face photo and the way to get the look for the outfit shown.
  List<Widget> _ready(
    BuildContext context,
    MakeupState state,
    PhotoState photo,
  ) {
    final l10n = context.translated;
    final day = state.day;
    final path = photo.path;
    return [
      if (day.outfitPending)
        _gap(
          Notice(
            icon: InVogueIcons.image,
            message: l10n.makeupWaitsForOutfit,
            busy: true,
          ),
        )
      else if (day.outfit == null)
        _gap(
          Notice(
            icon: InVogueIcons.image,
            message: l10n.makeupNeedsOutfit(day.day.name),
          ),
        ),
      if (photo.isKept && path != null)
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s4),
          child: PhotoSlot(
            image: FileImage(File(path)),
            aspectRatio: 1,
            alignment: _faceAlignment,
            semanticLabel: l10n.facePhotoSpoken,
          ),
        )
      else ...[
        SectionHeading(
          l10n.facePhotoTitle,
          padding: const EdgeInsets.only(
            top: InVogueSpace.s6,
            bottom: InVogueSpace.s2,
          ),
        ),
        Text(l10n.makeupFacePhotoLine, style: InVogueType.body),
        const SizedBox(height: InVogueSpace.s4),
        PhotoPicker(
          kind: PhotoKind.face,
          example: example,
          chosen: path == null ? null : FileImage(File(path)),
          optional: true,
          onChoose: () =>
              context.read<PhotoBloc>().add(const PhotoChooseRequested()),
          busy: photo.busy,
        ),
      ],
      PhotoNotices(photo),
      if (state.failure case final failure?) _gap(_failed(context, failure)),
    ];
  }

  Widget _failed(BuildContext context, Failure failure) {
    final l10n = context.translated;
    final action = switch (failure) {
      MakeupFailure(problem: MakeupProblem.photo) => InVogueButton.secondary(
        label: l10n.chooseDifferentPhoto,
        icon: InVogueIcons.image,
        onRose: true,
        onPressed: () =>
            context.read<PhotoBloc>().add(const PhotoChooseRequested()),
      ),
      MakeupFailure(
        problem: MakeupProblem.noCredit || MakeupProblem.unavailable,
      ) =>
        null,
      _ => InVogueButton.secondary(
        label: l10n.retry,
        icon: InVogueIcons.retry,
        onRose: true,
        onPressed: () =>
            context.read<MakeupBloc>().add(const MakeupRequested()),
      ),
    };
    return Notice(
      icon: InVogueIcons.warning,
      alert: true,
      message: failure.uiFriendlyMessage(context),
      action: action,
    );
  }

  /// The steps of a look being made, each filling in when it is ready.
  List<Widget> _making(BuildContext context, List<LookStep> steps) => [
    Padding(
      padding: const EdgeInsets.only(
        top: InVogueSpace.s2,
        bottom: InVogueSpace.s4,
      ),
      child: Text(
        context.translated.makeupStepsArriving,
        style: InVogueType.body.copyWith(color: InVogueColors.graphite),
      ),
    ),
    // The steps show once the recipe is known.
    if (steps.isEmpty) const RunningRule.content(),
    ..._steps(context, steps),
  ];

  /// A made look: before and after, why it suits the outfit, and its steps.
  List<Widget> _look(BuildContext context, MakeupLook look) {
    final l10n = context.translated;
    return [
      const SizedBox(height: InVogueSpace.s2),
      BeforeAfter(
        before: FileImage(File(look.before)),
        after: FileImage(File(look.after)),
        sentence: look.sentence(l10n),
        aspectRatio: 1,
      ),
      if (!look.matched)
        _gap(
          Notice(icon: InVogueIcons.image, message: l10n.makeupShadesNeutral),
        ),
      SectionHeading(stepCount(l10n, look.steps.length)),
      ..._steps(context, look.steps),
    ];
  }

  List<Widget> _steps(BuildContext context, List<LookStep> steps) {
    // Steps are made in order: the first without a picture is being made.
    final working = steps.indexWhere((step) => step.picture == null);
    return [
      for (final (index, step) in steps.indexed)
        MakeupStep(
          working: index == working,
          number: index + 1,
          title: step.title.of(context.language),
          instructions: step.howTo.of(context.language),
          product: step.productLine(context.language),
          picture: step.picture == null ? null : FileImage(File(step.picture!)),
          onPictureTap: step.picture == null
              ? null
              : () => onPicture(
                  step.picture!,
                  context.translated.faceAfterStep(index + 1),
                ),
        ),
    ];
  }

  static Widget _gap(Widget child) => Padding(
    padding: const EdgeInsets.only(top: InVogueSpace.s4),
    child: child,
  );
}
