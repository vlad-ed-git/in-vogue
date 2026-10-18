import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'account_remote_data_source_test.mocks.dart';

/// Everything the app keeps under an account document.
const _collections = [
  'wishlist',
  'days',
  'suggestions',
  'makeupLooks',
  'colorProfiles',
  'tryOns',
];

MockListResult _listed({
  List<Reference> items = const [],
  List<Reference> prefixes = const [],
}) {
  final listed = MockListResult();
  when(listed.items).thenReturn(items);
  when(listed.prefixes).thenReturn(prefixes);
  return listed;
}

@GenerateMocks([FirebaseStorage, Reference, ListResult])
void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorage storage;
  late AccountRemoteDataSourceImpl remote;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    storage = MockFirebaseStorage();
    remote = AccountRemoteDataSourceImpl(
      firestore: firestore,
      storage: storage,
    );
  });

  test('deletes the account, everything under it and its files, and no one '
      "else's", () async {
    final account = firestore.doc('users/uid-1');
    await account.set({'name': 'Ada'});
    // More days than one batch deletes.
    final batch = firestore.batch();
    for (var day = 0; day < AccountRemoteDataSourceImpl.batchSize + 50; day++) {
      batch.set(account.collection('days').doc('day-$day'), {
        'status': 'ready',
      });
    }
    await batch.commit();
    for (final name in _collections) {
      await account.collection(name).doc('one').set({'kept': true});
    }
    final someoneElse = firestore.doc('users/uid-2/days/2026-10-17_work');
    await someoneElse.set({'status': 'ready'});

    final folder = MockReference();
    final days = MockReference();
    final photo = MockReference();
    final picture = MockReference();
    final top = _listed(items: [photo], prefixes: [days]);
    final inDays = _listed(items: [picture]);
    when(storage.ref('users/uid-1')).thenReturn(folder);
    when(folder.listAll()).thenAnswer((_) async => top);
    when(days.listAll()).thenAnswer((_) async => inDays);
    when(photo.delete()).thenAnswer((_) async {});
    when(picture.delete()).thenAnswer((_) async {});

    await remote.deleteAccount('uid-1');

    expect((await account.get()).exists, isFalse);
    for (final name in _collections) {
      expect(
        (await account.collection(name).get()).docs,
        isEmpty,
        reason: name,
      );
    }
    expect((await someoneElse.get()).exists, isTrue);
    verify(photo.delete()).called(1);
    verify(picture.delete()).called(1);
  });

  test('downloads a photo, or says there is none', () async {
    final face = MockReference();
    when(storage.ref('users/uid-1/photos/face-2.png')).thenReturn(face);
    when(
      face.getData(any),
    ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
    expect(await remote.downloadPhoto('users/uid-1/photos/face-2.png'), [
      1,
      2,
      3,
    ]);
    verify(face.getData(AccountRemoteDataSourceImpl.maxPhotoBytes)).called(1);
    when(face.getData(any)).thenAnswer((_) async => null);
    await expectLater(
      remote.downloadPhoto('users/uid-1/photos/face-2.png'),
      throwsA(isA<ServerException>()),
    );
  });
}
