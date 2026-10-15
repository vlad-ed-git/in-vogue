import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// A kicker in the `label` style: WORKDAY, EXAMPLE, YOUR PHOTO.
///
/// Capitals and the +10% tracking are applied here, never written into the
/// string, and both are dropped for Chinese. Screen readers hear the words in
/// sentence case, so they are not spelt out letter by letter.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {this.color = InVogueColors.ink, super.key});

  /// Sentence-case words; three at most.
  final String text;
  final Color color;

  /// Whether kickers in [locale] are set in capitals with tracking.
  static bool usesCapitals(Locale? locale) => locale?.languageCode != 'zh';

  @override
  Widget build(BuildContext context) {
    final capitals = usesCapitals(Localizations.maybeLocaleOf(context));
    return Text(
      capitals ? text.toUpperCase() : text,
      semanticsLabel: text,
      style: InVogueType.label.copyWith(
        color: color,
        letterSpacing: capitals ? InVogueType.label.letterSpacing : 0,
      ),
    );
  }
}
