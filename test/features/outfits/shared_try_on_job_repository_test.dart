import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/shared_try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

import '../../helpers/memory_store.dart';

void main() {
  late Directory folder;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('shared-jobs');
  });
  tearDown(() async {
    await folder.delete(recursive: true);
  });

  TryOnJob job(int day) => TryOnJob(
    accountId: 'uid',
    date: DateTime.utc(2026, 11, day),
    occasion: Occasion.work,
    outfitId: 'outfit-$day',
    photoRevision: 2,
    updatedAt: DateTime.utc(2026, 11, 13),
    tasks: ['task-$day'],
  );

  test(
    'two engines share resumable progress without losing concurrent days',
    () async {
      final foreground = SharedTryOnJobRepository(folder.path);
      final background = SharedTryOnJobRepository(folder.path);
      await Future.wait([foreground.save(job(13)), background.save(job(14))]);
      expect(
        (await foreground.job(job(14).key)).getOrElse(() => null),
        job(14),
      );
      expect(
        (await background.job(job(13).key)).getOrElse(() => null),
        job(13),
      );
      await foreground.clearAccount('uid');
      expect((await background.job(job(13).key)).getOrElse(() => null), isNull);
      expect((await background.job(job(14).key)).getOrElse(() => null), isNull);
    },
  );

  test(
    'promotes existing Hive progress so the next background worker resumes it',
    () async {
      final legacy = TryOnJobRepositoryImpl(
        TryOnJobLocalDataSourceImpl(MemoryStore()),
      );
      await legacy.save(job(13));
      final foreground = SharedTryOnJobRepository(folder.path, legacy: legacy);
      expect(
        (await foreground.job(job(13).key)).getOrElse(() => null),
        job(13),
      );
      final background = SharedTryOnJobRepository(folder.path);
      expect(
        (await background.job(job(13).key)).getOrElse(() => null),
        job(13),
      );
      expect((await legacy.job(job(13).key)).getOrElse(() => null), isNull);
    },
  );
}
