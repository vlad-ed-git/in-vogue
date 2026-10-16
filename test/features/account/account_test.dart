import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/account/data/data_sources/account_remote_data_source.dart';
import 'package:in_vogue/features/account/data/models/account_model.dart';
import 'package:in_vogue/features/account/data/repositories/account_repository_impl.dart';
import 'package:in_vogue/features/account/domain/entities/account_setup.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/ensure_account.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
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
);

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
      expect(AccountModel.contentType('/a/body-1.jpg'), 'image/jpeg');
      expect(AccountModel.contentType('/a/body-1.JPEG'), 'image/jpeg');
      expect(AccountModel.contentType('/a/face-1.png'), 'image/png');
      expect(AccountModel.contentType('/a/face-1.heic'), 'image/heic');
    });

    test('gives a new account the demo plan, and only a new one', () {
      final photos = {
        PhotoRole.body: (path: 'users/u/body-2.jpg', revision: 2),
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
          'body': {'path': 'users/u/body-2.jpg', 'revision': 2},
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

    test('reads the photos an account document records', () {
      expect(
        AccountModel.photosFromJson({
          'photos': {
            'body': {'path': 'users/u/body-1.jpg', 'revision': 1},
            'face': {'path': 7},
          },
        }),
        {PhotoRole.body: (path: 'users/u/body-1.jpg', revision: 1)},
      );
      expect(AccountModel.photosFromJson(null), isEmpty);
    });
  });

  group('AccountRepositoryImpl', () {
    late MockAccountRemoteDataSource remote;
    late AccountRepositoryImpl repository;

    setUp(() {
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
      ).thenAnswer((_) async {});
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

    test('creates a new account with its photos, picks and plan', () async {
      expect(
        await repository.save('uid-1', _setup),
        const Right<Failure, Unit>(unit),
      );
      verify(
        remote.uploadPhoto(
          path: 'users/uid-1/photos/body-2.jpg',
          file: '/support/photos/body-2.jpg',
          contentType: 'image/jpeg',
        ),
      ).called(1);
      verify(
        remote.uploadPhoto(
          path: 'users/uid-1/photos/face-1.png',
          file: '/support/photos/face-1.png',
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
      final written = verify(
        remote.writeAccount('uid-1', captureAny, created: true),
      ).captured.single;
      expect(written, containsPair('plan', 'pro'));
      expect(written, containsPair('name', 'Maya'));
      verifyNever(remote.deletePhoto(any));
    });

    test('uploads nothing the account already holds', () async {
      when(remote.readAccount(any)).thenAnswer(
        (_) async => {
          'plan': 'pro',
          'photos': {
            'body': {'path': 'users/uid-1/photos/body-2.jpg', 'revision': 2},
            'face': {'path': 'users/uid-1/photos/face-1.png', 'revision': 1},
          },
        },
      );
      when(
        remote.wishlist(any),
      ).thenAnswer((_) async => {'everlane:a', 'everlane:b'});
      expect(
        await repository.save('uid-1', _setup),
        const Right<Failure, Unit>(unit),
      );
      verifyNever(
        remote.uploadPhoto(
          path: anyNamed('path'),
          file: anyNamed('file'),
          contentType: anyNamed('contentType'),
        ),
      );
      verifyNever(
        remote.writeWishlist(
          any,
          add: anyNamed('add'),
          remove: anyNamed('remove'),
        ),
      );
      final written = verify(
        remote.writeAccount('uid-1', captureAny, created: false),
      ).captured.single;
      expect(written, isNot(contains('plan')));
    });

    test(
      'replaces a photo of another revision and deletes the old one',
      () async {
        when(remote.readAccount(any)).thenAnswer(
          (_) async => {
            'photos': {
              'body': {'path': 'users/uid-1/photos/body-1.jpg', 'revision': 1},
            },
          },
        );
        await repository.save('uid-1', const AccountSetup(body: _body));
        verifyInOrder([
          remote.uploadPhoto(
            path: 'users/uid-1/photos/body-2.jpg',
            file: '/support/photos/body-2.jpg',
            contentType: 'image/jpeg',
          ),
          remote.writeAccount('uid-1', any, created: false),
          remote.deletePhoto('users/uid-1/photos/body-1.jpg'),
        ]);
      },
    );

    test('mirrors the picks: adds new ones, removes unloved ones', () async {
      when(
        remote.wishlist(any),
      ).thenAnswer((_) async => {'everlane:b', 'everlane:c'});
      await repository.save('uid-1', _setup);
      verify(
        remote.writeWishlist(
          'uid-1',
          add: {'everlane:a'},
          remove: {'everlane:c'},
        ),
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
        await repository.save('uid-1', const AccountSetup(body: _body)),
        const Right<Failure, Unit>(unit),
      );
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
        await repository.save('uid-1', _setup),
        const Left<Failure, Unit>(NetworkFailure()),
      );
      when(
        remote.readAccount(any),
      ).thenThrow(ServerException(Exception('denied'), StackTrace.current));
      expect(
        await repository.save('uid-1', _setup),
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
        account.save(any, any),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    });

    test('saves what the phone keeps on the account', () async {
      expect(await save('uid-1'), const Right<Failure, Unit>(unit));
      verify(account.save('uid-1', _setup)).called(1);
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
