import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';
import 'package:in_vogue/features/auth/domain/usecases/log_out.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_job_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'log_out_test.mocks.dart';

const _done = Right<Failure, Unit>(unit);

@GenerateMocks([
  AuthRepository,
  ProfileRepository,
  DayRepository,
  MakeupRepository,
  MakeupJobRepository,
  HomeWidgetRepository,
])
void main() {
  late MockAuthRepository auth;
  late MockProfileRepository profile;
  late MockDayRepository days;
  late MockMakeupRepository makeup;
  late MockMakeupJobRepository makeupJobs;
  late MockHomeWidgetRepository widget;
  late LogOut logOut;

  setUp(() {
    auth = MockAuthRepository();
    profile = MockProfileRepository();
    days = MockDayRepository();
    makeup = MockMakeupRepository();
    makeupJobs = MockMakeupJobRepository();
    widget = MockHomeWidgetRepository();
    logOut = LogOut(
      auth: auth,
      profile: profile,
      days: days,
      makeup: makeup,
      makeupJobs: makeupJobs,
      widget: widget,
    );
    when(
      auth.currentAccount(),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
    when(auth.signOut()).thenAnswer((_) async => _done);
    when(profile.clearName()).thenAnswer((_) async => _done);
    when(days.forgetPictures(any)).thenAnswer((_) async => _done);
    when(makeup.forgetPictures(any)).thenAnswer((_) async => _done);
    when(makeupJobs.clearAccount(any)).thenAnswer((_) async => _done);
    when(widget.clear()).thenAnswer((_) async => _done);
  });

  test('signs out, then forgets the name and the account\'s outfit and '
      'makeup pictures', () async {
    expect(await logOut(const NoParams()), _done);
    verifyInOrder([
      auth.signOut(),
      days.forgetPictures('uid-1'),
      makeup.forgetPictures('uid-1'),
      makeupJobs.clearAccount('uid-1'),
      widget.clear(),
      profile.clearName(),
    ]);
  });

  test('keeps everything when signing out fails', () async {
    when(auth.signOut()).thenAnswer((_) async => const Left(NetworkFailure()));
    expect(
      await logOut(const NoParams()),
      const Left<Failure, Unit>(NetworkFailure()),
    );
    verifyZeroInteractions(days);
    verifyZeroInteractions(makeup);
    verifyZeroInteractions(makeupJobs);
    verifyZeroInteractions(widget);
    verifyNever(profile.clearName());
  });

  test('a picture that cannot be removed does not stop the rest', () async {
    when(
      days.forgetPictures(any),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    when(
      makeup.forgetPictures(any),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    expect(await logOut(const NoParams()), _done);
    verify(makeupJobs.clearAccount('uid-1')).called(1);
    verify(profile.clearName()).called(1);
  });

  test(
    'with no account on the phone it signs out and forgets the name',
    () async {
      when(auth.currentAccount()).thenAnswer((_) async => const Right(null));
      expect(await logOut(const NoParams()), _done);
      verify(auth.signOut()).called(1);
      verify(profile.clearName()).called(1);
      verifyZeroInteractions(days);
      verifyZeroInteractions(makeup);
      verifyZeroInteractions(makeupJobs);
    },
  );
}
