import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_job_local_data_source.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_job_model.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_job_repository_impl.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';

import '../../helpers/memory_store.dart';

void main() {
  test('a makeup job never drops a running analysis or its progress', () {
    final at = DateTime.utc(2026, 10, 17, 8);
    final job =
        MakeupJob(
              accountId: 'uid-1',
              outfitSignature: 'coat+tee',
              faceRevision: 2,
              updatedAt: at,
            )
            .reservingAnalysis(at)
            .analysing('analysis-1', at)
            .withBefore('before.png', at);
    expect(job.analysisTask, 'analysis-1');
    expect(job.analysisReserved, isFalse);
    expect(job.before, 'before.png');

    final steps = job
        .analysed(at)
        .withRecipe('work|cool_neutral|light|high|none', at)
        .reservingStep(0, at)
        .started('step-1', at)
        .kept('step-1.jpg', at)
        .reservingStep(1, at);
    expect(steps.analysisTask, isNull);
    expect(steps.tasks, ['step-1']);
    expect(steps.pictures, ['step-1.jpg']);
    expect(steps.reservedStep, 1);
    expect(steps.recipeKey, 'work|cool_neutral|light|high|none');
    expect(steps.started('step-2', at).reservedStep, isNull);
    expect(steps.keeping(0, at).tasks, isEmpty);
    expect(steps.key, 'uid-1|coat+tee');
  });

  group('makeup jobs on the phone', () {
    final at = DateTime.utc(2026, 10, 17, 8);
    final job = MakeupJob(
      accountId: 'uid-1',
      outfitSignature: 'coat+tee',
      faceRevision: 2,
      updatedAt: at,
    ).withBefore('before.png', at).analysing('analysis-1', at);

    test('are kept as JSON and read back the same', () {
      expect(MakeupJobModel.fromJson(MakeupJobModel.toJson(job)), job);
      expect(() => MakeupJobModel.fromJson(const {}), throwsFormatException);
    });

    test('are saved by key, cleared alone or by account', () async {
      final store = MemoryStore();
      final jobs = MakeupJobRepositoryImpl(MakeupJobLocalDataSourceImpl(store));
      final other = MakeupJob(
        accountId: 'uid-2',
        outfitSignature: 'dress',
        faceRevision: 1,
        updatedAt: at,
      );
      await jobs.save(job);
      await jobs.save(other);
      expect((await jobs.job(job.key)).getOrElse(() => null), job);
      await jobs.clearAccount('uid-1');
      expect((await jobs.job(job.key)).getOrElse(() => null), isNull);
      expect((await jobs.job(other.key)).getOrElse(() => null), other);
      await jobs.clear(other.key);
      expect((await jobs.job(other.key)).getOrElse(() => null), isNull);
    });

    test('leave out an unreadable job', () {
      final store = MemoryStore()
        ..values[MakeupJobLocalDataSourceImpl.jobsKey] = jsonEncode({
          'a': MakeupJobModel.toJson(job),
          'b': {'accountId': 'uid-1'},
        });
      expect(MakeupJobLocalDataSourceImpl(store).jobs().keys, ['a']);
    });
  });
}
