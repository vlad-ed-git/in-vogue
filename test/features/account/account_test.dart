import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:in_vogue/features/account/data/models/account_model.dart';
import 'package:in_vogue/features/account/data/repositories/account_repository_impl.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/ensure_account.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
import 'package:in_vogue/features/photos/data/photo_content_type.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../auth/sign_in_bloc_test.mocks.dart';
import 'account_test.mocks.dart';

const _paris = UserLocation(
  latitude: 48.86,
  longitude: 2.35,
  city: 'Paris',
  countryCode: 'FR',
);
const _body = UserPhoto(
  role: PhotoRole.body,
  path: '/support/photos/body-2.jpg',
  revision: 2,
);
const _face = UserPhoto(
  role: PhotoRole.face,
  path: '/support/photos/face-1.png',
  revision: 1,
);
const _setup = AccountSetup(
  name: 'Maya',
  location: _paris,
  body: _body,
  face: _face,
  picks: {'everlane:a', 'everlane:b'},
  syncedPicks: {'everlane:b', 'everlane:c'},
);

String _sha256(String content) =>
    sha256.convert(utf8.encode(content)).toString();

@GenerateMocks([
  AccountRemoteDataSource,
  AccountRepository,
  ProfileRepository,
  LocationRepository,
  PhotoRepository,
  PicksRepository,
])
void main() {
  group('AccountModel', () {
    test('keeps photos under the account by their file names', () {
      expect(
        AccountModel.photoPath('uid-1', _body),
        'users/uid-1/photos/body-2.jpg',
      );
    });

    test('names the image type from the extension', () {
      expect(photoContentType('/a/body-1.jpg'), 'image/jpeg');
      expect(photoContentType('/a/body-1.JPEG'), 'image/jpeg');
      expect(photoContentType('/a/face-1.png'), 'image/png');
      expect(photoContentType('/a/face-1.heic'), 'image/heic');
    });

    test('gives a new account the demo plan, and only a new one', () {
      final photos = {
        PhotoRole.body: (
          path: 'users/u/body-2.jpg',
          revision: 2,
          url: 'https://storage.example/body-2.jpg',
          sha256: 'b2',
        ),
      };
      final created = AccountModel.toJson(
        _setup,
        photos: photos,
        created: true,
      );
      expect(created, {
        'name': 'Maya',
        'location': {
          'city': 'Paris',
          'countryCode': 'FR',
          'latitude': 48.86,
          'longitude': 2.35,
        },
        'photos': {
          'body': {
            'path': 'users/u/body-2.jpg',
            'revision': 2,
            'url': 'https://storage.example/body-2.jpg',
            'sha256': 'b2',
          },
        },
        'plan': 'pro',
      });
      expect(
        AccountModel.toJson(_setup, photos: photos, created: false),
        isNot(contains('plan')),
      );
    });

    test('leaves out what the phone does not know yet', () {
      expect(
        AccountModel.toJson(const AccountSetup(), photos: {}, created: false),
        isEmpty,
      );
    });

    test('reads the plan an account document records', () {
      expect(AccountModel.planFromJson({'plan': 'pro'}), AccountPlan.pro);
      expect(AccountModel.planFromJson({'plan': 'free'}), AccountPlan.free);
      expect(AccountModel.planFromJson({'plan': 'gold'}), isNull);
      expect(AccountModel.planFromJson(null), isNull);
    });

    test('reads the photos an account document records', () {
      expect(
        AccountModel.photosFromJson({
          'photos': {
            'body': {'path': 'users/u/body-1.jpg', 'revision': 1},
            'face': {'path': 7},
          },
        }),
        {
          PhotoRole.body: (
            path: 'users/u/body-1.jpg',
            revision: 1,
            url: null,
            sha256: null,
          ),
        },
      );
      expect(
        AccountModel.photosFromJson({
          'photos': {
            'face': {
              'path': 'users/u/face-2.png',
              'revision': 2,
              'url': 'https://storage.example/face-2.png',
              'sha256': 'f2',
            },
          },
        }),
        {
          PhotoRole.face: (
            path: 'users/u/face-2.png',
            revision: 2,
            url: 'https://storage.example/face-2.png',
            sha256: 'f2',
          ),
        },
      );
      expect(AccountModel.photosFromJson(null), isEmpty);
    });
  });

  group('AccountRepositoryImpl', () {
    late MockAccountRemoteDataSource remote;
    late AccountRepositoryImpl repository;
    late UserPhoto body;
    late UserPhoto face;
    late AccountSetup setup;
    final bodySha = _sha256('body two');
    final faceSha = _sha256('face one');

    setUp(() {
      final phone = Directory.systemTemp.createTempSync('photos');
      addTearDown(() => phone.deleteSync(recursive: true));
      body = UserPhoto(
        role: PhotoRole.body,
        path: (File(
          '${phone.path}/body-2.jpg',
        )..writeAsStringSync('body two')).path,
        revision: 2,
      );
      face = UserPhoto(
        role: PhotoRole.face,
        path: (File(
          '${phone.path}/face-1.png',
        )..writeAsStringSync('face one')).path,
        revision: 1,
      );
      setup = AccountSetup(
        name: 'Maya',
        location: _paris,
        body: body,
        face: face,
        picks: const {'everlane:a', 'everlane:b'},
      );
      remote = MockAccountRemoteDataSource();
      repository = AccountRepositoryImpl(
        remoteDataSource: remote,
        logMessages: LogMessagesImpl(),
      );
      when(remote.readAccount(any)).thenAnswer((_) async => null);
      when(remote.wishlist(any)).thenAnswer((_) async => {});
      when(
        remote.uploadPhoto(
          path: anyNamed('path'),
          file: anyNamed('file'),
          contentType: anyNamed('contentType'),
        ),
      ).thenAnswer(
        (invocation) async =>
            'https://storage.example/${invocation.namedArguments[#path]}',
      );
      when(remote.photoUrl(any)).thenAnswer(
        (invocation) async =>
            'https://storage.example/${invocation.positionalArguments.first}',
      );
      when(
        remote.writeWishlist(
          any,
          add: anyNamed('add'),
          remove: anyNamed('remove'),
        ),
      ).thenAnswer((_) async {});
      when(
        remote.writeAccount(any, any, created: anyNamed('created')),
      ).thenAnswer((_) async {});
      when(remote.deletePhoto(any)).thenAnswer((_) async {});
    });

    void verifyNoUpload() => verifyNever(
      remote.uploadPhoto(
        path: anyNamed('path'),
        file: anyNamed('file'),
        contentType: anyNamed('contentType'),
      ),
    );

    Map<String, Object?> written({required bool created}) =>
        verify(
              remote.writeAccount('uid-1', captureAny, created: created),
            ).captured.single
            as Map<String, Object?>;

    test('creates a new account with its photos, picks and plan', () async {
      expect(
        await repository.save('uid-1', setup),
        const Right<Failure, Unit>(unit),
      );
      verify(
        remote.uploadPhoto(
          path: 'users/uid-1/photos/body-2.jpg',
          file: body.path,
          contentType: 'image/jpeg',
        ),
      ).called(1);
      verify(
        remote.uploadPhoto(
          path: 'users/uid-1/photos/face-1.png',
          file: face.path,
          contentType: 'image/png',
        ),
      ).called(1);
      verify(
        remote.writeWishlist(
          'uid-1',
          add: {'everlane:a', 'everlane:b'},
          remove: <String>{},
        ),
      ).called(1);
      final account = written(created: true);
      expect(account, containsPair('plan', 'pro'));
      expect(account, containsPair('name', 'Maya'));
      expect(account['photos'], {
        'body': {
          'path': 'users/uid-1/photos/body-2.jpg',
          'revision': 2,
          'url': 'https://storage.example/users/uid-1/photos/body-2.jpg',
          'sha256': bodySha,
        },
        'face': {
          'path': 'users/uid-1/photos/face-1.png',
          'revision': 1,
          'url': 'https://storage.example/users/uid-1/photos/face-1.png',
          'sha256': faceSha,
        },
      });
      verifyNever(remote.deletePhoto(any));
    });

    test('uploads nothing the account already holds', () async {
      when(remote.readAccount(any)).thenAnswer(
        (_) async => {
          'plan': 'pro',
          'photos': {
            'body': {
              'path': 'users/uid-1/photos/body-2.jpg',
              'revision': 2,
              'url': 'https://kept.example/body-2.jpg',
              'sha256': bodySha,
            },
            // A photo restored on this phone keeps its place and number.
            'face': {
              'path': 'users/uid-1/photos/face-3.png',
              'revision': 3,
              'sha256': faceSha,
            },
          },
        },
      );
      when(
        remote.wishlist(any),
      ).thenAnswer((_) async => {'everlane:a', 'everlane:b'});
      expect(
        await repository.save('uid-1', setup),
        const Right<Failure, Unit>(unit),
      );
      verifyNoUpload();
      verifyNever(
        remote.writeWishlist(
          any,
          add: anyNamed('add'),
          remove: anyNamed('remove'),
        ),
      );
      final account = written(created: false);
      expect(account, isNot(contains('plan')));
      // A kept URL stays; one missing from an earlier save is looked up.
      expect(account['photos'], {
        'body': {
          'path': 'users/uid-1/photos/body-2.jpg',
          'revision': 2,
          'url': 'https://kept.example/body-2.jpg',
          'sha256': bodySha,
        },
        'face': {
          'path': 'users/uid-1/photos/face-3.png',
          'revision': 3,
          'url': 'https://storage.example/users/uid-1/photos/face-3.png',
          'sha256': faceSha,
        },
      });
      verifyNever(remote.deletePhoto(any));
    });

    test('replaces a photo whose content changed, even under the same name, '
        'as after a reinstall', () async {
      when(remote.readAccount(any)).thenAnswer(
        (_) async => {
          'photos': {
            'body': {
              'path': 'users/uid-1/photos/body-2.jpg',
              'revision': 2,
              'sha256': _sha256('an older body photo'),
            },
          },
        },
      );
      await repository.save('uid-1', AccountSetup(body: body));
      verify(
        remote.uploadPhoto(
          path: 'users/uid-1/photos/body-2.jpg',
          file: body.path,
          contentType: 'image/jpeg',
        ),
      ).called(1);
      verifyNever(remote.deletePhoto(any));
    });

    test('uploads once a photo saved before fingerprints', () async {
      when(remote.readAccount(any)).thenAnswer(
        (_) async => {
          'photos': {
            'body': {'path': 'users/uid-1/photos/body-2.jpg', 'revision': 2},
          },
        },
      );
      await repository.save('uid-1', AccountSetup(body: body));
      final photos =
          written(created: false)['photos']! as Map<Object?, Object?>;
      expect(photos['body'], containsPair('sha256', bodySha));
    });

    test(
      'replaces a photo under another name and deletes the old one',
      () async {
        when(remote.readAccount(any)).thenAnswer(
          (_) async => {
            'photos': {
              'body': {
                'path': 'users/uid-1/photos/body-1.jpg',
                'revision': 1,
                'sha256': _sha256('an older body photo'),
              },
            },
          },
        );
        await repository.save('uid-1', AccountSetup(body: body));
        verifyInOrder([
          remote.uploadPhoto(
            path: 'users/uid-1/photos/body-2.jpg',
            file: body.path,
            contentType: 'image/jpeg',
          ),
          remote.writeAccount('uid-1', any, created: false),
          remote.deletePhoto('users/uid-1/photos/body-1.jpg'),
        ]);
      },
    );

    test('adds new picks, and removes only those this phone unloved', () async {
      when(
        remote.wishlist(any),
      ).thenAnswer((_) async => {'everlane:b', 'everlane:c', 'everlane:d'});
      await repository.save(
        'uid-1',
        const AccountSetup(
          picks: {'everlane:a', 'everlane:b'},
          syncedPicks: {'everlane:b', 'everlane:c'},
        ),
      );
      verify(
        remote.writeWishlist(
          'uid-1',
          add: {'everlane:a'},
          remove: {'everlane:c'},
        ),
      ).called(1);
    });

    test('never removes a favourite from a phone that has not saved it, as '
        'after a reinstall', () async {
      when(
        remote.wishlist(any),
      ).thenAnswer((_) async => {'everlane:b', 'everlane:c'});
      await repository.save('uid-1', const AccountSetup(picks: {'everlane:a'}));
      verify(
        remote.writeWishlist('uid-1', add: {'everlane:a'}, remove: <String>{}),
      ).called(1);
    });

    test('is saved even when an old photo cannot be deleted', () async {
      when(remote.readAccount(any)).thenAnswer(
        (_) async => {
          'photos': {
            'body': {'path': 'users/uid-1/photos/body-1.jpg', 'revision': 1},
          },
        },
      );
      when(
        remote.deletePhoto(any),
      ).thenThrow(ServerException(Exception('gone'), StackTrace.current));
      expect(
        await repository.save('uid-1', AccountSetup(body: body)),
        const Right<Failure, Unit>(unit),
      );
    });

    test('says when a photo cannot be read on the phone', () async {
      expect(
        await repository.save(
          'uid-1',
          const AccountSetup(
            body: UserPhoto(
              role: PhotoRole.body,
              path: '/nowhere/body-9.jpg',
              revision: 9,
            ),
          ),
        ),
        const Left<Failure, Unit>(CacheFailure()),
      );
      verifyNever(remote.writeAccount(any, any, created: anyNamed('created')));
    });

    test('knows whether the account has been saved', () async {
      expect(
        await repository.exists('uid-1'),
        const Right<Failure, bool>(false),
      );
      when(remote.readAccount(any)).thenAnswer((_) async => {'plan': 'pro'});
      expect(
        await repository.exists('uid-1'),
        const Right<Failure, bool>(true),
      );
    });

    test('says when it is offline or the server refuses', () async {
      when(
        remote.readAccount(any),
      ).thenThrow(NetworkException(Exception('offline'), StackTrace.current));
      expect(
        await repository.save('uid-1', setup),
        const Left<Failure, Unit>(NetworkFailure()),
      );
      when(
        remote.readAccount(any),
      ).thenThrow(ServerException(Exception('denied'), StackTrace.current));
      expect(
        await repository.save('uid-1', setup),
        const Left<Failure, Unit>(ServerFailure()),
      );
    });
  });

  group('SaveSetupToAccount', () {
    late MockAccountRepository account;
    late MockProfileRepository profile;
    late MockLocationRepository location;
    late MockPhotoRepository photos;
    late MockPicksRepository picks;
    late SaveSetupToAccount save;

    setUp(() {
      account = MockAccountRepository();
      profile = MockProfileRepository();
      location = MockLocationRepository();
      photos = MockPhotoRepository();
      picks = MockPicksRepository();
      save = SaveSetupToAccount(
        account: account,
        profile: profile,
        location: location,
        photos: photos,
        picks: picks,
      );
      when(profile.name()).thenAnswer((_) async => const Right('Maya'));
      when(
        location.savedLocation(),
      ).thenAnswer((_) async => const Right(_paris));
      when(
        photos.kept(PhotoRole.body),
      ).thenAnswer((_) async => const Right(_body));
      when(
        photos.kept(PhotoRole.face),
      ).thenAnswer((_) async => const Right(_face));
      when(
        picks.picks(),
      ).thenAnswer((_) async => const Right({'everlane:a', 'everlane:b'}));
      when(
        picks.synced('uid-1'),
      ).thenAnswer((_) async => const Right({'everlane:b', 'everlane:c'}));
      when(
        picks.markSynced(any, any),
      ).thenAnswer((_) async => const Right(unit));
      when(
        account.save(any, any),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    });

    test('saves what the phone keeps on the account, and records the picks '
        'saved', () async {
      expect(await save('uid-1'), const Right<Failure, Unit>(unit));
      verifyInOrder([
        account.save('uid-1', _setup),
        picks.markSynced('uid-1', {'everlane:a', 'everlane:b'}),
      ]);
    });

    test('records no picks as saved when the save fails', () async {
      when(
        account.save(any, any),
      ).thenAnswer((_) async => const Left<Failure, Unit>(NetworkFailure()));
      expect(await save('uid-1'), const Left<Failure, Unit>(NetworkFailure()));
      verifyNever(picks.markSynced(any, any));
    });

    test(
      'saves what is known so far, before the name and face photo',
      () async {
        when(profile.name()).thenAnswer((_) async => const Right(null));
        when(
          photos.kept(PhotoRole.face),
        ).thenAnswer((_) async => const Right(null));
        await save('uid-1');
        verify(
          account.save(
            'uid-1',
            const AccountSetup(
              location: _paris,
              body: _body,
              picks: {'everlane:a', 'everlane:b'},
              syncedPicks: {'everlane:b', 'everlane:c'},
            ),
          ),
        ).called(1);
      },
    );

    test('saves nothing when the phone cannot read its setup', () async {
      when(picks.picks()).thenAnswer(
        (_) async => const Left<Failure, Set<String>>(CacheFailure()),
      );
      expect(await save('uid-1'), const Left<Failure, Unit>(CacheFailure()));
      verifyNever(account.save(any, any));
    });
  });

  group('EnsureAccount', () {
    late MockAuthRepository auth;
    late MockAccountRepository account;
    late MockSaveSetupToAccount saveSetup;
    late EnsureAccount ensure;

    setUp(() {
      auth = MockAuthRepository();
      account = MockAccountRepository();
      saveSetup = MockSaveSetupToAccount();
      ensure = EnsureAccount(
        auth: auth,
        account: account,
        saveSetupToAccount: saveSetup,
      );
      when(
        auth.currentAccount(),
      ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
      when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
    });

    test("saves the phone's setup when the account was never saved", () async {
      when(
        account.exists(any),
      ).thenAnswer((_) async => const Right<Failure, bool>(false));
      expect(await ensure(const NoParams()), const Right<Failure, Unit>(unit));
      verify(saveSetup('uid-1')).called(1);
    });

    test('leaves a saved account as it is', () async {
      when(
        account.exists(any),
      ).thenAnswer((_) async => const Right<Failure, bool>(true));
      await ensure(const NoParams());
      verifyNever(saveSetup(any));
    });

    test('does nothing when nobody is signed in', () async {
      when(auth.currentAccount()).thenAnswer((_) async => const Right(null));
      await ensure(const NoParams());
      verifyNever(account.exists(any));
      verifyNever(saveSetup(any));
    });

    test('saves nothing when it cannot tell', () async {
      when(
        account.exists(any),
      ).thenAnswer((_) async => const Left<Failure, bool>(NetworkFailure()));
      expect(
        await ensure(const NoParams()),
        const Left<Failure, Unit>(NetworkFailure()),
      );
      verifyNever(saveSetup(any));
    });
  });
}
