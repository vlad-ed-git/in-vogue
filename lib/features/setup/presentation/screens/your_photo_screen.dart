import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/photos/presentation/widgets/photo_notices.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';

/// Setup step 2: the full-body photo every outfit is made from, chosen from
/// Photos or Gallery and trusted as the person's own.
class YourPhotoScreen extends StatelessWidget {
  const YourPhotoScreen({
    required this.onBack,
    required this.onDone,
    super.key,
  });

  final VoidCallback onBack;

  /// Called once the photo is kept.
  final VoidCallback onDone;

  /// A catalogue photo that shows what a good photo looks like.
  static const example = AssetImage('assets/images/example_body.jpg');

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocListener<PhotoBloc, PhotoState>(
      listenWhen: (previous, current) =>
          previous.status != PhotoStatus.confirmed &&
          current.status == PhotoStatus.confirmed,
      listener: (context, state) => onDone(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: PageMargin(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BackBar(
                    onBack: onBack,
                    step: SetupStep.photo.folio,
                    total: SetupStepFolio.total,
                  ),
                  const SizedBox(height: InVogueSpace.s3),
                  ScreenTitle(l10n.addPhotoOfYou),
                  const SizedBox(height: InVogueSpace.s3),
                  Text(
                    l10n.bodyPhotoWhy,
                    style: InVogueType.body.copyWith(
                      color: InVogueColors.graphite,
                    ),
                  ),
                  const SizedBox(height: InVogueSpace.s6),
                  BlocBuilder<PhotoBloc, PhotoState>(
                    builder: (context, state) => _picker(context, state),
                  ),
                  const SizedBox(height: InVogueSpace.s6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _picker(BuildContext context, PhotoState state) {
    final bloc = context.read<PhotoBloc>();
    final path = state.path;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PhotoPicker(
          kind: PhotoKind.body,
          example: example,
          chosen: path == null ? null : FileImage(File(path)),
          onChoose: () => bloc.add(const PhotoChooseRequested()),
          onContinue: state.busy
              ? null
              : () => bloc.add(const PhotoConfirmed()),
        ),
        PhotoNotices(state),
      ],
    );
  }
}
