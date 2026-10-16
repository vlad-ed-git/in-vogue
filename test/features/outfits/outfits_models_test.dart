import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/data/data_sources/catalog_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/outfit_record_model.dart';
import 'package:in_vogue/features/outfits/data/models/outfits_model.dart';
import 'package:in_vogue/features/outfits/data/models/try_on_job_model.dart';
import 'package:in_vogue/features/outfits/data/models/unit_budget_model.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/services/choose_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

import '../../helpers/memory_store.dart';

Outfit _outfit(String id, List<String> pieces) => Outfit(
  id: id,
  signature: pieces.join('+'),
  pieces: pieces,
  passes: const [],
);

void main() {
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

    test('know the palette of every outfit', () {
      for (final outfit in index.outfits.values) {
        expect(outfit.palette, isNotNull, reason: outfit.id);
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

  group('ChooseOutfit', () {
    final ranked = [
      _outfit('a', ['p1', 'p2']),
      _outfit('b', ['p3', 'p4']),
      _outfit('c', ['p5', 'p6']),
      _outfit('d', ['p7', 'p8']),
      _outfit('e', ['p9', 'p10']),
    ];

    test('takes the best outfit not shown before', () {
      expect(ChooseOutfit.from(ranked, shown: {}, picks: {})?.id, 'a');
      expect(ChooseOutfit.from(ranked, shown: {'p1+p2'}, picks: {})?.id, 'b');
    });

    test(
      'lets loved pieces lift an outfit, by up to a quarter of the list',
      () {
        // Each place is worth 0.8 / 5; a fully loved outfit gains 0.2.
        expect(
          ChooseOutfit.from(ranked, shown: {}, picks: {'p3', 'p4'})?.id,
          'b',
        );
        expect(
          ChooseOutfit.from(ranked, shown: {}, picks: {'p5', 'p6'})?.id,
          'a',
        );
        expect(ChooseOutfit.from(ranked, shown: {}, picks: {'p3'})?.id, 'a');
      },
    );

    test('never rules out an outfit without loved pieces', () {
      expect(
        ChooseOutfit.from(
          ranked,
          shown: {'p5+p6'},
          picks: {'p5', 'p6', 'unknown'},
        )?.id,
        'a',
      );
    });

    test('has nothing when every outfit has been shown', () {
      expect(
        ChooseOutfit.from(
          ranked,
          shown: {for (final outfit in ranked) outfit.signature},
          picks: {'p1'},
        ),
        isNull,
      );
    });
  });

  test('the unit budget allows units up to its limit, never past it', () {
    expect(UnitBudgetModel.allows(spent: 0, limit: 15, units: 2), isTrue);
    expect(UnitBudgetModel.allows(spent: 13, limit: 15, units: 2), isTrue);
    expect(UnitBudgetModel.allows(spent: 14, limit: 15, units: 2), isFalse);
    expect(UnitBudgetModel.allows(spent: 16, limit: 15, units: 2), isFalse);
  });

  group('OutfitRecordModel', () {
    test('keeps pictures under the account by signature and type', () {
      expect(
        OutfitRecordModel.imagePath('uid-1', 'a+b', 'jpg'),
        'users/uid-1/outfits/a+b.jpg',
      );
      expect(OutfitRecordModel.extensionOf([0x89, 0x50, 0x4E, 0x47]), 'png');
      expect(OutfitRecordModel.extensionOf([0xFF, 0xD8, 0xFF, 0xE0]), 'jpg');
      expect(OutfitRecordModel.contentType('png'), 'image/png');
    });

    test('reads back what it writes', () {
      final record = (
        signature: 'a+b',
        outfitId: 'o1',
        pieces: ['everlane:a', 'everlane:b'],
        cell: 'cool|wet|calm|work',
        date: DateTime.utc(2026, 10, 17),
        occasion: Occasion.work,
        imagePath: 'users/uid-1/outfits/a+b.jpg',
        createdAt: null,
      );
      final json = OutfitRecordModel.toJson(record);
      expect(json['forDate'], '2026-10-17');
      final read = OutfitRecordModel.fromJson('a+b', json)!;
      expect(read.signature, 'a+b');
      expect(read.outfitId, 'o1');
      expect(read.pieces, record.pieces);
      expect(read.cell, record.cell);
      expect(read.date, record.date);
      expect(read.occasion, Occasion.work);
      expect(read.imagePath, record.imagePath);
      expect(OutfitRecordModel.fromJson('a+b', {'outfitId': 'o1'}), isNull);
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
      reservedPass: 1,
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
      expect(job.started('task-2', at).reservedPass, isNull);
      expect(job.reserving(1, at).reservedPass, 1);
      expect(job.unreserved(at).reservedPass, isNull);
      expect(job.started('task-2', at).keeping(1, at).tasks, ['task-1']);
    });
  });
}
