import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/text_link.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/foundations/running_rule.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Stacks [SettingsRow]s and closes them with a bottom hairline.
class SettingsRows extends StatelessWidget {
  const SettingsRows({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: InVogueColors.rule)),
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: InVogueLayout.strokeHairline),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

/// A hairline row: a name, an optional value, and a text action. While
/// [busy], the action's link, or a command's title, runs a [RunningRule].
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.value,
    this.action,
    this.onAction,
    this.busy = false,
    super.key,
  }) : avatar = null,
       showAvatar = false,
       icon = null,
       onTap = null;

  /// A row led by a 56-point square photo. Without [avatar] it shows
  /// [title]'s first letter on Rouge, or Rose when [title] is blank.
  const SettingsRow.profile({
    required this.title,
    required this.avatar,
    this.value,
    this.action,
    this.onAction,
    this.busy = false,
    super.key,
  }) : showAvatar = true,
       icon = null,
       onTap = null;

  /// A whole-row action in Rouge with its icon, such as Log out.
  const SettingsRow.command({
    required this.title,
    required IconData this.icon,
    required this.onTap,
    this.busy = false,
    super.key,
  }) : value = null,
       action = null,
       onAction = null,
       avatar = null,
       showAvatar = false;

  final String title;
  final String? value;

  /// Text link label, such as "Replace".
  final String? action;
  final VoidCallback? onAction;
  final ImageProvider? avatar;
  final bool showAvatar;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Working: taps do nothing and screen readers hear it loading.
  final bool busy;

  /// Log out; null [onTap] disables it.
  static SettingsRow logOut(
    BuildContext context,
    VoidCallback? onTap, {
    bool busy = false,
  }) => SettingsRow.command(
    title: context.translated.logOut,
    icon: InVogueIcons.signOut,
    onTap: onTap,
    busy: busy,
  );

  /// Delete account.
  static SettingsRow deleteAccount(
    BuildContext context,
    VoidCallback onTap, {
    bool busy = false,
  }) => SettingsRow.command(
    title: context.translated.deleteAccount,
    icon: InVogueIcons.trash,
    onTap: onTap,
    busy: busy,
  );

  /// [title]'s first letter, upper-cased; null when [title] is blank.
  String? get _initial {
    final name = title.trim();
    return name.isEmpty ? null : name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Row(
            children: [
              Icon(icon!, size: 20, color: InVogueColors.signal),
              const SizedBox(width: 6),
              Flexible(
                child: Stack(
                  children: [
                    Text(
                      title,
                      style: InVogueType.item.copyWith(
                        color: InVogueColors.signal,
                      ),
                    ),
                    if (busy)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: RunningRule(color: InVogueColors.signal),
                      ),
                  ],
                ),
              ),
            ],
          )
        else
          Text(title, style: InVogueType.item),
        if (value != null) ...[
          const SizedBox(height: 2),
          Text(
            value!,
            style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
          ),
        ],
      ],
    );
    final row = DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: InVogueColors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: InVogueLayout.strokeHairline + InVogueSpace.s3,
          bottom: InVogueSpace.s3,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 56 - InVogueLayout.strokeHairline - 2 * InVogueSpace.s3,
          ),
          child: Row(
            children: [
              if (showAvatar) ...[
                SizedBox.square(
                  dimension: 56,
                  child: switch ((avatar, _initial)) {
                    (null, final String letter) => _Initial(letter),
                    _ => PhotoSlot(image: avatar, aspectRatio: 1),
                  },
                ),
                const SizedBox(width: InVogueSpace.s3),
              ],
              Expanded(child: text),
              if (action != null) ...[
                const SizedBox(width: InVogueSpace.s4),
                TextLink(label: action!, onTap: onAction, busy: busy),
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null && !busy) return row;
    return Pressable(
      onTap: busy ? null : onTap,
      semanticLabel: title,
      semanticValue: busy ? context.translated.loading : null,
      excludeSemantics: true,
      expandTapTarget: false,
      builder: (context, state) => row,
    );
  }
}

/// A Rouge square with [letter] centred in white, in the logo's type.
class _Initial extends StatelessWidget {
  const _Initial(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: ColoredBox(
        color: InVogueColors.signal,
        child: Center(
          child: Text(
            letter,
            maxLines: 1,
            textAlign: TextAlign.center,
            textScaler: TextScaler.noScaling,
            style: InVogueType.title.copyWith(color: InVogueColors.onSignal),
          ),
        ),
      ),
    ),
  );
}
