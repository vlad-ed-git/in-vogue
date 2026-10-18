import 'package:equatable/equatable.dart';

/// Whether the skin leans golden, pink or neither.
enum Undertone { warm, neutral, cool }

/// How light or deep the person's colouring is.
enum Depth { light, medium, deep }

/// How far the hair and brows are from the skin in lightness.
enum Contrast { low, medium, high }

/// The twelve colour seasons.
enum ColourSeason {
  lightSpring,
  trueSpring,
  brightSpring,
  lightSummer,
  trueSummer,
  softSummer,
  softAutumn,
  trueAutumn,
  darkAutumn,
  darkWinter,
  trueWinter,
  brightWinter,
}

/// A season's clothing colours as `0xFFRRGGBB`.
class ColourPalette extends Equatable {
  const ColourPalette({
    required this.suits,
    required this.neutrals,
    required this.avoid,
  });

  final List<int> suits;
  final List<int> neutrals;

  /// Colours to go easy on.
  final List<int> avoid;

  @override
  List<Object?> get props => [suits, neutrals, avoid];
}

/// What a face's colours say: the season, why, and its palette.
class ColourReading extends Equatable {
  const ColourReading({
    required this.season,
    required this.undertone,
    required this.depth,
    required this.contrast,
    required this.palette,
    required this.clear,
  });

  final ColourSeason season;
  final Undertone undertone;
  final Depth depth;
  final Contrast contrast;
  final ColourPalette palette;

  /// Whether it comes from a photo clear enough to trust.
  final bool clear;

  @override
  List<Object?> get props => [
    season,
    undertone,
    depth,
    contrast,
    palette,
    clear,
  ];
}
