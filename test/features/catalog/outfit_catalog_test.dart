import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/outfit_catalog_remote_data_source.dart';
import 'package:in_vogue/features/catalog/data/models/catalog_outfit_model.dart';
import 'package:in_vogue/features/catalog/data/repositories/outfit_catalog_repository_impl.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

import '../../helpers/catalog_outfits.dart';

class _FakeRemote implements OutfitCatalogRemoteDataSource {
  int serverVersion = 2;
  List<Map<String, Object?>> documents = [];
  Exception? failure;
  int versions = 0, samples = 0, wholes = 0;

  Future<T> _answer<T>(T value) async {
    if (failure case final failure?) throw failure;
    return value;
  }

  @override
  Future<int> version() {
    versions++;
    return _answer(serverVersion);
  }

  @override
  Future<List<Map<String, Object?>>> sample() {
    samples++;
    return _answer([
      for (final doc in documents)
        if (doc['sample'] == true) doc,
    ]);
  }

  @override
  Future<List<Map<String, Object?>>> outfits() {
    wholes++;
    return _answer(documents);
  }
}

class _FakeLocal implements OutfitCatalogLocalDataSource {
  CatalogCopy? copy;

  @override
  Future<CatalogCopy?> read() async => copy;

  @override
  Future<void> save(CatalogCopy copy) async => this.copy = copy;
}

class _Log implements LogMessages {
  final errors = <Object>[];

  @override
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  }) => errors.add(error);
}

void main() {
  group('CatalogOutfitModel', () {
    test('reads an outfit document with its pieces and passes', () {
      final read = outfit('o1', order: 7, sample: true);
      expect(read.id, 'o1');
      expect(read.order, 7);
      expect(read.sample, isTrue);
      expect(read.imageUrl, 'https://firebasestorage.googleapis.com/o1.jpg');
      expect(read.weathers, {WarmthBand.mild});
      expect(read.seasons, {ColourSeason.lightSpring, ColourSeason.softAutumn});
      expect(read.dressy, 2.5);
      expect(read.warmth, 3);
      expect(
        (read.rain, read.wind, read.coat),
        (RainFit.fine, WindFit.fine, false),
      );
      final [top, skirt] = read.pieces;
      expect(top.hex, 0xFFD6CDC2);
      expect(top.role, PieceRole.top);
      expect(top.warmth, PieceWarmth.medium);
      expect(top.dressy, 3);
      expect(top.accent, isNull);
      expect(top.weathers, hasLength(4));
      expect(skirt.accent, 'navy');
      expect(skirt.pattern, ColourPattern.striped);
      expect(skirt.warmth, PieceWarmth.veryWarm);
      expect((skirt.rain, skirt.wind), (RainFit.avoid, WindFit.avoid));
      expect(read.passes.first.category, GarmentCategory.lowerBody);
      expect(read.outsideIn.map((piece) => piece.name), [
        'The Cropped Crew Top in Ultrafine Merino',
        'Seamed Midi Skirt',
      ]);
    });

    test('keeps only the app’s occasions', () {
      expect(outfit('o1').occasions, {
        Occasion.work,
        Occasion.casual,
        Occasion.stayingIn,
      });
    });

    test('rejects a document that is not an outfit', () {
      expect(
        () => CatalogOutfitModel.fromJson({
          ...document('o1'),
          'weathers': ['tropical'],
        }),
        throwsFormatException,
      );
      expect(
        () => CatalogOutfitModel.fromJson({
          ...document('o1'),
          'image': <String, Object?>{},
        }),
        throwsFormatException,
      );
    });
  });

  group('OutfitCatalogRemoteDataSourceImpl', () {
    test(
      'reads the version, the sample and every outfit, without timestamps',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('catalog').doc('outfits').set({
          'version': 2,
          'count': 2,
        });
        await firestore.collection('outfits').doc('o1').set({
          ...document('o1', sample: true),
          'updatedAt': DateTime(2026),
        });
        await firestore.collection('outfits').doc('o2').set(document('o2'));
        final remote = OutfitCatalogRemoteDataSourceImpl(firestore);
        expect(await remote.version(), 2);
        expect((await remote.sample()).map((doc) => doc['id']), ['o1']);
        final all = await remote.outfits();
        expect(all.map((doc) => doc['id']), unorderedEquals(['o1', 'o2']));
        expect(all.every((doc) => !doc.containsKey('updatedAt')), isTrue);
        expect(CatalogOutfitModel.fromJson(all.first).pieces, hasLength(2));
      },
    );
  });

  group('OutfitCatalogLocalDataSourceImpl', () {
    late Directory folder;
    setUp(() => folder = Directory.systemTemp.createTempSync('catalog'));
    tearDown(() => folder.deleteSync(recursive: true));

    test(
      'keeps the copy in a file, and reads none from a broken one',
      () async {
        final path = '${folder.path}/catalog/outfits.json';
        final local = OutfitCatalogLocalDataSourceImpl(path);
        expect(await local.read(), isNull);
        await local.save((version: 2, whole: true, outfits: [document('o1')]));
        final copy = await OutfitCatalogLocalDataSourceImpl(path).read();
        expect((copy!.version, copy.whole), (2, true));
        expect(CatalogOutfitModel.fromJson(copy.outfits.single).id, 'o1');
        File(path).writeAsStringSync('not json');
        expect(await local.read(), isNull);
      },
    );
  });

  group('OutfitCatalogRepositoryImpl', () {
    late _FakeRemote remote;
    late _FakeLocal local;
    late _Log log;
    OutfitCatalogRepositoryImpl repository() => OutfitCatalogRepositoryImpl(
      remote: remote,
      local: local,
      logMessages: log,
    );
    List<String> ids(Either<Failure, List<CatalogOutfit>> result) => result
        .getOrElse(() => throw StateError('$result'))
        .map((o) => o.id)
        .toList();

    setUp(() {
      remote = _FakeRemote()
        ..documents = [
          document('o3', order: 2, sample: true),
          document('o1', order: 0),
          document('o2', order: 1, sample: true),
        ];
      local = _FakeLocal();
      log = _Log();
    });

    test('fetches the sample once, keeps it, and answers from it', () async {
      final catalog = repository();
      expect(ids(await catalog.sample()), ['o2', 'o3']);
      expect(ids(await catalog.sample()), ['o2', 'o3']);
      expect((remote.versions, remote.samples), (1, 1));
      expect((local.copy!.version, local.copy!.whole), (2, false));
    });

    test('a phone with the current copy reads only the version', () async {
      await repository().outfits();
      final catalog = repository();
      expect(ids(await catalog.outfits()), ['o1', 'o2', 'o3']);
      expect(ids(await catalog.sample()), ['o2', 'o3']);
      expect((remote.versions, remote.wholes, remote.samples), (2, 1, 0));
    });

    test('fetches the catalog again when its version changes', () async {
      await repository().outfits();
      remote
        ..serverVersion = 3
        ..documents = [document('o9')];
      expect(ids(await repository().outfits()), ['o9']);
      expect(local.copy!.version, 3);
    });

    test('fetches every outfit when only the sample is kept', () async {
      final catalog = repository();
      await catalog.sample();
      expect(ids(await catalog.outfits()), ['o1', 'o2', 'o3']);
      expect(local.copy!.whole, isTrue);
    });

    test(
      'offline, uses the copy kept; with none, says so and tries again later',
      () async {
        await repository().outfits();
        remote.failure = NetworkException('offline', StackTrace.empty);
        expect(ids(await repository().outfits()), ['o1', 'o2', 'o3']);
        local.copy = null;
        final catalog = repository();
        expect(
          await catalog.sample(),
          const Left<Failure, List<CatalogOutfit>>(NetworkFailure()),
        );
        remote.failure = null;
        expect(ids(await catalog.sample()), ['o2', 'o3']);
      },
    );

    test('a refused read is a server failure, and is reported', () async {
      remote.failure = ServerException('permission-denied', StackTrace.empty);
      expect(
        await repository().outfits(),
        const Left<Failure, List<CatalogOutfit>>(ServerFailure()),
      );
      expect(log.errors, isNotEmpty);
    });

    test('leaves out a document it can’t read, and reports it', () async {
      remote.documents = [
        document('o1'),
        {'id': 'broken'},
      ];
      expect(ids(await repository().outfits()), ['o1']);
      expect(log.errors.single, isFormatException);
    });

    test('two loads at once fetch the catalog once', () async {
      final catalog = repository();
      await Future.wait([
        catalog.outfits(),
        catalog.outfits(),
        catalog.sample(),
      ]);
      expect((remote.versions, remote.wholes, remote.samples), (1, 1, 0));
    });
  });

  group('catalog use cases', () {
    late _FakeRemote remote;
    late OutfitCatalogRepositoryImpl catalog;
    setUp(() {
      remote = _FakeRemote()
        ..documents = [
          for (var i = 0; i < 45; i++)
            document(
              'o$i',
              order: i,
              weathers: i.isEven ? ['cold', 'freezing'] : ['warm'],
              rain: i % 5 == 0 ? 'good' : 'fine',
            ),
        ];
      catalog = OutfitCatalogRepositoryImpl(
        remote: remote,
        local: _FakeLocal(),
        logMessages: _Log(),
      );
    });

    test('pages through the catalog, 20 at a time', () async {
      final page = GetCatalogPage(catalog);
      final first = (await page(
        const CatalogPageParams(),
      )).getOrElse(() => throw StateError(''));
      expect(first.outfits.map((o) => o.id).take(3), ['o0', 'o1', 'o2']);
      expect((first.outfits.length, first.hasMore), (20, true));
      final last = (await page(
        const CatalogPageParams(offset: 40),
      )).getOrElse(() => throw StateError(''));
      expect((last.outfits.length, last.hasMore), (5, false));
      final beyond = (await page(
        const CatalogPageParams(offset: 60),
      )).getOrElse(() => throw StateError(''));
      expect(beyond.outfits, isEmpty);
      expect(beyond.hasMore, isFalse);
    });

    test(
      'a weather chip keeps the outfits for that weather, rain those good in rain',
      () async {
        final page = GetCatalogPage(catalog);
        final freezing = (await page(
          const CatalogPageParams(
            filter: CatalogFilter.weather(WarmthBand.freezing),
            limit: 100,
          ),
        )).getOrElse(() => throw StateError(''));
        expect(freezing.outfits, hasLength(23));
        expect(
          freezing.outfits.every(
            (o) => o.weathers.contains(WarmthBand.freezing),
          ),
          isTrue,
        );
        final rain = (await page(
          const CatalogPageParams(filter: CatalogFilter.rain(), limit: 100),
        )).getOrElse(() => throw StateError(''));
        expect(rain.outfits.map((o) => o.id), [
          'o0',
          'o5',
          'o10',
          'o15',
          'o20',
          'o25',
          'o30',
          'o35',
          'o40',
        ]);
      },
    );

    test(
      'finds outfits by id, in that order, leaving out unknown ones',
      () async {
        final found = await GetOutfits(catalog)([
          'o7',
          'everlane:a-piece',
          'o2',
        ]);
        expect(found.getOrElse(() => []).map((o) => o.id), ['o7', 'o2']);
      },
    );

    test('the sample comes from the catalog', () async {
      remote.documents = [document('o1', sample: true), document('o2')];
      final sample = await GetSampleOutfits(catalog)(const NoParams());
      expect(sample.getOrElse(() => []).map((o) => o.id), ['o1']);
    });
  });
}
