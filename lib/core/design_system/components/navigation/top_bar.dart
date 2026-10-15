import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The first line of Home: the forecast's city on the left and Your picks
/// on the right. No logo, search, avatar, bell or greeting.
///
/// The city comes from the location, never typed in; a long name wraps,
/// never truncates. Without location, Home shows the location notice instead.
class TopBar extends StatelessWidget {
  const TopBar({required this.city, required this.onYourPicks, super.key});

  final String city;

  /// Opens Pick what you like.
  final VoidCallback? onYourPicks;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: InVogueLayout.topBarHeight),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(child: Text(city, style: InVogueType.item)),
          const SizedBox(width: InVogueSpace.s4),
          // At very large text the link wraps within 60% of the bar rather
          // than pushing the city off the screen.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
            child: YourPicksLink(onTap: onYourPicks),
          ),
        ],
      ),
    ),
  );
}

/// "Your picks" with the outline heart, in the link size, not underlined.
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
