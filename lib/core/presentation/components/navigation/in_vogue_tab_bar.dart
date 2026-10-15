import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Tab bar destinations.
enum InVogueTab { home, makeup, settings }

/// A bottom bar of three text tabs; the current one is bold with a 32 × 2
/// marker on the top hairline. Includes the bottom safe area.
class InVogueTabBar extends StatelessWidget {
  const InVogueTabBar({
    required this.current,
    required this.onSelected,
    super.key,
  });

  final InVogueTab current;
  final ValueChanged<InVogueTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final labels = {
      InVogueTab.home: l10n.tabHome,
      InVogueTab.makeup: l10n.tabMakeup,
      InVogueTab.settings: l10n.tabSettings,
    };
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: InVogueColors.paper,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: InVogueLayout.strokeHairline,
                child: ColoredBox(color: InVogueColors.rule),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: InVogueLayout.tabBarHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: InVogueLayout.strokeHairline,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final tab in InVogueTab.values)
                          Expanded(
                            child: _Tab(
                              label: labels[tab]!,
                              current: tab == current,
                              onTap: () => onSelected(tab),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.current, required this.onTap});

  final String label;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    selected: current,
    semanticLabel: label,
    excludeSemantics: true,
    expandTapTarget: false,
    builder: (context, state) => Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: current ? InVogueType.navActive : InVogueType.nav,
        ),
        if (current)
          // Starts on the hairline, one point above the tab.
          const Positioned(
            top: -InVogueLayout.strokeHairline,
            child: SizedBox(
              width: 32,
              height: InVogueLayout.strokeSelect,
              child: ColoredBox(color: InVogueColors.ink),
            ),
          ),
      ],
    ),
  );
}
