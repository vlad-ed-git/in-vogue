import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/presentation/bloc/skin_analysis_bloc.dart';
import 'package:mockito/mockito.dart';

import 'colours_bloc_test.mocks.dart';

const _colours = FaceColours(
  skin: '#F3D3B5',
  eyebrow: '#A07850',
  lip: '#C98276',
  hair: '#C9A26B',
  clear: true,
);

void main() {
  late MockGetCurrentAccount account;
  late MockAnalyseFace analyse;

  setUp(() {
    provideDummy<Either<Failure, Account?>>(const Right(null));
    provideDummy<Either<Failure, FaceColours>>(const Right(_colours));
    account = MockGetCurrentAccount();
    analyse = MockAnalyseFace();
    when(
      account(const NoParams()),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
    when(
      analyse('uid-1', redo: true),
    ).thenAnswer((_) async => const Right(_colours));
  });

  SkinAnalysisBloc build() =>
      SkinAnalysisBloc(getCurrentAccount: account, analyseFace: analyse);

  blocTest<SkinAnalysisBloc, SkinAnalysisState>(
    'redoes the analysis on the face photo when the person asks',
    build: build,
    act: (bloc) => bloc.add(const SkinAnalysisRedone()),
    expect: () => const [
      SkinAnalysisState(status: SkinAnalysisStatus.redoing),
      SkinAnalysisState(status: SkinAnalysisStatus.done),
    ],
    verify: (_) => verify(analyse('uid-1', redo: true)).called(1),
  );

  blocTest<SkinAnalysisBloc, SkinAnalysisState>(
    'says what to change when the new photo is refused',
    build: () {
      when(analyse('uid-1', redo: true)).thenAnswer(
        (_) async => const Left(
          AnalysisFailure(
            AnalysisProblem.photo,
            advice: PhotoAdvice.lookStraight,
          ),
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(const SkinAnalysisRedone()),
    expect: () => const [
      SkinAnalysisState(status: SkinAnalysisStatus.redoing),
      SkinAnalysisState(
        status: SkinAnalysisStatus.failed,
        failure: AnalysisFailure(
          AnalysisProblem.photo,
          advice: PhotoAdvice.lookStraight,
        ),
      ),
    ],
  );
}
