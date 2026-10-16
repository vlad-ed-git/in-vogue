import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A Rose band with an icon, a message and an optional action. [alert] adds
/// a 2-point ink rule on top and announces the message.
class Notice extends StatelessWidget {
  const Notice({
    required this.icon,
    required this.message,
    this.action,
    this.alert = false,
    super.key,
  });

  /// Location is unavailable; offers Open settings.
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

  /// Offline, with the time [savedAt] the content was saved.
  factory Notice.offline({
    required BuildContext context,
    required String savedAt,
    Key? key,
  }) => Notice(
    key: key,
    icon: InVogueIcons.offline,
    message: context.translated.offlineSaved(savedAt),
  );

  /// A failed try-on; offers Try again.
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

  /// Every suitable outfit for [day] has been shown.
  factory Notice.everyLookSeen({
    required BuildContext context,
    required ForecastDay day,
    Key? key,
  }) => Notice(
    key: key,
    icon: InVogueIcons.check,
    message: context.translated.everyLookSeen(day.name),
  );

  final IconData icon;

  final String message;

  /// Shown below the message.
  final Widget? action;

  /// Adds the ink rule and announces the message.
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
        // The alert rule is drawn inside the padding, like CSS's inset
        // shadow, so content does not move.
        padding: const EdgeInsets.all(InVogueSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
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
