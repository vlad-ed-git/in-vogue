import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';

FaceColours _face(String skin, String hair, String brow, {bool clear = true}) =>
    FaceColours(
      skin: skin,
      eyebrow: brow,
      lip: '#B5726E',
      hair: hair,
      clear: clear,
    );

void main() {
  group('the season of a face', () {
    final cases = {
      'golden blonde, peachy fair': (
        _face('#F3D3B5', '#C9A26B', '#A07850'),
        ColourSeason.lightSpring,
      ),
      'light warm skin, red hair': (
        _face('#F1CDB0', '#B5562A', '#A0603A'),
        ColourSeason.lightSpring,
      ),
      'medium warm skin, auburn hair': (
        _face('#D7A47E', '#8A4B2A', '#7A4A30'),
        ColourSeason.trueAutumn,
      ),
      'deep warm skin': (
        _face('#8D5524', '#2B1B10', '#2B1B10'),
        ColourSeason.darkAutumn,
      ),
      'olive skin, dark brown hair': (
        _face('#C08A66', '#3B2A20', '#3B2A20'),
        ColourSeason.softAutumn,
      ),
      'rosy fair skin, ash light brown hair': (
        _face('#E3C2B9', '#A89585', '#9A8878'),
        ColourSeason.lightSummer,
      ),
      'cool medium skin, ash brown hair': (
        _face('#C7A096', '#6E625C', '#625852'),
        ColourSeason.trueSummer,
      ),
      'pink fair skin, black hair': (
        _face('#EBC9C3', '#1A1A1A', '#222222'),
        ColourSeason.trueWinter,
      ),
      'deep cool skin': (
        _face('#6B4A44', '#141414', '#141414'),
        ColourSeason.darkWinter,
      ),
    };
    for (final MapEntry(key: name, value: (face, season)) in cases.entries) {
      test(name, () => expect(SeasonRules.readingOf(face).season, season));
    }
  });

  test('keeps the colours it was read from', () {
    final face = _face('#EBC9C3', '#1A1A1A', '#222222');
    expect(SeasonRules.readingOf(face).colours, face);
  });

  test('says why: undertone, depth and contrast', () {
    final reading = SeasonRules.readingOf(
      _face('#EBC9C3', '#1A1A1A', '#222222'),
    );
    expect(reading.undertone, Undertone.cool);
    expect(reading.depth, Depth.medium);
    expect(reading.contrast, Contrast.high);
    expect(reading.palette, SeasonRules.palettes[ColourSeason.trueWinter]);
  });

  test('a neutral undertone leans on the hair: golden hair warms it', () {
    final reading = SeasonRules.readingOf(
      _face('#C9A18A', '#6B5444', '#5E4A3C'),
    );
    expect(reading.undertone, Undertone.neutral);
    expect(reading.season, ColourSeason.softAutumn);
  });

  test('keeps whether the photo was clear enough to trust', () {
    expect(SeasonRules.readingOf(SeasonRules.neutralColours).clear, isFalse);
    expect(
      SeasonRules.readingOf(_face('#F3D3B5', '#C9A26B', '#A07850')).clear,
      isTrue,
    );
  });

  test('unreadable colours read as the neutral colours', () {
    expect(
      SeasonRules.readingOf(_face('tan', '#C9A26B', '#A07850')).season,
      SeasonRules.readingOf(SeasonRules.neutralColours).season,
    );
  });

  test('every season has its palette: twelve colours that suit, six '
      'neutrals and four to go easy on, all opaque and different', () {
    expect(SeasonRules.palettes.keys, unorderedEquals(ColourSeason.values));
    for (final MapEntry(key: season, value: palette)
        in SeasonRules.palettes.entries) {
      expect(palette.suits, hasLength(12), reason: '$season');
      expect(palette.neutrals, hasLength(6), reason: '$season');
      expect(palette.avoid, hasLength(4), reason: '$season');
      final all = [...palette.suits, ...palette.neutrals, ...palette.avoid];
      expect(all.toSet(), hasLength(all.length), reason: '$season');
      expect(all.every((colour) => colour >> 24 == 0xFF), isTrue);
    }
  });
}
