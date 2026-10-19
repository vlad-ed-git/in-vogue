import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/components/feedback/in_vogue_sheet.dart';
import 'package:in_vogue/core/presentation/foundations/kicker.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';

/// The occasion as a kicker.
class OccasionLine extends StatelessWidget {
  const OccasionLine({required this.occasion, super.key});

  final Occasion occasion;

  static const double height = 32;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: height),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Kicker(occasion.kicker(context.translated)),
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
