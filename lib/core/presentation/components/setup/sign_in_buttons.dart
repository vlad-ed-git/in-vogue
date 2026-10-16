import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A sign-in provider.
enum SignInProvider { apple, google }

/// Sign-in buttons, 12 apart: Apple then Google on Apple platforms, Google
/// alone elsewhere.
class SignInButtons extends StatelessWidget {
  const SignInButtons({
    required this.onApple,
    required this.onGoogle,
    super.key,
  });

  final VoidCallback? onApple;
  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    final apple = SignInButton(
      provider: SignInProvider.apple,
      onPressed: onApple,
    );
    final google = SignInButton(
      provider: SignInProvider.google,
      onPressed: onGoogle,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.isApplePlatform) ...[
          apple,
          const SizedBox(height: InVogueSpace.s3),
        ],
        google,
      ],
    );
  }
}

/// A full-width sign-in button with the provider's logo and a centred label.
/// Apple is ink with a paper label; Google is paper with an edge.
class SignInButton extends StatelessWidget {
  const SignInButton({
    required this.provider,
    required this.onPressed,
    super.key,
  });

  final SignInProvider provider;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final (label, icon) = switch (provider) {
      SignInProvider.apple => (l10n.signInWithApple, InVogueIcons.appleLogo),
      SignInProvider.google => (l10n.signInWithGoogle, InVogueIcons.googleLogo),
    };
    final apple = provider == SignInProvider.apple;
    return Pressable(
      onTap: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      expandTapTarget: false,
      builder: (context, state) {
        final enabled = state.enabled;
        final fill = !enabled
            ? InVogueColors.studio
            : (apple ? InVogueColors.ink : InVogueColors.paper);
        final foreground = !enabled
            ? InVogueColors.graphite
            : (apple ? InVogueColors.paper : InVogueColors.ink);
        return DecoratedBox(
          // Inset edge, as the CSS box-shadow draws it.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: apple || !enabled
                ? null
                : Border.all(color: InVogueColors.line),
          ),
          child: ColoredBox(
            color: fill,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: InVogueLayout.controlHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: InVogueSpace.s4,
                  vertical: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: foreground),
                    const SizedBox(width: InVogueSpace.s2),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: InVogueType.button.copyWith(color: foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
