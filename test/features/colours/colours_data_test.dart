import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/colours/data/data_sources/colour_profile_remote_data_source.dart';
import 'package:in_vogue/features/colours/data/models/face_colours_model.dart';
import 'package:in_vogue/features/colours/data/repositories/analysis_job_repository_impl.dart';
import 'package:in_vogue/features/colours/data/repositories/colour_profile_repository_impl.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';

import '../../helpers/memory_store.dart';

const _analysis = {
  'face_quality': {
    'has_face': true,
    'frontal': 'good',
    'lighting': 'good',
    'faceangle': 'good',
  },
  'color': {
    'skin_color': '#E8C4AE',
    'eyebrow_color': '#3B2A22',
    'lip_color': '#C98276',
    'hair_color': '#42280E',
    'eye_color': '#5A3B2B',
  },
};

const _colours = FaceColours(
  skin: '#E8C4AE',
  eyebrow: '#3B2A22',
  lip: '#C98276',
  hair: '#42280E',
  eye: '#5A3B2B',
  clear: true,
);

void main() {
  group('FaceColoursModel', () {
    test("reads the analysis's colours, trusted when the photo is clear", () {
      expect(FaceColoursModel.fromAnalysis(_analysis), _colours);
      final dim = {
        ..._analysis,
        'face_quality': {..._analysis['face_quality']!, 'lighting': 'too_dark'},
      };
      expect(FaceColoursModel.fromAnalysis(dim).clear, isFalse);
    });

    test('trusts the colours of a success that reports no face quality', () {
      expect(
        FaceColoursModel.fromAnalysis({'color': _analysis['color']}),
        _colours,
      );
    });

    test('counts results without readable colours as an unclear photo', () {
      expect(
        FaceColoursModel.fromAnalysis({
          'face_quality': _analysis['face_quality'],
        }),
        SeasonRules.neutralColours,
      );
      expect(
        FaceColoursModel.fromAnalysis({
          'color': {..._analysis['color']!, 'skin_color': 'tan'},
        }),
        SeasonRules.neutralColours,
      );
    });

    test('keeps the colours on the account as they are, eyes or none', () {
      expect(
        FaceColoursModel.fromJson(FaceColoursModel.toJson(_colours)),
        _colours,
      );
      final older = FaceColoursModel.toJson(_colours)..remove('eye');
      expect(FaceColoursModel.fromJson(older)?.eye, isNull);
    });
  });

  group('ColourProfileRepositoryImpl', () {
    test('keeps a face photo\'s colours under its content, for that account '
        'only', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = ColourProfileRepositoryImpl(
        remoteDataSource: ColourProfileRemoteDataSourceImpl(firestore),
        fingerprints: PhotoFingerprints(read: (path) async => path.codeUnits),
        logMessages: LogMessagesImpl(),
      );
      expect(
        await repository.colours('uid-1', '/photos/face.png'),
        const Right<Failure, FaceColours?>(null),
      );
      await repository.save('uid-1', '/photos/face.png', _colours);
      expect(
        await repository.colours('uid-1', '/photos/face.png'),
        const Right<Failure, FaceColours?>(_colours),
      );
      expect(
        await repository.colours('uid-2', '/photos/face.png'),
        const Right<Failure, FaceColours?>(null),
      );
      expect(
        await repository.colours('uid-1', '/photos/another.png'),
        const Right<Failure, FaceColours?>(null),
      );
    });
  });

  group('AnalysisJobRepositoryImpl', () {
    test('keeps a task under way until it is cleared', () async {
      final jobs = AnalysisJobRepositoryImpl(MemoryStore());
      expect(await jobs.task('uid-1/2'), isNull);
      await jobs.save('uid-1/2', 'task-1');
      expect(await jobs.task('uid-1/2'), 'task-1');
      await jobs.clear('uid-1/2');
      expect(await jobs.task('uid-1/2'), isNull);
    });

    test("forgets an account's tasks and no one else's", () async {
      final jobs = AnalysisJobRepositoryImpl(MemoryStore());
      await jobs.save('uid-1/2', 'task-1');
      await jobs.save('uid-2/1', 'task-2');
      await jobs.forgetAccount('uid-1');
      expect(await jobs.task('uid-1/2'), isNull);
      expect(await jobs.task('uid-2/1'), 'task-2');
    });
  });
}
