import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/failure_message.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/presentation/setup_step_folio.dart';

/// Setup step 4: Apple or Google, nothing else. The person's photo shows
/// what they keep; outfits begin once they have an account.
class SignInScreen extends StatelessWidget {
  const SignInScreen({
    required this.onBack,
    required this.onSignedIn,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<Account> onSignedIn;

  /// Width of the photo of what is kept.
  static const double keptPhotoWidth = 196;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return BlocListener<SignInBloc, SignInState>(
      listenWhen: (previous, current) =>
          previous.status != SignInStatus.signedIn &&
          current.status == SignInStatus.signedIn,
      listener: (context, state) => onSignedIn(state.account!),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageMargin(
                child: BackBar(
                  onBack: onBack,
                  step: SetupStep.signIn.folio,
                  total: SetupStepFolio.total,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: PageMargin(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: InVogueSpace.s3),
                        ScreenTitle(l10n.signInTitle),
                        const SizedBox(height: InVogueSpace.s3),
                        Text(
                          l10n.signInLine,
                          style: InVogueType.body.copyWith(
                            color: InVogueColors.graphite,
                          ),
                        ),
                        const SizedBox(height: InVogueSpace.s6),
                        SizedBox(
                          width: keptPhotoWidth,
                          child: BlocBuilder<PhotoBloc, PhotoState>(
                            builder: (context, state) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PhotoSlot(
                                  image: state.path == null
                                      ? null
                                      : FileImage(File(state.path!)),
                                  // The person whole, never cropped.
                                  fit: BoxFit.contain,
                                  background: InVogueColors.paper,
                                  semanticLabel: l10n.yourPhoto,
                                ),
                                const SizedBox(height: InVogueSpace.s2),
                                Kicker(l10n.yourPhoto),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: InVogueSpace.s6),
                      ],
                    ),
                  ),
                ),
              ),
              PageMargin(
                child: BlocBuilder<SignInBloc, SignInState>(
                  builder: (context, state) {
                    final bloc = context.read<SignInBloc>();
                    final idle = state.status == SignInStatus.idle;
                    final failure = state.failure;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (failure != null) ...[
                          Notice(
                            icon: InVogueIcons.warning,
                            alert: true,
                            message: failure.uiFriendlyMessage(context),
                          ),
                          const SizedBox(height: InVogueSpace.s4),
                        ],
                        SignInButtons(
                          onApple: idle
                              ? () => bloc.add(
                                  const SignInRequested(SignInMethod.apple),
                                )
                              : null,
                          onGoogle: idle
                              ? () => bloc.add(
                                  const SignInRequested(SignInMethod.google),
                                )
                              : null,
                        ),
                        const SizedBox(height: InVogueSpace.s5),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
