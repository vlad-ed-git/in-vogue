import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_asset_data_source.dart';
import 'package:in_vogue/features/makeup/data/models/face_colours_model.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_look_model.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_recipes_model.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/services/makeup_rules.dart';
import 'package:in_vogue/features/makeup/domain/services/skin_rules.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

const _analysis = {
  'face_quality': {
    'has_face': true,
    'area': 'good',
    'frontal': 'good',
    'lighting': 'good',
    'faceangle': 'good',
  },
  'color': {
    'skin_color': '#e8c4ae',
    'eyebrow_color': '#3B2A22',
    'lip_color': '#C98276',
    'eye_color': '#5B3A29',
    'eye_color_name': 'Brown',
    'hair_color': '#42280E',
    'hair_color_name': 'Brown',
  },
};

final _look = MakeupLook(
  outfitSignature: 'coat+tee',
  date: DateTime.utc(2026, 10, 17),
  occasion: Occasion.work,
  palette: OutfitPalette.coolNeutral,
  cheeks: CheekColour.rose,
  lips: LipColour.rosyNude,
  before: '/support/makeup/uid-1/coat+tee/before.png',
  steps: const [
    LookStep(
      title: LocalizedText(
        'Even base',
        translations: {'es': 'Base uniforme', 'zh': '均匀底妆'},
      ),
      howTo: LocalizedText('Blend it in.'),
      products: [LocalizedText('foundation in your shade')],
      picture: '/support/makeup/uid-1/coat+tee/step-1.jpg',
    ),
    LookStep(
      title: LocalizedText('Rosy-nude lips'),
      howTo: LocalizedText('Fill them in.'),
      products: [LocalizedText('rosy-nude lipstick')],
      picture: '/support/makeup/uid-1/coat+tee/step-2.png',
    ),
  ],
  matched: true,
);

void main() {
  test("reads each step's texts in every language they have, plain ones as "
      'English', () {
    final recipes = MakeupRecipesModel.fromJson({
      'steps': [
        {
          'title': {'en': 'Light base', 'es': 'Base ligera', 'zh': '轻薄底妆'},
          'howTo': {'en': 'Blend.', 'es': 'Difumina.', 'zh': '晕开。'},
          'products': [
            {'en': 'concealer', 'es': 'corrector', 'zh': '遮瑕'},
            'mascara',
          ],
          'effects': <Object?>[],
        },
      ],
      'recipes': {
        'work|colourful|light|low|none': {
          'cheeks': 'rose',
          'lips': 'nude',
          'steps': [0],
        },
      },
    });
    final step = recipes['work|colourful|light|low|none']!.steps.single;
    expect(step.title.of(SupportedLanguages.spanish), 'Base ligera');
    expect(step.howTo.of(SupportedLanguages.chinese), '晕开。');
    expect(
      [
        for (final product in step.products)
          product.of(SupportedLanguages.spanish),
      ],
      ['corrector', 'mascara'],
    );
  });

  group('the bundled makeup recipes', () {
    late Map<String, MakeupRecipe> recipes;

    setUpAll(() {
      recipes = MakeupRecipesModel.fromJson(
        jsonDecode(File(MakeupAssetDataSourceImpl.path).readAsStringSync()),
      );
    });

    test('have a recipe for every key the rules can make', () {
      const weathers = ['none', 'rain', 'cold_wind', 'heat', 'rain+cold_wind'];
      for (final occasion in Occasion.values) {
        for (final palette in OutfitPalette.values) {
          for (final shadeGroup in ShadeGroup.values) {
            for (final contrast in SkinContrast.values) {
              for (final weather in weathers) {
                final key = MakeupRules.keyOf(
                  occasion: occasion,
                  palette: palette,
                  profile: SkinProfile(
                    shadeGroup: shadeGroup,
                    contrast: contrast,
                    foundation: '#C69C82',
                    concealer: '#D0A58B',
                    brow: '#4A3628',
                    nudeLip: '#A76C68',
                    matched: true,
                  ),
                  weather: weather,
                );
                expect(recipes[key], isNotNull, reason: key);
                expect(recipes[key]!.steps.length, inInclusiveRange(3, 6));
              }
            }
          }
        }
      }
    });

    test('never smooth the skin and never touch the hair', () {
      for (final recipe in recipes.values) {
        for (final step in recipe.steps) {
          expect(step.effects.first, {
            'category': 'skin_smooth',
            'skinSmoothStrength': 0,
            'skinSmoothColorIntensity': 0,
          }, reason: recipe.key);
          for (final effect in step.effects) {
            expect('${effect['category']}', isNot(contains('hair')));
          }
        }
      }
    });

    test("only leave the face's own colours to fill in", () {
      final placeholders = {
        for (final colour in SkinColour.values) colour.placeholder,
      };
      void check(Object? value, String key) {
        switch (value) {
          case final String text when text.startsWith('{'):
            expect(placeholders, contains(text), reason: key);
          case final List<Object?> items:
            for (final item in items) {
              check(item, key);
            }
          case final Map<String, Object?> fields:
            for (final item in fields.values) {
              check(item, key);
            }
        }
      }

      for (final recipe in recipes.values) {
        for (final step in recipe.steps) {
          check(step.effects, recipe.key);
        }
      }
    });
  });

  group('FaceColoursModel', () {
    test("reads the analysis's colours, trusted when the photo is clear", () {
      expect(
        FaceColoursModel.fromAnalysis(_analysis),
        const FaceColours(
          skin: '#E8C4AE',
          eyebrow: '#3B2A22',
          lip: '#C98276',
          hair: '#42280E',
          clear: true,
        ),
      );
      final dim = {
        ..._analysis,
        'face_quality': {..._analysis['face_quality']!, 'lighting': 'too_dark'},
      };
      expect(FaceColoursModel.fromAnalysis(dim).clear, isFalse);
    });

    test('counts results without readable colours as an unclear photo', () {
      expect(
        FaceColoursModel.fromAnalysis({
          'face_quality': _analysis['face_quality'],
        }),
        SkinRules.neutralColours,
      );
      expect(
        FaceColoursModel.fromAnalysis({
          'color': {..._analysis['color']!, 'skin_color': 'tan'},
        }),
        SkinRules.neutralColours,
      );
    });

    test('keeps the colours on the account as they are', () {
      final colours = FaceColoursModel.fromAnalysis(_analysis);
      expect(
        FaceColoursModel.fromJson(FaceColoursModel.toJson(colours)),
        colours,
      );
      expect(FaceColoursModel.fromJson(const {'skin': '#000000'}), isNull);
    });
  });

  group('MakeupLookModel', () {
    test('records pictures by name and reads them back as names', () {
      final json = MakeupLookModel.toJson(_look);
      expect(json['before'], 'before.png');
      expect(json['palette'], 'cool_neutral');
      expect(json['cheeks'], 'rose');
      expect(json['lips'], 'rosy_nude');
      expect(json['forDate'], '2026-10-17');
      final read = MakeupLookModel.fromJson('coat+tee', json)!;
      expect(read.before, 'before.png');
      expect(
        [for (final step in read.steps) step.picture],
        ['step-1.jpg', 'step-2.png'],
      );
      expect(read.palette, _look.palette);
      expect(read.matched, isTrue);
      expect(
        MakeupLookModel.fromJson('coat+tee', {...json, 'steps': []}),
        isNull,
      );
    });

    test("keeps every language of the steps' texts, and reads a look kept "
        'in English only', () {
      final json = MakeupLookModel.toJson(_look);
      final steps = json['steps']! as List<Object?>;
      expect((steps.first! as Map<String, Object?>)['title'], {
        'en': 'Even base',
        'es': 'Base uniforme',
        'zh': '均匀底妆',
      });
      final read = MakeupLookModel.fromJson('coat+tee', json)!;
      expect(read.steps.first.title.of(SupportedLanguages.chinese), '均匀底妆');
      expect(read.steps.first.products, _look.steps.first.products);

      final english = MakeupLookModel.fromJson('coat+tee', {
        ...json,
        'steps': [
          {
            'title': 'Even base',
            'howTo': 'Blend it in.',
            'products': ['foundation in your shade'],
            'picture': 'step-1.jpg',
          },
        ],
      })!;
      expect(
        english.steps.single.title.of(SupportedLanguages.spanish),
        'Even base',
      );
      expect(
        english.steps.single.products.single.of(SupportedLanguages.spanish),
        'foundation in your shade',
      );
    });

    test('keeps pictures under the account by look and type', () {
      expect(
        MakeupLookModel.storagePath('uid-1', 'coat+tee', 'step-1.jpg'),
        'users/uid-1/makeup/coat+tee/step-1.jpg',
      );
      expect(
        MakeupLookModel.extensionOf(const [0x89, 0x50, 0x4E, 0x47]),
        'png',
      );
      expect(MakeupLookModel.extensionOf(const [0xFF, 0xD8, 0xFF]), 'jpg');
      expect(MakeupLookModel.contentType('before.png'), 'image/png');
      expect(MakeupLookModel.contentType('step-1.jpg'), 'image/jpeg');
    });
  });
}
