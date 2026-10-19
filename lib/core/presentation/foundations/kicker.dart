import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// Short text in the label style, shown in capitals with tracking except in
/// Chinese. Screen readers read [text] as given.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key});

  final String text;

  /// Whether [locale] uses capitals and tracking.
  static bool usesCapitals(Locale? locale) => locale?.languageCode != 'zh';

  @override
  Widget build(BuildContext context) {
    final capitals = usesCapitals(Localizations.maybeLocaleOf(context));
    return Text(
      capitals ? text.toUpperCase() : text,
      semanticsLabel: text,
      style: InVogueType.label.copyWith(
        letterSpacing: capitals ? InVogueType.label.letterSpacing : 0,
      ),
    );
  }
}
