import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/analyse_face.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';
import 'package:in_vogue/features/colours/presentation/bloc/colours_bloc.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'colours_bloc_test.mocks.dart';

const _face = UserPhoto(
  role: PhotoRole.face,
  path: '/photos/face-2.png',
  revision: 2,
);

const _colours = FaceColours(
  skin: '#F3D3B5',
  eyebrow: '#A07850',
  lip: '#C98276',
  hair: '#C9A26B',
  clear: true,
);

@GenerateMocks([GetCurrentAccount, GetKeptPhoto, AnalyseFace])
void main() {
  late MockGetCurrentAccount account;
  late MockGetKeptPhoto photos;
  late MockAnalyseFace analyse;

  setUp(() {
    provideDummy<Either<Failure, Account?>>(const Right(null));
    provideDummy<Either<Failure, UserPhoto?>>(const Right(null));
    provideDummy<Either<Failure, FaceColours>>(const Right(_colours));
    account = MockGetCurrentAccount();
    photos = MockGetKeptPhoto();
    analyse = MockAnalyseFace();
    when(
      account(const NoParams()),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
    when(photos(PhotoRole.face)).thenAnswer((_) async => const Right(_face));
    when(analyse('uid-1')).thenAnswer((_) async => const Right(_colours));
  });

  ColoursBloc build() => ColoursBloc(
    getCurrentAccount: account,
    getKeptPhoto: photos,
    analyseFace: analyse,
  );

  final ready = ColoursState(
    status: ColoursStatus.ready,
    reading: SeasonRules.readingOf(_colours),
  );

  blocTest<ColoursBloc, ColoursState>(
    'reads the face photo, then shows its season',
    build: build,
    act: (bloc) => bloc.add(const ColoursShown()),
    expect: () => [const ColoursState(status: ColoursStatus.reading), ready],
  );

  blocTest<ColoursBloc, ColoursState>(
    'asks for a selfie without a face photo, and reads nothing',
    build: () {
      when(photos(PhotoRole.face)).thenAnswer((_) async => const Right(null));
      return build();
    },
    act: (bloc) => bloc.add(const ColoursShown()),
    expect: () => [const ColoursState(status: ColoursStatus.noPhoto)],
    verify: (_) => verifyZeroInteractions(analyse),
  );

  blocTest<ColoursBloc, ColoursState>(
    'says why the colours could not be read',
    build: () {
      when(analyse('uid-1')).thenAnswer(
        (_) async => const Left(
          AnalysisFailure(
            AnalysisProblem.photo,
            advice: PhotoAdvice.lookStraight,
          ),
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(const ColoursShown()),
    expect: () => [
      const ColoursState(status: ColoursStatus.reading),
      const ColoursState(
        status: ColoursStatus.failed,
        failure: AnalysisFailure(
          AnalysisProblem.photo,
          advice: PhotoAdvice.lookStraight,
        ),
      ),
    ],
  );

  blocTest<ColoursBloc, ColoursState>(
    'keeps the season on screen while the same photo is checked again',
    build: build,
    seed: () => ready,
    act: (bloc) async {
      bloc.add(const ColoursShown());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ColoursShown());
    },
    expect: () => [const ColoursState(status: ColoursStatus.reading), ready],
  );
}
