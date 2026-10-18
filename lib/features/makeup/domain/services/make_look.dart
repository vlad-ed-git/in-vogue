import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/utils/latest_updates.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_update.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_job_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_service_repository.dart';
import 'package:in_vogue/features/makeup/domain/services/makeup_rules.dart';
import 'package:in_vogue/features/makeup/domain/services/skin_rules.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:path/path.dart' as p;

class MakeLookParams extends Equatable {
  const MakeLookParams({
    required this.accountId,
    required this.outfit,
    this.weather,
  });

  final String accountId;
  final DayOutfit outfit;

  /// The outfit's day in its occasion's hours; the outfit's own cell when
  /// null.
  final WeatherClass? weather;

  String get key => MakeupJob.keyFor(accountId, outfit.outfit.signature);

  @override
  List<Object?> get props => [accountId, outfit, weather];
}

/// Makes the makeup look for an outfit on the person's face photo:
/// analyses the face's colours once per photo, takes the knowledge base's
/// recipe for the outfit, its occasion, the face and the weather, renders
/// each step on the picture of the step before, keeps every picture and
/// records the look. A look already made on the face photo is never made
/// again; a new face photo gets its own.
///
/// Progress is kept after each step, so a look cut short goes on where it
/// stopped. One making per look runs at a time; asking again follows it.
class MakeLook {
  MakeLook({
    required this._looks,
    required this._service,
    required this._jobs,
    required this._photos,
    required this._saveSetupToAccount,
    this._checkEvery = const Duration(seconds: 3),
    this._taskTimeLimit = const Duration(minutes: 2),
  });

  final MakeupRepository _looks;
  final MakeupServiceRepository _service;
  final MakeupJobRepository _jobs;
  final PhotoRepository _photos;
  final SaveSetupToAccount _saveSetupToAccount;
  final Duration _checkEvery;
  final Duration _taskTimeLimit;

  /// How long the service keeps a task's result.
  static const resultLifetime = Duration(hours: 2);

  final _making = <String, LatestUpdates<MakeupUpdate>>{};

  /// The making's updates, ending with [MakeupDone] or [MakeupFailed]; the
  /// latest update first when it is already under way.
  Stream<MakeupUpdate> call(MakeLookParams params) {
    final making = _making.putIfAbsent(params.key, () {
      final making = LatestUpdates<MakeupUpdate>();
      unawaited(
        _make(params, making.add).then((last) {
          _making.remove(params.key);
          making
            ..add(last)
            ..close();
        }),
      );
      return making;
    });
    return making.watch();
  }

  /// Whether the look of [params] is being made, or was cut short and can
  /// go on.
  Future<bool> underway(MakeLookParams params) async {
    if (_making.containsKey(params.key)) return true;
    final face = await _face();
    return face != null && await _resumable(params, face) != null;
  }

  Future<MakeupUpdate> _make(
    MakeLookParams params,
    void Function(MakeupUpdate update) report,
  ) async {
    // Nothing is kept for a look that cannot be made.
    if (!_service.available) {
      return const MakeupFailed(MakeupFailure(MakeupProblem.unavailable));
    }
    final accountId = params.accountId;
    final outfit = params.outfit;
    final signature = outfit.outfit.signature;
    final face = await _face();
    if (face == null) {
      return const MakeupFailed(MakeupFailure(MakeupProblem.photo));
    }
    final made = await _looks.look(
      accountId,
      facePhoto: face.path,
      outfitSignature: signature,
    );
    if (made case Left(value: final failure)) return MakeupFailed(failure);
    if (made.getOrElse(() => null) case final MakeupLook look) {
      return MakeupDone(look);
    }
    var job =
        await _resumable(params, face) ??
        MakeupJob(
          accountId: accountId,
          outfitSignature: signature,
          faceRevision: face.revision,
          updatedAt: clock.now(),
        );
    // So the face photo is on the account; a failed save never blocks.
    await _saveSetupToAccount(accountId);

    final weatherClass = params.weather ?? WeatherClass.fromCell(outfit.cell);
    final weather = weatherClass == null
        ? 'none'
        : MakeupRules.weatherOf(weatherClass);
    String keyFor(SkinProfile profile) => MakeupRules.keyOf(
      occasion: outfit.occasion,
      palette: outfit.outfit.palette,
      profile: profile,
      weather: weather,
    );

    // The steps show at once, in neutral colours until the face's are known.
    final shown = await _recipe(job.recipeKey ?? keyFor(SkinRules.neutral));
    if (shown case Left(value: final failure)) return MakeupFailed(failure);
    var recipe = shown.getOrElse(() => throw StateError('recipe'));
    report(MakeupProgress(_steps(recipe)));

    // The face as the service takes it, kept as the look's before.
    var before = job.before == null
        ? null
        : await _kept(accountId, face, signature, job.before!);
    if (before == null) {
      final prepared = await _service.prepareFace(face.path);
      if (prepared case Left(value: final failure)) {
        return MakeupFailed(failure);
      }
      final kept = await _looks.keepPicture(
        accountId,
        facePhoto: face.path,
        outfitSignature: signature,
        name: 'before',
        picture: prepared.getOrElse(() => const []),
      );
      if (kept case Left(value: final failure)) return MakeupFailed(failure);
      before = kept.getOrElse(() => throw StateError('kept'));
      job = job.withBefore(p.basename(before), clock.now());
    }
    final saved = await _jobs.save(job);
    if (saved case Left(value: final failure)) return MakeupFailed(failure);

    final known = await _looks.faceColours(accountId, face.path);
    if (known case Left(value: final failure)) return MakeupFailed(failure);
    var colours = known.getOrElse(() => null);
    if (colours == null) {
      final String task;
      if (job.analysisTask case final String started) {
        task = started;
      } else {
        final uploaded = await _service.upload(before);
        if (uploaded case Left(value: final failure)) {
          return MakeupFailed(failure);
        }
        final started = await _service.startAnalysis(
          uploaded.getOrElse(() => throw StateError('uploaded')),
        );
        if (started case Left(value: final failure)) {
          return MakeupFailed(failure);
        }
        task = started.getOrElse(() => throw StateError('started'));
        await _jobs.save(job = job.analysing(task, clock.now()));
      }
      final analysed = await _finish(() => _service.checkAnalysis(task));
      if (analysed case Left(value: final failure)) {
        // A failed analysis starts again next time.
        if (failure is MakeupFailure) {
          await _jobs.save(job = job.analysed(clock.now()));
        }
        return MakeupFailed(failure);
      }
      colours = analysed.getOrElse(() => throw StateError('analysed'));
      // Kept with its task until the colours are saved.
      final kept = await _looks.saveFaceColours(accountId, face.path, colours);
      if (kept case Left(value: final failure)) return MakeupFailed(failure);
      await _jobs.save(job = job.analysed(clock.now()));
      unawaited(_service.discard(task));
    }
    final profile = SkinRules.profileOf(colours);

    final key = job.recipeKey ?? keyFor(profile);
    if (key != recipe.key) {
      final chosen = await _recipe(key);
      if (chosen case Left(value: final failure)) return MakeupFailed(failure);
      recipe = chosen.getOrElse(() => throw StateError('recipe'));
    }
    if (job.recipeKey == null) {
      await _jobs.save(job = job.withRecipe(key, clock.now()));
    }
    final steps = _steps(recipe);
    for (var index = 0; index < job.pictures.length; index++) {
      final picture = await _kept(
        accountId,
        face,
        signature,
        job.pictures[index],
      );
      if (picture == null || index >= steps.length) {
        // What was kept is gone; the look starts again next time.
        await _jobs.clear(job.key);
        return const MakeupFailed(CacheFailure());
      }
      steps[index] = steps[index].withPicture(picture);
    }
    report(MakeupProgress(List.unmodifiable(steps)));

    for (var index = job.pictures.length; index < steps.length; index++) {
      final String task;
      if (index < job.tasks.length) {
        task = job.tasks[index];
      } else {
        final uploaded = await _service.upload(
          index == 0 ? before : steps[index - 1].picture!,
        );
        if (uploaded case Left(value: final failure)) {
          return MakeupFailed(failure);
        }
        final started = await _service.startStep(
          uploaded.getOrElse(() => throw StateError('uploaded')),
          MakeupRules.effectsFor(recipe.steps[index], profile),
        );
        if (started case Left(value: final failure)) {
          return MakeupFailed(failure);
        }
        task = started.getOrElse(() => throw StateError('started'));
        await _jobs.save(job = job.started(task, clock.now()));
      }
      final finished = await _finish(() => _service.checkStep(task));
      if (finished case Left(value: final failure)) {
        // A failed step is tried again next time.
        if (failure is MakeupFailure) {
          await _jobs.save(job = job.keeping(index, clock.now()));
        }
        return MakeupFailed(failure);
      }
      final picture = await _service.download(
        finished.getOrElse(() => throw StateError('finished')),
      );
      if (picture case Left(value: final failure)) {
        return MakeupFailed(failure);
      }
      final kept = await _looks.keepPicture(
        accountId,
        facePhoto: face.path,
        outfitSignature: signature,
        name: 'step-${index + 1}',
        picture: picture.getOrElse(() => const []),
      );
      if (kept case Left(value: final failure)) return MakeupFailed(failure);
      final path = kept.getOrElse(() => throw StateError('kept'));
      await _jobs.save(job = job.kept(p.basename(path), clock.now()));
      steps[index] = steps[index].withPicture(path);
      report(MakeupProgress(List.unmodifiable(steps)));
      unawaited(_service.discard(task));
    }

    final look = MakeupLook(
      outfitSignature: signature,
      date: outfit.date,
      occasion: outfit.occasion,
      palette: outfit.outfit.palette ?? OutfitPalette.mixedNeutral,
      cheeks: recipe.cheeks,
      lips: recipe.lips,
      before: before,
      steps: List.unmodifiable(steps),
      matched: profile.matched,
    );
    final recorded = await _looks.record(accountId, look, facePhoto: face.path);
    if (recorded case Left(value: final failure)) return MakeupFailed(failure);
    await _jobs.clear(job.key);
    return MakeupDone(look);
  }

  Future<UserPhoto?> _face() async => (await _photos.kept(
    PhotoRole.face,
  )).fold<UserPhoto?>((_) => null, (photo) => photo);

  Future<String?> _kept(
    String accountId,
    UserPhoto face,
    String signature,
    String name,
  ) async => (await _looks.keptPicture(
    accountId,
    facePhoto: face.path,
    outfitSignature: signature,
    fileName: name,
  )).fold<String?>((_) => null, (path) => path);

  /// The recipe [key]; a [CacheFailure] when the knowledge base has none.
  Future<Either<Failure, MakeupRecipe>> _recipe(String key) async =>
      (await _looks.recipe(key)).fold(
        (failure) => Left(failure),
        (recipe) => recipe == null ? const Left(CacheFailure()) : Right(recipe),
      );

  /// [recipe]'s steps, none made yet.
  static List<LookStep> _steps(MakeupRecipe recipe) => [
    for (final step in recipe.steps)
      LookStep(title: step.title, howTo: step.howTo, products: step.products),
  ];

  /// The kept job of [params] when it can go on: for the same face photo,
  /// with its results still at the service. Any other is dropped.
  Future<MakeupJob?> _resumable(MakeLookParams params, UserPhoto face) async {
    final job = (await _jobs.job(
      params.key,
    )).fold<MakeupJob?>((_) => null, (job) => job);
    if (job == null) return null;
    final fresh = clock.now().difference(job.updatedAt) < resultLifetime;
    if (fresh && job.faceRevision == face.revision) return job;
    await _jobs.clear(job.key);
    return null;
  }

  /// Waits for a task through [check]; its result. A [MakeupFailure] when
  /// the task failed; a [ServerFailure] when it takes too long to say.
  Future<Either<Failure, T>> _finish<T>(
    Future<Either<Failure, MakeupTask<T>>> Function() check,
  ) async {
    final deadline = clock.now().add(_taskTimeLimit);
    while (true) {
      final checked = await check();
      if (checked case Left(value: final failure)) return Left(failure);
      switch (checked.getOrElse(() => MakeupTaskRunning<T>())) {
        case MakeupTaskDone<T>(:final result):
          return Right(result);
        case MakeupTaskFailed<T>(:final problem):
          return Left(MakeupFailure(problem));
        case MakeupTaskRunning<T>():
          if (!clock.now().isBefore(deadline)) {
            return const Left(ServerFailure());
          }
          await Future<void>.delayed(_checkEvery);
      }
    }
  }
}
