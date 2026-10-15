import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/components/actions/text_link.dart';
import 'package:in_vogue/core/design_system/components/feedback/in_vogue_sheet.dart';
import 'package:in_vogue/core/design_system/foundations/kicker.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';

/// The occasion as a kicker, with an optional Change link.
class OccasionLine extends StatelessWidget {
  const OccasionLine({required this.occasion, this.onChange, super.key});

  final Occasion occasion;

  /// Shows a Change link when set.
  final VoidCallback? onChange;

  static const double height = 32;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: height),
    child: Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Kicker(occasion.kicker(context.translated)),
          ),
        ),
        if (onChange != null) ...[
          const SizedBox(width: InVogueSpace.s4),
          TextLink(label: context.translated.change, onTap: onChange),
        ],
      ],
    ),
  );
}

/// Opens a sheet to choose an occasion for [day]; returns the choice.
Future<Occasion?> showOccasionSheet({
  required BuildContext context,
  required Occasion current,
  required ForecastDay day,
  required String date,
}) => showInVogueSheet<Occasion>(
  context: context,
  builder: (context) => InVogueSheet(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InVogueSheetHeader(
          title: context.translated.dayIs(day.name),
          subtitle: date,
        ),
        for (final occasion in Occasion.values)
          InVogueSheetOption(
            label: occasion.label(context.translated),
            selected: occasion == current,
            onTap: () => Navigator.of(context).pop(occasion),
          ),
      ],
    ),
  ),
);
