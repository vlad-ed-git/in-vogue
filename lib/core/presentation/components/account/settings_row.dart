import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/text_link.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
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

/// A hairline row: a name, an optional value, and a text action.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.value,
    this.action,
    this.onAction,
    super.key,
  }) : avatar = null,
       showAvatar = false,
       icon = null,
       onTap = null;

  /// A row led by a 56-point square photo; Rose when [avatar] is null.
  const SettingsRow.profile({
    required this.title,
    required this.avatar,
    this.value,
    this.action,
    this.onAction,
    super.key,
  }) : showAvatar = true,
       icon = null,
       onTap = null;

  /// A whole-row action with an ink icon, such as Log out.
  const SettingsRow.command({
    required this.title,
    required IconData this.icon,
    required this.onTap,
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

  /// Log out.
  static SettingsRow logOut(BuildContext context, VoidCallback onTap) =>
      SettingsRow.command(
        title: context.translated.logOut,
        icon: InVogueIcons.signOut,
        onTap: onTap,
      );

  /// Delete account, in the ink alert colour.
  static SettingsRow deleteAccount(BuildContext context, VoidCallback onTap) =>
      SettingsRow.command(
        title: context.translated.deleteAccount,
        icon: InVogueIcons.trash,
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Row(
            children: [
              Icon(icon!, size: 20, color: InVogueColors.alert),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: InVogueType.item.copyWith(color: InVogueColors.alert),
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
                  child: PhotoSlot(image: avatar, aspectRatio: 1),
                ),
                const SizedBox(width: InVogueSpace.s3),
              ],
              Expanded(child: text),
              if (action != null) ...[
                const SizedBox(width: InVogueSpace.s4),
                TextLink(label: action!, onTap: onAction),
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return row;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      excludeSemantics: true,
      expandTapTarget: false,
      builder: (context, state) => row,
    );
  }
}
