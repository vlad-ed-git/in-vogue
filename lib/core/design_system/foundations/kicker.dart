import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// Short text in the label style, shown in capitals with tracking except in
/// Chinese. Screen readers read [text] as given.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {this.color = InVogueColors.ink, super.key});

  final String text;
  final Color color;

  /// Whether [locale] uses capitals and tracking.
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
