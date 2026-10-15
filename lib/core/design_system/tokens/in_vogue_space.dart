/// The spacing scale of `design-spec/tokens.json`: a 4-point baseline.
/// Space separates; boxes do not.
abstract final class InVogueSpace {
  /// Icon to its label; swatch to swatch.
  static const double s1 = 4;

  /// Photo to its caption; tight stacks inside a row.
  static const double s2 = 8;

  /// Grid gutter; between a title and its line of text.
  static const double s3 = 12;

  /// Inside sheets and bars; between rows in a list.
  static const double s4 = 16;

  /// Page margin: the left and right edge of every screen.
  static const double s5 = 20;

  /// Between blocks inside a section.
  static const double s6 = 24;

  /// Above the free-plan line; between a screen title and its first block.
  static const double s8 = 32;

  /// Between sections on Home, Shop and Makeup.
  static const double s10 = 40;

  /// Above the headline on Welcome and the Pro screens.
  static const double s12 = 48;

  /// Clear space after the last block, above the tab bar.
  static const double s16 = 64;
}
