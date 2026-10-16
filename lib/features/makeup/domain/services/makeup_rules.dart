import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

/// Chooses a makeup recipe from the knowledge base (makeup.v1.json) and
/// matches its steps to a face.
abstract final class MakeupRules {
  /// The knowledge base's names of the outfit palettes.
  static const palettes = {
    OutfitPalette.warmNeutral: 'warm_neutral',
    OutfitPalette.coolNeutral: 'cool_neutral',
    OutfitPalette.mixedNeutral: 'mixed_neutral',
    OutfitPalette.colourful: 'colourful',
  };

  /// The weather's change to the makeup: "rain" when anything falls,
  /// drizzle too; "cold_wind" when the coldest hours are cold or it is
  /// windy; "heat" when the warmest hours are hot and nothing else applies;
  /// both of the first two as "rain+cold_wind"; otherwise "none".
  static String weatherOf(WeatherClass weather) {
    final rain = weather.precipitation != Precipitation.dry || weather.drizzle;
    final coldWind = weather.band == WarmthBand.cold || weather.windy;
    return switch ((rain, coldWind)) {
      (true, true) => 'rain+cold_wind',
      (true, false) => 'rain',
      (false, true) => 'cold_wind',
      _ => weather.warmest == WarmthBand.hot ? 'heat' : 'none',
    };
  }

  /// The key of the recipe for [occasion], an outfit in [palette] (mixed
  /// neutrals when unknown), the face's [profile] and the [weather]
  /// modifier.
  static String keyOf({
    required Occasion occasion,
    required OutfitPalette? palette,
    required SkinProfile profile,
    required String weather,
  }) => [
    WeatherClass.contexts[occasion],
    palettes[palette ?? OutfitPalette.mixedNeutral],
    profile.shadeGroup.name,
    profile.contrast.name,
    weather,
  ].join('|');

  /// [step]'s effects with the face's own colours in place of their
  /// placeholders.
  static List<Map<String, Object?>> effectsFor(
    RecipeStep step,
    SkinProfile profile,
  ) {
    final colours = {
      SkinColour.skin.placeholder: profile.foundation,
      SkinColour.concealer.placeholder: profile.concealer,
      SkinColour.brow.placeholder: profile.brow,
      SkinColour.nudeLip.placeholder: profile.nudeLip,
    };
    Object? fill(Object? value) => switch (value) {
      final String text => colours[text] ?? text,
      final List<Object?> items => [for (final item in items) fill(item)],
      final Map<String, Object?> fields => {
        for (final MapEntry(:key, :value) in fields.entries) key: fill(value),
      },
      _ => value,
    };
    return [
      for (final effect in step.effects) fill(effect)! as Map<String, Object?>,
    ];
  }
}
