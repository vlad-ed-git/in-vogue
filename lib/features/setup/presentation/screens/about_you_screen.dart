import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/photos/presentation/widgets/photo_notices.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';

/// Setup step 5: the name In Vogue uses, then an optional face photo for
/// makeup, kept as soon as it is chosen.
class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({required this.onBack, required this.onDone, super.key});

  final VoidCallback onBack;

  /// Called once the name is saved.
  final VoidCallback onDone;

  /// A catalogue close-up that shows what a good face photo looks like.
  static const example = AssetImage('assets/images/example_face.jpg');

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<ProfileBloc>().state.name)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() => context.read<ProfileBloc>().add(ProfileNameSaved(_name.text));

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              previous.status == ProfileStatus.loading &&
              current.status == ProfileStatus.ready,
          listener: (context, state) {
            if (_name.text.isEmpty) _name.text = state.name;
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (previous, current) =>
              previous.status != ProfileStatus.saved &&
              current.status == ProfileStatus.saved,
          listener: (context, state) => widget.onDone(),
        ),
        BlocListener<PhotoBloc, PhotoState>(
          listenWhen: (previous, current) =>
              current.status == PhotoStatus.chosen &&
              !current.isKept &&
              !current.busy &&
              previous != current,
          listener: (context, state) =>
              context.read<PhotoBloc>().add(const PhotoConfirmed()),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: PageMargin(
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BackBar(
                      onBack: widget.onBack,
                      step: SetupStep.profile.folio,
                      total: SetupStepFolio.total,
                    ),
                    const SizedBox(height: InVogueSpace.s3),
                    ScreenTitle(l10n.aboutYouTitle),
                    const SizedBox(height: InVogueSpace.s6),
                    InVogueTextField(
                      label: l10n.yourName,
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    SectionHeading(l10n.facePhotoTitle),
                    Text(
                      l10n.facePhotoLine,
                      style: InVogueType.body.copyWith(
                        color: InVogueColors.graphite,
                      ),
                    ),
                    const SizedBox(height: InVogueSpace.s6),
                    BlocBuilder<PhotoBloc, PhotoState>(
                      builder: (context, face) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PhotoPicker(
                            kind: PhotoKind.face,
                            example: AboutYouScreen.example,
                            chosen: face.path == null
                                ? null
                                : FileImage(File(face.path!)),
                            optional: true,
                            onChoose: () => context.read<PhotoBloc>().add(
                              const PhotoChooseRequested(),
                            ),
                            busy: face.busy,
                          ),
                          PhotoNotices(face),
                        ],
                      ),
                    ),
                    if (profile.failure != null) ...[
                      const SizedBox(height: InVogueSpace.s6),
                      Notice(
                        icon: InVogueIcons.warning,
                        alert: true,
                        message: profile.failure!.uiFriendlyMessage(context),
                      ),
                    ],
                    const SizedBox(height: InVogueSpace.s8),
                    InVogueButton.primary(
                      label: l10n.continueAction,
                      onPressed: _name.text.trim().isEmpty ? null : _save,
                      busy: profile.status == ProfileStatus.saving,
                    ),
                    const SizedBox(height: InVogueSpace.s6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
