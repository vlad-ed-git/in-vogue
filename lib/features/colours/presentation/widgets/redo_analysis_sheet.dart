import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Asks whether to redo the skin analysis from the new face photo; true
/// when the person asks to.
Future<bool> offerAnalysisRedo(BuildContext context) async {
  final redo = await showInVogueSheet<bool>(
    context: context,
    builder: (context) {
      final l10n = context.translated;
      return InVogueSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InVogueSheetHeader(
              title: l10n.redoAnalysisTitle,
              subtitle: l10n.redoAnalysisLine,
            ),
            InVogueButton.primary(
              label: l10n.redoAnalysis,
              icon: InVogueIcons.retry,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: InVogueSpace.s3),
            InVogueButton.secondary(
              label: l10n.keepColours,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      );
    },
  );
  return redo ?? false;
}
