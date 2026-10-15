import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/preferences/presentation/widgets/language_row.dart';

/// The Settings tab: hairline rows of what the person can change.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SingleChildScrollView(
      child: PageMargin(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: InVogueSpace.s4),
            ScreenTitle(context.translated.tabSettings),
            const SizedBox(height: InVogueSpace.s6),
            const SettingsRows(children: [LanguageRow()]),
            const SizedBox(height: InVogueSpace.s10),
          ],
        ),
      ),
    ),
  );
}
