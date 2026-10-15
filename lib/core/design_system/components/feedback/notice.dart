import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A plain message in the flow of the page, with the fix next to it: a flat
/// Rose band, the icon on the left, ink words and an optional action below.
///
/// A blocking problem ([alert]) adds a 2-point ink rule along the top and
/// the `warning` icon; it is never red, so it can't pass for a Rouge action.
/// It lives where the problem is, never as a toast or modal.
class Notice extends StatelessWidget {
  const Notice({
    required this.icon,
    required this.message,
    this.action,
    this.alert = false,
    super.key,
  });

  /// Location is off: Home shows this in place of the weather.
  factory Notice.locationOff({
    required BuildContext context,
    required VoidCallback onOpenSettings,
    Key? key,
  }) => Notice(
    key: key,
    icon: InVogueIcons.mapPin,
    message: context.translated.locationOff,
    action: InVogueButton.primary(
      label: context.translated.openSettings,
      onPressed: onOpenSettings,
    ),
  );

  /// Offline: the saved outfit is on screen; [savedAt] is its real date and
  /// time, such as "Thu 16 Oct at 9:12 pm".
  factory Notice.offline({
    required BuildContext context,
    required String savedAt,
    Key? key,
  }) => Notice(
    key: key,
    icon: InVogueIcons.offline,
    message: context.translated.offlineSaved(savedAt),
  );

  /// A try-on failed: the user's photo stays, faded, above this.
  factory Notice.tryOnFailed({
    required BuildContext context,
    required VoidCallback onRetry,
    Key? key,
  }) => Notice(
    key: key,
    icon: InVogueIcons.warning,
    alert: true,
    message: context.translated.tryOnFailed,
    action: InVogueButton.secondary(
      label: context.translated.retry,
      icon: InVogueIcons.retry,
      onRose: true,
      onPressed: onRetry,
    ),
  );

  /// Every suitable outfit has been seen; nothing is repeated.
  factory Notice.everyLookSeen({
    required BuildContext context,
    required ForecastDay day,
    Key? key,
  }) => Notice(
    key: key,
    icon: InVogueIcons.check,
    message: context.translated.everyLookSeen(day.name),
  );

  /// The chosen photo is not full length. Its fix, Choose another photo,
  /// is the screen's primary button below.
  factory Notice.notFullLength({required BuildContext context, Key? key}) =>
      Notice(
        key: key,
        icon: InVogueIcons.warning,
        alert: true,
        message: context.translated.notFullLength,
      );

  final InVogueIcons icon;

  /// One or two plain sentences: what happened and what to do.
  final String message;

  /// The fix, usually a button.
  final Widget? action;

  /// A blocking problem: the ink rule on top, read out at once.
  final bool alert;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: alert,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: InVogueColors.accent,
        border: alert
            ? const Border(
                top: BorderSide(
                  color: InVogueColors.alert,
                  width: InVogueLayout.strokeSelect,
                ),
              )
            : null,
      ),
      child: Padding(
        // The alert rule is drawn inside the top padding, like the spec's
        // inset shadow, so the content does not move.
        padding: const EdgeInsets.all(InVogueSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InVogueIcon(
              icon,
              color: alert ? InVogueColors.alert : InVogueColors.onAccent,
            ),
            const SizedBox(width: InVogueSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    message,
                    style: InVogueType.body.copyWith(
                      color: InVogueColors.onAccent,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: InVogueSpace.s3),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
