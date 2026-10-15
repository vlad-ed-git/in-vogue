import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The three destinations after setup.
enum InVogueTab { home, makeup, settings }

/// Home · Makeup · Settings, in words: three plain words are clearer than
/// pictograms and keep the bar quiet under a photograph.
///
/// The current tab is ink at weight 700 with a 32 × 2 ink marker sitting on
/// the top hairline; the others are graphite. Paper, 50 points plus the
/// bottom safe area, and it never hides on scroll. Only on Home, Makeup and
/// Settings; never during setup or on pushed screens.
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
          // The marker covers the hairline: it starts one point above the
          // tab, on the rule itself.
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
