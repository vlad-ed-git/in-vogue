import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/utils/latest_updates.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/unit_budget_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/choose_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

class MakeOutfitParams extends Equatable {
  const MakeOutfitParams({
    required this.accountId,
    required this.date,
    required this.occasion,
    required this.weatherClass,
  });

  final String accountId;

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The weather of [date] in [occasion]'s hours.
  final WeatherClass weatherClass;

  String get cell => weatherClass.cell(occasion);

  String get key => TryOnJob.keyFor(accountId, date, occasion);

  @override
  List<Object?> get props => [accountId, date, occasion, weatherClass];
}

/// Makes the outfit of a day and occasion: saves the setup on the account,
/// chooses an outfit not shown before, tries it on piece by piece, keeps
/// its picture and records it.
///
/// Nothing starts that the budget cannot finish. Every pass reserves its
/// units first and gives them back when the service charges nothing.
/// Progress is kept after each step, so a try-on cut short goes on where it
/// stopped. One making per day and occasion runs at a time; asking again
/// follows it.
class MakeOutfit {
  MakeOutfit({
    required this._outfits,
    required this._tryOn,
    required this._budget,
    required this._jobs,
    required this._photos,
    required this._picks,
    required this._saveSetupToAccount,
    this._checkEvery = const Duration(seconds: 5),
    this._passTimeLimit = const Duration(minutes: 4),
  });

  final OutfitRepository _outfits;
  final TryOnRepository _tryOn;
  final UnitBudgetRepository _budget;
  final TryOnJobRepository _jobs;
  final PhotoRepository _photos;
  final PicksRepository _picks;
  final SaveSetupToAccount _saveSetupToAccount;
  final Duration _checkEvery;
  final Duration _passTimeLimit;

  /// Units one try-on pass costs.
  static const unitsPerPass = 2;

  /// How long the service keeps a pass's picture downloadable.
  static const pictureLifetime = Duration(hours: 2);

  final _making = <String, LatestUpdates<TryOnUpdate>>{};

  /// The making's updates, ending with [TryOnDone] or [TryOnFailed]; the
  /// latest update first when it is already under way.
  Stream<TryOnUpdate> call(MakeOutfitParams params) {
    final making = _making.putIfAbsent(params.key, () {
      final making = LatestUpdates<TryOnUpdate>();
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

  Future<TryOnUpdate> _make(
    MakeOutfitParams params,
    void Function(TryOnUpdate update) report,
  ) async {
    // Nothing is chosen, reserved or saved for a try-on that cannot run.
    if (!_tryOn.available) {
      return const TryOnFailed(TryOnFailure(TryOnProblem.unavailable));
    }
    final body = (await _photos.kept(
      PhotoRole.body,
    )).fold<UserPhoto?>((_) => null, (photo) => photo);
    if (body == null) {
      return const TryOnFailed(TryOnFailure(TryOnProblem.photo));
    }
    var job = await _resumable(params, body);
    Outfit? outfit;
    if (job != null) {
      outfit = (await _outfits.outfit(
        job.outfitId,
      )).fold<Outfit?>((_) => null, (outfit) => outfit);
    }
    if (job == null || outfit == null) {
      final chosen = await _choose(params);
      final failure = chosen.fold((failure) => failure, (_) => null);
      if (failure != null) return TryOnFailed(failure);
      outfit = chosen.getOrElse(() => throw StateError('chosen'));
      job = TryOnJob(
        accountId: params.accountId,
        date: params.date,
        occasion: params.occasion,
        cell: params.cell,
        outfitId: outfit.id,
        photoRevision: body.revision,
        updatedAt: clock.now(),
      );
      final kept = await _jobs.save(job);
      if (kept case Left(value: final failure)) return TryOnFailed(failure);
    }

    String? pictureUrl;
    final passes = outfit.passes;
    // Nothing starts that the budget cannot finish.
    final unpaid =
        passes.length - job.tasks.length - (job.reservedPass == null ? 0 : 1);
    if (unpaid > 0) {
      final left = await _budget.left();
      if (left case Left(value: final failure)) return TryOnFailed(failure);
      if (left.getOrElse(() => 0) < unpaid * unitsPerPass) {
        return const TryOnFailed(TryOnFailure(TryOnProblem.budgetSpent));
      }
    }
    for (var index = 0; index < passes.length; index++) {
      report(TryOnProgress(piece: index + 1, pieces: passes.length));
      final String task;
      if (index < job!.tasks.length) {
        task = job.tasks[index];
      } else {
        if (job.reservedPass != index) {
          final reserved = await _budget.reserve(unitsPerPass);
          if (reserved case Left(value: final failure)) {
            return TryOnFailed(failure);
          }
          job = job.reserving(index, clock.now());
          await _jobs.save(job);
        }
        String? fileId;
        if (pictureUrl == null) {
          final uploaded = await _tryOn.upload(body.path);
          if (uploaded case Left(value: final failure)) {
            // Nothing starts without the photo.
            await _budget.release(unitsPerPass);
            await _jobs.save(job.unreserved(clock.now()));
            return TryOnFailed(failure);
          }
          fileId = uploaded.getOrElse(() => throw StateError('uploaded'));
        }
        final started = await _tryOn.start(
          passes[index],
          fileId: fileId,
          pictureUrl: pictureUrl,
        );
        if (started case Left(value: final failure)) {
          // A refusal starts nothing; any other failure may have started
          // the task, so its units stay reserved for the next attempt.
          if (failure is TryOnFailure) {
            await _budget.release(unitsPerPass);
            await _jobs.save(job.unreserved(clock.now()));
          }
          return TryOnFailed(failure);
        }
        task = started.getOrElse(() => throw StateError('started'));
        job = job.started(task, clock.now());
        await _jobs.save(job);
      }
      final finished = await _finish(task);
      if (finished case Left(value: final failure)) {
        // A failed task is not charged: its pass is tried again next time.
        if (failure is TryOnFailure) {
          await _budget.release(unitsPerPass);
          await _jobs.save(job.keeping(index, clock.now()));
        }
        return TryOnFailed(failure);
      }
      pictureUrl = finished.getOrElse(() => throw StateError('finished'));
    }

    final picture = await _tryOn.download(pictureUrl!);
    if (picture case Left(value: final failure)) return TryOnFailed(failure);
    final recorded = await _outfits.record(
      params.accountId,
      outfit: outfit,
      cell: job!.cell,
      date: job.date,
      occasion: job.occasion,
      picture: picture.getOrElse(() => const []),
    );
    if (recorded case Left(value: final failure)) return TryOnFailed(failure);
    await _jobs.clear(job.key);
    for (final task in job.tasks) {
      unawaited(_tryOn.discard(task));
    }
    return TryOnDone(recorded.getOrElse(() => throw StateError('recorded')));
  }

  /// The kept job of [params] when it can go on: for the same body photo,
  /// with its pictures still downloadable. Any other is dropped.
  Future<TryOnJob?> _resumable(MakeOutfitParams params, UserPhoto body) async {
    final job = (await _jobs.job(
      params.key,
    )).fold<TryOnJob?>((_) => null, (job) => job);
    if (job == null) return null;
    final fresh = clock.now().difference(job.updatedAt) < pictureLifetime;
    if (fresh && job.photoRevision == body.revision) return job;
    await _jobs.clear(job.key);
    return null;
  }

  /// Saves the setup on the account, so the photo is there, then chooses
  /// the outfit.
  Future<Either<Failure, Outfit>> _choose(MakeOutfitParams params) async {
    final saved = await _saveSetupToAccount(params.accountId);
    if (saved case Left(value: final failure)) return Left(failure);
    final ranked = await _outfits.outfitsFor(params.cell);
    if (ranked case Left(value: final failure)) return Left(failure);
    final shown = await _outfits.shownSignatures(params.accountId);
    if (shown case Left(value: final failure)) return Left(failure);
    final picks = (await _picks.picks()).getOrElse(() => const {});
    final outfit = ChooseOutfit.from(
      ranked.getOrElse(() => const []),
      shown: shown.getOrElse(() => const {}),
      picks: picks,
    );
    return outfit == null
        ? const Left(TryOnFailure(TryOnProblem.everySeen))
        : Right(outfit);
  }

  /// Waits for [task]; its picture's URL. A [TryOnFailure] when the task
  /// failed; a [ServerFailure] when it takes too long to say.
  Future<Either<Failure, String>> _finish(String task) async {
    final deadline = clock.now().add(_passTimeLimit);
    while (true) {
      final checked = await _tryOn.check(task);
      if (checked case Left(value: final failure)) return Left(failure);
      switch (checked.getOrElse(() => const TryOnRunning())) {
        case TryOnSucceeded(:final pictureUrl):
          return Right(pictureUrl);
        case TryOnErrored(:final problem):
          return Left(TryOnFailure(problem));
        case TryOnRunning():
          if (!clock.now().isBefore(deadline)) {
            return const Left(ServerFailure());
          }
          await Future<void>.delayed(_checkEvery);
      }
    }
  }
}
