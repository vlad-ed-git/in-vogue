import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/services/makeup_rules.dart';
import 'package:in_vogue/features/makeup/domain/services/skin_rules.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

FaceColours _face({
  String skin = '#E8C4AE',
  String eyebrow = '#3B2A22',
  String lip = '#C98276',
  String hair = '#42280E',
  bool clear = true,
}) => FaceColours(
  skin: skin,
  eyebrow: eyebrow,
  lip: lip,
  hair: hair,
  clear: clear,
);

WeatherClass _weather({
  WarmthBand band = WarmthBand.mild,
  Precipitation precipitation = Precipitation.dry,
  bool windy = false,
  bool drizzle = false,
  WarmthBand? warmest,
}) => WeatherClass(
  band: band,
  precipitation: precipitation,
  windy: windy,
  drizzle: drizzle,
  warmest: warmest,
);

void main() {
  group('SkinRules', () {
    test('matches a clear face: its shade group, contrast and colours', () {
      expect(
        SkinRules.profileOf(_face()),
        const SkinProfile(
          shadeGroup: ShadeGroup.light,
          contrast: SkinContrast.high,
          foundation: '#E8C4AE',
          concealer: '#F2CEB7',
          brow: '#3B2A22',
          nudeLip: '#BB7B71',
          matched: true,
        ),
      );
    });

    test('takes the shade group from the skin, deeper near an edge', () {
      ShadeGroup group(String skin) =>
          SkinRules.profileOf(_face(skin: skin)).shadeGroup;
      // ITA° 63.5, 41.9, 13.0, −15.1.
      expect(group('#E8C4AE'), ShadeGroup.light);
      expect(group('#C69C82'), ShadeGroup.medium);
      expect(group('#B07A5A'), ShadeGroup.medium);
      expect(group('#8D5B40'), ShadeGroup.deep);
      expect(SkinRules.shadeGroupOf(43), ShadeGroup.light);
      expect(SkinRules.shadeGroupOf(42.9), ShadeGroup.medium);
      expect(SkinRules.shadeGroupOf(12), ShadeGroup.medium);
      expect(SkinRules.shadeGroupOf(11.9), ShadeGroup.deep);
    });

    test('takes the contrast from the darker of the brows and hair', () {
      expect(SkinRules.contrastOf(24.9), SkinContrast.low);
      expect(SkinRules.contrastOf(25), SkinContrast.medium);
      expect(SkinRules.contrastOf(45), SkinContrast.high);
      // Skin L* 43.5, black hair L* 0.
      expect(
        SkinRules.profileOf(_face(skin: '#8D5B40', hair: '#000000')).contrast,
        SkinContrast.medium,
      );
    });

    test('uses neutral colours for a missing, unclear or odd analysis', () {
      final neutral = SkinRules.neutral;
      expect(neutral.shadeGroup, ShadeGroup.medium);
      expect(neutral.contrast, SkinContrast.medium);
      expect(neutral.foundation, '#C69C82');
      expect(neutral.concealer, '#D0A58B');
      expect(neutral.nudeLip, '#A76C68');
      expect(neutral.matched, isFalse);
      expect(SkinRules.profileOf(null), neutral);
      expect(SkinRules.profileOf(_face(clear: false)), neutral);
      expect(SkinRules.profileOf(_face(skin: 'peach')), neutral);
    });
  });

  group('MakeupRules', () {
    test('names the weather the way the makeup recipes do', () {
      expect(MakeupRules.weatherOf(_weather()), 'none');
      expect(
        MakeupRules.weatherOf(_weather(precipitation: Precipitation.wet)),
        'rain',
      );
      expect(
        MakeupRules.weatherOf(_weather(precipitation: Precipitation.snow)),
        'rain',
      );
      expect(MakeupRules.weatherOf(_weather(drizzle: true)), 'rain');
      expect(
        MakeupRules.weatherOf(_weather(band: WarmthBand.cold)),
        'cold_wind',
      );
      expect(MakeupRules.weatherOf(_weather(windy: true)), 'cold_wind');
      expect(
        MakeupRules.weatherOf(
          _weather(precipitation: Precipitation.wet, windy: true),
        ),
        'rain+cold_wind',
      );
      expect(MakeupRules.weatherOf(_weather(warmest: WarmthBand.hot)), 'heat');
      expect(
        MakeupRules.weatherOf(
          _weather(warmest: WarmthBand.hot, precipitation: Precipitation.wet),
        ),
        'rain',
      );
    });

    test('keys a recipe by occasion, palette, face and weather', () {
      final profile = SkinRules.profileOf(_face());
      expect(
        MakeupRules.keyOf(
          occasion: Occasion.goingOut,
          palette: OutfitPalette.warmNeutral,
          profile: profile,
          weather: 'rain',
        ),
        'going_out|warm_neutral|light|high|rain',
      );
      expect(
        MakeupRules.keyOf(
          occasion: Occasion.stayingIn,
          palette: null,
          profile: SkinRules.neutral,
          weather: 'none',
        ),
        'staying_in|mixed_neutral|medium|medium|none',
      );
    });

    test("puts the face's own colours in place of the placeholders", () {
      const step = RecipeStep(
        title: 'Light base',
        howTo: 'Blend it in.',
        products: ['light foundation in your shade'],
        effects: [
          {'category': 'skin_smooth', 'skinSmoothStrength': 0},
          {
            'category': 'foundation',
            'palettes': [
              {'color': '{skin}', 'colorIntensity': 100},
            ],
          },
          {
            'category': 'lip_color',
            'palettes': [
              {'color': '{nudeLip}'},
              {'color': '#B9526D'},
            ],
          },
        ],
      );
      final profile = SkinRules.profileOf(_face());
      expect(MakeupRules.effectsFor(step, profile), [
        {'category': 'skin_smooth', 'skinSmoothStrength': 0},
        {
          'category': 'foundation',
          'palettes': [
            {'color': '#E8C4AE', 'colorIntensity': 100},
          ],
        },
        {
          'category': 'lip_color',
          'palettes': [
            {'color': '#BB7B71'},
            {'color': '#B9526D'},
          ],
        },
      ]);
    });
  });
}
