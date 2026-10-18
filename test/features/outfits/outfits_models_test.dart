import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/catalog/data/data_sources/catalog_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/outfits_model.dart';
import 'package:in_vogue/features/outfits/data/models/try_on_job_model.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

import '../../helpers/memory_store.dart';

void main() {
  test(
    'reads each reason in every language it has, a plain one as English',
    () {
      const cell = 'mild|dry|calm|casual';
      Map<String, Object?> outfit(Object reason) => {
        'signature': 's',
        'pieces': <Object?>[],
        'passes': <Object?>[],
        'reasons': {cell: reason},
      };
      final index = OutfitsModel.fromJson({
        'cells': {
          cell: ['o1', 'o2'],
        },
        'outfits': {
          'o1': outfit({
            'en': 'A tee.',
            'es': 'Una camiseta.',
            'zh': '一件 T 恤。',
          }),
          'o2': outfit('A dress.'),
        },
      });
      final translated = index.outfits['o1']!.reasons[cell]!;
      expect(translated.of(SupportedLanguages.spanish), 'Una camiseta.');
      expect(translated.of(SupportedLanguages.chinese), '一件 T 恤。');
      expect(
        index.outfits['o2']!.reasons[cell]!.of(SupportedLanguages.chinese),
        'A dress.',
      );
    },
  );

  group('the bundled outfits', () {
    late OutfitIndex index;
    late Set<String> colourways;

    setUpAll(() {
      index = OutfitsModel.fromJson(
        jsonDecode(File(OutfitAssetDataSourceImpl.path).readAsStringSync()),
      );
      final catalog =
          jsonDecode(File(CatalogAssetDataSourceImpl.path).readAsStringSync())
              as Map<String, Object?>;
      colourways = {
        for (final piece in catalog['pieces']! as List<Object?>)
          for (final colourway
              in (piece! as Map<String, Object?>)['colourways']!
                  as List<Object?>)
            (colourway! as Map<String, Object?>)['id']! as String,
      };
    });

    test('have outfits for every weather class and occasion', () {
      for (final band in WarmthBand.values) {
        for (final precipitation in Precipitation.values) {
          if (precipitation == Precipitation.snow &&
              band != WarmthBand.cool &&
              band != WarmthBand.cold) {
            continue;
          }
          for (final windy in [false, true]) {
            for (final occasion in Occasion.values) {
              final cell = WeatherClass(
                band: band,
                precipitation: precipitation,
                windy: windy,
              ).cell(occasion);
              expect(index.cells[cell], isNotEmpty, reason: cell);
              for (final id in index.cells[cell]!) {
                expect(index.outfits[id]?.reasons[cell], isNotNull);
              }
            }
          }
        }
      }
    });

    test('say why in Spanish and Chinese too', () {
      for (final outfit in index.outfits.values) {
        for (final reason in outfit.reasons.values) {
          expect(
            reason.translations.keys,
            containsAll(['es', 'zh']),
            reason: reason.english,
          );
          expect(reason.translations.values, everyElement(isNotEmpty));
        }
      }
    });

    test('only use pieces of the bundled collection', () {
      for (final outfit in index.outfits.values) {
        expect(colourways, containsAll(outfit.pieces), reason: outfit.id);
        expect(outfit.passes, isNotEmpty, reason: outfit.id);
        for (final pass in outfit.passes) {
          expect(outfit.pieces, contains(pass.piece), reason: outfit.id);
          expect(Uri.parse(pass.reference).isAbsolute, isTrue);
        }
      }
    });

    test('put a dress on in one pass, everything else from the bottom up', () {
      for (final outfit in index.outfits.values) {
        final categories = [for (final pass in outfit.passes) pass.category];
        final base = [
          for (final category in categories)
            if (category != GarmentCategory.outer) category,
        ];
        expect(
          base,
          anyOf(
            equals([GarmentCategory.fullBody]),
            equals([GarmentCategory.lowerBody, GarmentCategory.upperBody]),
          ),
          reason: outfit.id,
        );
        if (categories.contains(GarmentCategory.outer)) {
          expect(categories.last, GarmentCategory.outer, reason: outfit.id);
        }
      }
    });
  });

  group('try-on jobs', () {
    final job = TryOnJob(
      accountId: 'uid-1',
      date: DateTime.utc(2026, 10, 17),
      occasion: Occasion.casual,
      cell: 'mild|dry|calm|casual',
      outfitId: 'o1',
      photoRevision: 2,
      updatedAt: DateTime.utc(2026, 10, 16, 15),
      tasks: const ['task-1'],
    );

    test('are kept as JSON and read back', () {
      expect(TryOnJobModel.fromJson(TryOnJobModel.toJson(job)), job);
      expect(job.key, 'uid-1|2026-10-17|casual');
    });

    test('are saved, found and cleared on the phone', () async {
      final repository = TryOnJobRepositoryImpl(
        TryOnJobLocalDataSourceImpl(MemoryStore()),
      );
      expect((await repository.job(job.key)).getOrElse(() => null), isNull);
      await repository.save(job);
      expect((await repository.job(job.key)).getOrElse(() => null), job);
      await repository.clear(job.key);
      expect((await repository.job(job.key)).getOrElse(() => null), isNull);
    });

    test('record each step', () {
      final at = DateTime.utc(2026, 10, 16, 16);
      expect(job.started('task-2', at).tasks, ['task-1', 'task-2']);
      expect(job.started('task-2', at).keeping(1, at).tasks, ['task-1']);
    });
  });
}
