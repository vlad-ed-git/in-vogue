import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// A `rule` hairline: between sections and rows. Decorative only, never the
/// only edge of a control.
class Hairline extends StatelessWidget {
  const Hairline({this.color = InVogueColors.rule, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: InVogueLayout.strokeHairline,
    width: double.infinity,
    child: ColoredBox(color: color),
  );
}

/// The left and right page margin: 20 points, 16 below 360 points wide.
class PageMargin extends StatelessWidget {
  const PageMargin({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
    child: child,
  );
}

/// A heading inside a screen, in `section`: "Other outfits for tomorrow",
/// "About this outfit". It opens a new section, so it carries the 40-point
/// gap above it and sits 12 points over its content.
class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.text, {
    this.padding = const EdgeInsets.only(
      top: InVogueSpace.s10,
      bottom: InVogueSpace.s3,
    ),
    super.key,
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: InVogueType.section,
        textScaler: context.displayTextScaler,
      ),
    ),
  );
}

/// The one screen title, in `title`: what this screen is for.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {this.style = InVogueType.title, super.key});

  final String text;

  /// [InVogueType.title], or [InVogueType.headline] on Welcome and the two
  /// Pro screens.
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: style, textScaler: context.displayTextScaler),
  );
}
