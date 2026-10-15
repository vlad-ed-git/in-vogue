import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A bar with a place name on the left and a Your picks link on the right.
class TopBar extends StatelessWidget {
  const TopBar({required this.city, required this.onYourPicks, super.key});

  final String city;

  /// Your picks action.
  final VoidCallback? onYourPicks;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: InVogueLayout.topBarHeight),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: Text(city, style: InVogueType.item)),
          const SizedBox(width: InVogueSpace.s4),
          // Wraps the link within 60% of the bar at very large text.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
            child: YourPicksLink(onTap: onYourPicks),
          ),
        ],
      ),
    ),
  );
}

/// A heart followed by "Your picks".
class YourPicksLink extends StatelessWidget {
  const YourPicksLink({required this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = context.translated.yourPicks;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, state) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InVogueIcon(
            InVogueIcons.heart,
            size: 20,
            color: InVogueColors.ink,
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: InVogueType.link)),
        ],
      ),
    );
  }
}
