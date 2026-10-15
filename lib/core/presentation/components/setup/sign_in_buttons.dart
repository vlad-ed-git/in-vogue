import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';

/// Stacks the platforms' own sign-in buttons, full width and 52 points tall,
/// 12 apart: Apple first on Apple platforms, Google first elsewhere.
class SignInButtons extends StatelessWidget {
  const SignInButtons({required this.apple, required this.google, super.key});

  /// The official Sign in with Apple button.
  final Widget apple;

  /// The official Sign in with Google button.
  final Widget google;

  @override
  Widget build(BuildContext context) {
    final buttons = context.isApplePlatform ? [apple, google] : [google, apple];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: InVogueLayout.controlHeight, child: buttons.first),
        const SizedBox(height: InVogueSpace.s3),
        SizedBox(height: InVogueLayout.controlHeight, child: buttons.last),
      ],
    );
  }
}
