import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/wardrobe/data/data_sources/wardrobe_photo_local_data_source.dart';
import 'package:in_vogue/features/wardrobe/data/data_sources/wardrobe_remote_data_source.dart';
import 'package:in_vogue/features/wardrobe/data/models/wardrobe_outfit_model.dart';
import 'package:in_vogue/features/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:path/path.dart' as p;

const _details = OutfitDetails(
  name: 'Navy work suit',
  colours: {OutfitColour.navy, OutfitColour.white},
  bands: {WarmthBand.mild, WarmthBand.cool},
  rain: true,
  occasions: {Occasion.work},
);

/// An account's outfits in memory, as Firestore and Storage would keep them.
class _Remote implements WardrobeRemoteDataSource {
  final records = <String, Map<String, Object?>>{};
  final uploads = <String, String>{};
  final _changes = StreamController<void>.broadcast();
  Object? failUploadWith;
  var _ids = 0;

  @override
  Stream<List<(String, Map<String, Object?>)>> watch(String accountId) {
    StreamSubscription<void>? changes;
    late final StreamController<List<(String, Map<String, Object?>)>> sink;
    sink = StreamController(
      onListen: () {
        sink.add(_sorted());
        changes = _changes.stream.listen((_) => sink.add(_sorted()));
      },
      onCancel: () => changes?.cancel(),
    );
    return sink.stream;
  }

  List<(String, Map<String, Object?>)> _sorted() =>
      records.entries.map((entry) => (entry.key, entry.value)).toList()..sort(
        (a, b) =>
            (b.$2['createdAt']! as dynamic).compareTo(
                  a.$2['createdAt']! as dynamic,
                )
                as int,
      );

  @override
  String newId(String accountId) => 'outfit-${++_ids}';

  @override
  Future<(String, String)> uploadPhoto(
    String accountId,
    String id, {
    required String file,
    required String contentType,
  }) async {
    if (failUploadWith case final Object error) throw error;
    uploads[id] = file;
    return ('users/$accountId/wardrobe/$id.jpg', 'https://photos/$id.jpg');
  }

  @override
  Future<void> save(
    String accountId,
    String id,
    Map<String, Object?> json,
  ) async {
    records[id] = json;
    _changes.add(null);
  }

  @override
  Future<void> delete(String accountId, String id) async {
    records.remove(id);
    _changes.add(null);
  }
}

void main() {
  group('WardrobeOutfitModel', () {
    test('keeps an outfit as it was added', () {
      final createdAt = DateTime.utc(2026, 10, 18, 9);
      final json = WardrobeOutfitModel.toJson(
        details: _details,
        photoPath: 'users/uid-1/wardrobe/a.jpg',
        photoUrl: 'https://photos/a.jpg',
        createdAt: createdAt,
      );
      expect(json['colours'], ['white', 'navy']);
      expect(json['bands'], ['mild', 'cool']);
      expect(json['occasions'], ['work']);
      expect(
        WardrobeOutfitModel.photoPathOf(json),
        'users/uid-1/wardrobe/a.jpg',
      );
      expect(
        WardrobeOutfitModel.fromJson('a', json, photo: '/phone/a.jpg'),
        WardrobeOutfit(
          id: 'a',
          details: _details,
          photoUrl: 'https://photos/a.jpg',
          photoPath: '/phone/a.jpg',
          createdAt: createdAt.toLocal(),
        ),
      );
    });

    test('reads what it knows and leaves out what it does not', () {
      final json =
          WardrobeOutfitModel.toJson(
            details: _details,
            photoPath: 'p',
            photoUrl: 'u',
            createdAt: DateTime(2026),
          )..addAll({
            'colours': ['navy', 'chartreuse'],
            'bands': ['mild', 'tropical'],
            'occasions': ['work', 'gala'],
          });
      final outfit = WardrobeOutfitModel.fromJson('a', json)!;
      expect(outfit.details.colours, {OutfitColour.navy, OutfitColour.mixed});
      expect(outfit.details.bands, {WarmthBand.mild});
      expect(outfit.details.occasions, {Occasion.work});
      expect(WardrobeOutfitModel.fromJson('b', const {'name': 'Bare'}), isNull);
    });

    test('reads an outfit saved with one colour, before several could be '
        'chosen', () {
      final json = WardrobeOutfitModel.toJson(
        details: _details,
        photoPath: 'p',
        photoUrl: 'u',
        createdAt: DateTime(2026),
      );
      final colours = json.remove('colours');
      expect(colours, isNotNull);
      expect(
        WardrobeOutfitModel.fromJson('a', {
          ...json,
          'colour': 'navy',
        })!.details.colours,
        {OutfitColour.navy},
      );
      expect(WardrobeOutfitModel.fromJson('b', json), isNull);
    });
  });

  group('WardrobeRepositoryImpl', () {
    late Directory folder;
    late _Remote remote;
    late WardrobeRepositoryImpl repository;
    late String chosen;

    setUp(() async {
      folder = await Directory.systemTemp.createTemp('wardrobe');
      remote = _Remote();
      repository = WardrobeRepositoryImpl(
        remoteDataSource: remote,
        photoDataSource: WardrobePhotoLocalDataSourceImpl(
          p.join(folder.path, 'wardrobe'),
        ),
        logMessages: LogMessagesImpl(),
      );
      chosen = p.join(folder.path, 'chosen.jpg');
      await File(chosen).writeAsBytes(const [1, 2, 3]);
    });

    tearDown(() => folder.delete(recursive: true));

    test('adds an outfit: a copy on the phone, the photo on the account and '
        'its record', () async {
      final added = await withClock(
        Clock.fixed(DateTime(2026, 10, 18, 9)),
        () => repository.add('uid-1', photo: chosen, details: _details),
      );
      final outfit = added.getOrElse(() => throw StateError('added'));
      expect(outfit.details, _details);
      expect(outfit.photoUrl, 'https://photos/outfit-1.jpg');
      expect(File(outfit.photoPath!).readAsBytesSync(), const [1, 2, 3]);
      expect(remote.uploads['outfit-1'], outfit.photoPath);
      expect(remote.records['outfit-1']?['name'], 'Navy work suit');
    });

    test('leaves nothing on the phone when the upload fails', () async {
      remote.failUploadWith = NetworkException(Exception(), StackTrace.current);
      expect(
        await repository.add('uid-1', photo: chosen, details: _details),
        const Left<Failure, WardrobeOutfit>(NetworkFailure()),
      );
      expect(
        Directory(p.join(folder.path, 'wardrobe', 'uid-1')).listSync(),
        isEmpty,
      );
      expect(remote.records, isEmpty);
    });

    test('shows the outfits newest first, with the photo on the phone when '
        'it is there', () async {
      final updates = <List<WardrobeOutfit>>[];
      final watching = repository
          .watch('uid-1')
          .listen((update) => updates.add(update.getOrElse(() => const [])));
      await withClock(
        Clock.fixed(DateTime(2026, 10, 18, 9)),
        () => repository.add('uid-1', photo: chosen, details: _details),
      );
      await withClock(
        Clock.fixed(DateTime(2026, 10, 18, 10)),
        () => repository.add(
          'uid-1',
          photo: chosen,
          details: const OutfitDetails(
            name: 'Weekend jeans',
            colours: {OutfitColour.blue},
            bands: {WarmthBand.warm},
            occasions: {Occasion.casual},
          ),
        ),
      );
      await pumpEventQueue();
      expect(updates.last.map((outfit) => outfit.details.name), [
        'Weekend jeans',
        'Navy work suit',
      ]);
      expect(updates.last.every((outfit) => outfit.photoPath != null), isTrue);
      await watching.cancel();
    });

    test('removes an outfit everywhere', () async {
      final outfit = (await repository.add(
        'uid-1',
        photo: chosen,
        details: _details,
      )).getOrElse(() => throw StateError('added'));
      expect(
        await repository.remove('uid-1', outfit),
        const Right<Failure, Unit>(unit),
      );
      expect(remote.records, isEmpty);
      expect(File(outfit.photoPath!).existsSync(), isFalse);
    });

    test(
      "forgets an account's photos on the phone and no one else's",
      () async {
        final mine = (await repository.add(
          'uid-1',
          photo: chosen,
          details: _details,
        )).getOrElse(() => throw StateError('added'));
        final theirs = (await repository.add(
          'uid-2',
          photo: chosen,
          details: _details,
        )).getOrElse(() => throw StateError('added'));
        await repository.forgetPhotos('uid-1');
        expect(File(mine.photoPath!).existsSync(), isFalse);
        expect(File(theirs.photoPath!).existsSync(), isTrue);
      },
    );
  });
}
