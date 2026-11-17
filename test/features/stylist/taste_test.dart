import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_local_data_source.dart';
import 'package:in_vogue/features/stylist/data/data_sources/taste_remote_data_source.dart';
import 'package:in_vogue/features/stylist/data/models/taste_signal_model.dart';
import 'package:in_vogue/features/stylist/data/repositories/taste_repository_impl.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/stylist/domain/services/taste_model.dart';

import '../../helpers/memory_store.dart';
import '../../helpers/stylist_fixtures.dart';
import '../../helpers/taste.dart';

final _at = DateTime.utc(2026, 10, 19, 9);

TasteSignal _signal(
  String id,
  TasteSignalKind kind, {
  String? outfit,
  Set<String> families = const {},
}) => TasteSignal(
  id: id,
  kind: kind,
  at: _at,
  outfitId: outfit,
  families: families,
);

/// The account's signals, keeping what each save sent.
class _RecordingRemote implements TasteRemoteDataSource {
  _RecordingRemote(this._remote);
  final TasteRemoteDataSource _remote;
  final sent = <List<String>>[];

  /// Whether the next save fails.
  var offline = false;

  @override
  Future<List<Object?>> signals(String accountId) => _remote.signals(accountId);

  @override
  Future<void> add(String accountId, List<Map<String, Object?>> signals) {
    if (offline) {
      offline = false;
      throw NetworkException(Exception('offline'), StackTrace.empty);
    }
    sent.add([for (final signal in signals) signal['id']! as String]);
    return _remote.add(accountId, signals);
  }
}

void main() {
  final catalog = catalogFixture;
  final byId = {for (final outfit in catalog) outfit.id: outfit};
  final features = TasteFeatures(catalog);
  bool dress(CatalogOutfit outfit) => outfit.kinds.contains('dress');
  double mean(Iterable<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  group('TasteFeatures', () {
    test('45 features, centred over the catalog, the last the bias', () {
      final all = [for (final outfit in catalog) features.of(outfit)];
      expect(all.first, hasLength(TasteFeatures.size));
      expect(TasteFeatures.size, 45);
      for (var i = 0; i < TasteFeatures.size - 1; i++) {
        expect(mean([for (final x in all) x[i]]), closeTo(0, 1e-9));
      }
      expect(all.first.last, closeTo(1 / sqrt(45), 1e-12));
    });

    test('a wardrobe outfit says only its colours', () {
      final x = features.ofColours({'navy', 'not-a-family'});
      expect(x[TasteFeatures.families.indexOf('navy')], greaterThan(0));
      expect(x.skip(TasteFeatures.families.length), everyElement(0));
      expect(features.ofColours(const {}), everyElement(0));
    });
  });

  group('TasteModel', () {
    test('knows nothing at first, and draws alike for alike seeds', () {
      final prior = TasteModel.prior();
      expect(prior.mean(), everyElement(closeTo(0, 1e-12)));
      expect(
        prior.draw(Random(TasteModel.seed('uid-1|2026-10-19|work'))),
        prior.draw(Random(TasteModel.seed('uid-1|2026-10-19|work'))),
      );
      expect(
        prior.draw(Random(TasteModel.seed('uid-1|2026-10-19|work'))),
        isNot(prior.draw(Random(TasteModel.seed('uid-1|2026-10-20|work')))),
      );
      // FNV-1a's value for the empty string: the same on every platform.
      expect(TasteModel.seed(''), 0x811c9dc5);
    });

    test('loved outfits lift those like them, unloved ones lower them', () {
      final dresses = catalog.where(dress).toList();
      final others = catalog.where((outfit) => !dress(outfit)).toList();
      final loved = TasteModel.learn(
        [
          for (final outfit in dresses.take(6))
            _signal('l-${outfit.id}', TasteSignalKind.loved, outfit: outfit.id),
        ],
        features: features,
        catalog: byId,
      ).mean();
      double liking(List<double> weights, List<CatalogOutfit> outfits) => mean([
        for (final outfit in outfits.skip(6))
          TasteModel.score(weights, features.of(outfit)),
      ]);
      expect(liking(loved, dresses), greaterThan(liking(loved, others)));
      final unloved = TasteModel.learn(
        [
          for (final outfit in dresses.take(6))
            _signal(
              'u-${outfit.id}',
              TasteSignalKind.unloved,
              outfit: outfit.id,
            ),
        ],
        features: features,
        catalog: byId,
      ).mean();
      expect(liking(unloved, dresses), lessThan(liking(unloved, others)));
    });

    test('a heart toggled again and again counts once, as it was left', () {
      final outfit = catalog.first.id;
      TasteSignal heart(String id, TasteSignalKind kind, int minute) =>
          TasteSignal(
            id: id,
            kind: kind,
            at: DateTime.utc(2026, 10, 19, 9, minute),
            outfitId: outfit,
          );
      List<double> learnt(List<TasteSignal> signals) =>
          TasteModel.learn(signals, features: features, catalog: byId).mean();
      expect(
        learnt([
          heart('a', TasteSignalKind.loved, 3),
          heart('b', TasteSignalKind.unloved, 1),
          heart('c', TasteSignalKind.loved, 2),
        ]),
        learnt([heart('a', TasteSignalKind.loved, 3)]),
      );
      expect(
        learnt([
          heart('a', TasteSignalKind.picked, 1),
          heart('b', TasteSignalKind.unloved, 2),
        ]),
        learnt([heart('b', TasteSignalKind.unloved, 2)]),
      );
    });

    test('a wardrobe of navy lifts navy outfits; unknown outfits teach '
        'nothing', () {
      final weights = TasteModel.learn(
        [
          for (var i = 0; i < 5; i++)
            _signal('w$i', TasteSignalKind.wardrobe, families: {'navy'}),
          _signal('gone', TasteSignalKind.loved, outfit: 'o9999'),
        ],
        features: features,
        catalog: byId,
      ).mean();
      bool navy(CatalogOutfit outfit) =>
          outfit.pieces.every((piece) => piece.family == 'navy');
      final navyLiking = mean([
        for (final outfit in catalog.where(navy))
          TasteModel.score(weights, features.of(outfit)),
      ]);
      final rest = mean([
        for (final outfit in catalog.where((outfit) => !navy(outfit)))
          TasteModel.score(weights, features.of(outfit)),
      ]);
      expect(navyLiking, greaterThan(rest));
    });

    test('draws scatter around what was learnt, never wildly', () {
      final model = TasteModel.prior();
      final scores = [
        for (var seed = 0; seed < 50; seed++)
          TasteModel.score(model.draw(Random(seed)), features.of(catalog[7])),
      ];
      expect(scores, everyElement(inInclusiveRange(0.05, 0.95)));
    });
  });

  group('TasteRepositoryImpl', () {
    late MemoryStore phone;
    late FakeFirebaseFirestore firestore;
    TasteRepositoryImpl repository([MemoryStore? store]) => TasteRepositoryImpl(
      local: TasteLocalDataSourceImpl(store ?? phone),
      remote: TasteRemoteDataSourceImpl(firestore),
      logMessages: LogMessagesImpl(),
    );
    Future<List<String>> ids(TasteRepositoryImpl taste) async => [
      for (final signal in (await taste.signals()).getOrElse(() => const []))
        signal.id,
    ];

    setUp(() {
      phone = MemoryStore();
      firestore = FakeFirebaseFirestore();
    });

    test('keeps each signal once, on the phone', () async {
      final taste = repository();
      await taste.keep(_signal('a', TasteSignalKind.loved, outfit: 'o1'));
      await taste.keep(_signal('a', TasteSignalKind.loved, outfit: 'o1'));
      await taste.keep(
        _signal('b', TasteSignalKind.wardrobe, families: {'navy'}),
      );
      expect(await ids(repository()), ['a', 'b']);
      final read = (await taste.signals()).getOrElse(() => const []);
      expect(read.last.families, {'navy'});
    });

    test('two phones meet on the account, each signal once', () async {
      final first = repository();
      final second = repository(MemoryStore());
      await first.keep(_signal('a', TasteSignalKind.picked, outfit: 'o1'));
      await first.save('uid-1');
      await second.keep(_signal('b', TasteSignalKind.loved, outfit: 'o2'));
      await second.restore('uid-1');
      await second.save('uid-1');
      await first.restore('uid-1');
      expect(await ids(first), ['a', 'b']);
      expect(await ids(second), ['b', 'a']);
      final state = await firestore.doc('users/uid-1/stylist/state').get();
      expect((state.data()!['signals'] as List), hasLength(2));
      expect(state.data()!['version'], 1);
    });

    test('a signal kept while the account’s are read stays', () async {
      final other = repository(MemoryStore());
      await other.keep(_signal('a', TasteSignalKind.picked, outfit: 'o1'));
      await other.save('uid-1');
      final taste = repository();
      final restoring = taste.restore('uid-1');
      await taste.keep(_signal('b', TasteSignalKind.loved, outfit: 'o2'));
      await restoring;
      expect(await ids(taste), ['b', 'a']);
    });

    test('a save sends only what the account doesn’t have yet', () async {
      final remote = _RecordingRemote(TasteRemoteDataSourceImpl(firestore));
      TasteRepositoryImpl phoneWith(MemoryStore store) => TasteRepositoryImpl(
        local: TasteLocalDataSourceImpl(store),
        remote: remote,
        logMessages: LogMessagesImpl(),
      );
      final other = phoneWith(MemoryStore());
      await other.keep(_signal('a', TasteSignalKind.picked, outfit: 'o1'));
      await other.save('uid-1');
      final taste = phoneWith(phone);
      await taste.restore('uid-1');
      await taste.keep(_signal('b', TasteSignalKind.loved, outfit: 'o2'));
      remote.offline = true;
      await taste.save('uid-1');
      await taste.save('uid-1');
      await taste.keep(_signal('c', TasteSignalKind.kept, outfit: 'o3'));
      await taste.save('uid-1');
      await taste.save('uid-1');
      expect(remote.sent, [
        ['a'],
        ['b'],
        ['c'],
      ]);
      await taste.clear();
      await taste.keep(_signal('c', TasteSignalKind.kept, outfit: 'o3'));
      await taste.save('uid-1');
      expect(remote.sent.last, ['c']);
    });

    test(
      'log out forgets the phone’s copy; the account keeps its own',
      () async {
        final taste = repository();
        await taste.keep(_signal('a', TasteSignalKind.loved, outfit: 'o1'));
        await taste.save('uid-1');
        await taste.clear();
        expect(await ids(taste), isEmpty);
        await taste.restore('uid-1');
        expect(await ids(taste), ['a']);
      },
    );

    test('reads past a signal it doesn’t know', () {
      expect(
        TasteSignalModel.fromJson({
          'id': 'x',
          'kind': 'shrugged',
          'at': '2026',
        }),
        isNull,
      );
      final signal = _signal('a', TasteSignalKind.bought, outfit: 'o1');
      expect(
        TasteSignalModel.fromJson(TasteSignalModel.toJson(signal)),
        signal,
      );
    });
  });

  group('RecordSignal', () {
    test(
      'keeps the signal on the phone, and on the account when signed in',
      () async {
        final taste = MemoryTaste();
        await recordSignalInto(taste)(_signal('a', TasteSignalKind.loved));
        expect(taste.phone, hasLength(1));
        expect(taste.saves, isEmpty);
        await recordSignalInto(taste, accountId: 'uid-1')(
          _signal('b', TasteSignalKind.loved),
        );
        expect(taste.saves, ['uid-1']);
        expect(taste.accounts['uid-1'], hasLength(2));
      },
    );
  });
}
