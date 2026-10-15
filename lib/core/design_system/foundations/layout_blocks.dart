import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// A full-width 1-point line.
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

/// Pads [child] with the horizontal page margin.
class PageMargin extends StatelessWidget {
  const PageMargin({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.pageMargin),
    child: child,
  );
}

/// A section heading, 40 points below what precedes it and 12 above what
/// follows by default.
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

/// A screen title, marked as a header.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {this.style = InVogueType.title, super.key});

  final String text;

  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: style, textScaler: context.displayTextScaler),
  );
}
