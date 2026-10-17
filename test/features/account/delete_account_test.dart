import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';
import 'package:in_vogue/features/account/domain/usecases/delete_account.dart';
import 'package:in_vogue/features/account/presentation/bloc/delete_account_bloc.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_job_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'delete_account_test.mocks.dart';

const _done = Right<Failure, Unit>(unit);

@GenerateMocks([
  AuthRepository,
  AccountRepository,
  PhotoRepository,
  PicksRepository,
  ProfileRepository,
  LocationRepository,
  DayRepository,
  TryOnJobRepository,
  MakeupRepository,
  MakeupJobRepository,
])
void main() {
  late MockAuthRepository auth;
  late MockAccountRepository account;
  late MockPhotoRepository photos;
  late MockPicksRepository picks;
  late MockProfileRepository profile;
  late MockLocationRepository location;
  late MockDayRepository days;
  late MockTryOnJobRepository jobs;
  late MockMakeupRepository makeup;
  late MockMakeupJobRepository makeupJobs;
  late DeleteAccount delete;

  setUp(() {
    auth = MockAuthRepository();
    account = MockAccountRepository();
    photos = MockPhotoRepository();
    picks = MockPicksRepository();
    profile = MockProfileRepository();
    location = MockLocationRepository();
    days = MockDayRepository();
    jobs = MockTryOnJobRepository();
    makeup = MockMakeupRepository();
    makeupJobs = MockMakeupJobRepository();
    delete = DeleteAccount(
      auth: auth,
      account: account,
      photos: photos,
      picks: picks,
      profile: profile,
      location: location,
      days: days,
      jobs: jobs,
      makeup: makeup,
      makeupJobs: makeupJobs,
    );
    when(
      auth.currentAccount(),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
    when(auth.reauthenticate()).thenAnswer((_) async => _done);
    when(account.delete(any)).thenAnswer((_) async => _done);
    when(auth.deleteUser()).thenAnswer((_) async => _done);
    when(photos.forget(any)).thenAnswer((_) async => _done);
    when(picks.clear()).thenAnswer((_) async => _done);
    when(profile.clearName()).thenAnswer((_) async => _done);
    when(location.forget()).thenAnswer((_) async => _done);
    when(days.forgetPictures(any)).thenAnswer((_) async => _done);
    when(jobs.clearAccount(any)).thenAnswer((_) async => _done);
    when(makeup.forgetPictures(any)).thenAnswer((_) async => _done);
    when(makeupJobs.clearAccount(any)).thenAnswer((_) async => _done);
  });

  void verifyPhoneKept() {
    verifyNever(photos.forget(any));
    verifyNever(picks.clear());
    verifyNever(profile.clearName());
    verifyNever(location.forget());
    verifyNever(days.forgetPictures(any));
    verifyNever(makeup.forgetPictures(any));
  }

  test(
    'confirms, deletes the server data, the account, then the phone',
    () async {
      expect(await delete(const NoParams()), _done);
      verifyInOrder([
        auth.reauthenticate(),
        account.delete('uid-1'),
        auth.deleteUser(),
        photos.forget(PhotoRole.body),
        photos.forget(PhotoRole.face),
        picks.clear(),
        profile.clearName(),
        location.forget(),
        days.forgetPictures('uid-1'),
        jobs.clearAccount('uid-1'),
        makeup.forgetPictures('uid-1'),
        makeupJobs.clearAccount('uid-1'),
      ]);
    },
  );

  test('deletes nothing when the person does not confirm', () async {
    when(auth.reauthenticate()).thenAnswer(
      (_) async => const Left(SignInFailure(SignInProblem.cancelled)),
    );
    expect(
      await delete(const NoParams()),
      const Left<Failure, Unit>(SignInFailure(SignInProblem.cancelled)),
    );
    verifyNever(account.delete(any));
    verifyNever(auth.deleteUser());
    verifyPhoneKept();
  });

  test('keeps the account and the phone when the server data stays', () async {
    when(
      account.delete(any),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    expect(
      await delete(const NoParams()),
      const Left<Failure, Unit>(NetworkFailure()),
    );
    verifyNever(auth.deleteUser());
    verifyPhoneKept();
  });

  test('keeps the phone when the account cannot be deleted', () async {
    when(
      auth.deleteUser(),
    ).thenAnswer((_) async => const Left(SignInFailure(SignInProblem.failed)));
    await delete(const NoParams());
    verifyPhoneKept();
  });

  group('DeleteAccountBloc', () {
    blocTest<DeleteAccountBloc, DeleteAccountState>(
      'deletes the account once confirmed',
      build: () => DeleteAccountBloc(deleteAccount: delete),
      act: (bloc) => bloc.add(const DeleteAccountConfirmed()),
      expect: () => [
        const DeleteAccountState(status: DeleteAccountStatus.deleting),
        const DeleteAccountState(status: DeleteAccountStatus.deleted),
      ],
    );

    blocTest<DeleteAccountBloc, DeleteAccountState>(
      'goes back quietly when the provider sheet is closed',
      build: () {
        when(auth.reauthenticate()).thenAnswer(
          (_) async => const Left(SignInFailure(SignInProblem.cancelled)),
        );
        return DeleteAccountBloc(deleteAccount: delete);
      },
      act: (bloc) => bloc.add(const DeleteAccountConfirmed()),
      expect: () => [
        const DeleteAccountState(status: DeleteAccountStatus.deleting),
        const DeleteAccountState(),
      ],
    );

    blocTest<DeleteAccountBloc, DeleteAccountState>(
      'says why the account was not deleted',
      build: () {
        when(
          account.delete(any),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return DeleteAccountBloc(deleteAccount: delete);
      },
      act: (bloc) => bloc.add(const DeleteAccountConfirmed()),
      expect: () => [
        const DeleteAccountState(status: DeleteAccountStatus.deleting),
        const DeleteAccountState(failure: NetworkFailure()),
      ],
    );
  });
}
