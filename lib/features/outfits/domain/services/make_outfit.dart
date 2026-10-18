import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/utils/latest_updates.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/choose_outfit.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';
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

/// Makes the outfit of a day and occasion, shared by every phone signed in
/// to the account.
///
/// Claims the day first: a day another phone made is shown, one it is
/// making is left to it. A new day saves the setup on the account and
/// takes the best outfit for its weather never suggested, lifted by the
/// person's favourite pieces. The outfit is then tried on piece by piece,
/// each piece reported on the day, and the picture kept with the day.
///
/// A photo and outfit already tried on are never tried on again: the day
/// takes the picture made before. Progress is kept after each piece, so a
/// try-on cut short goes on where it stopped. When the try-on refuses a piece's photo, the piece is never
/// chosen again and the day goes on with another outfit. Days are claimed
/// one at a time, and one making per day runs at a time; asking again
/// follows it.
class MakeOutfit {
  MakeOutfit({
    required this._outfits,
    required this._days,
    required this._tryOn,
    required this._jobs,
    required this._photos,
    required this._picks,
    required this._saveSetupToAccount,
    required InstallId installId,
    this._checkEvery = const Duration(seconds: 5),
    this._passTimeLimit = const Duration(minutes: 4),
  }) : _device = installId.value;

  final OutfitRepository _outfits;
  final DayRepository _days;
  final TryOnRepository _tryOn;
  final TryOnJobRepository _jobs;
  final PhotoRepository _photos;
  final PicksRepository _picks;
  final SaveSetupToAccount _saveSetupToAccount;
  final String _device;
  final Duration _checkEvery;
  final Duration _passTimeLimit;

  /// How long the service keeps a pass's picture downloadable.
  static const pictureLifetime = Duration(hours: 2);

  /// Times choosing starts again when the outfit chosen was taken meanwhile.
  static const claimAttempts = 3;

  /// Outfits one making tries before the refusal of a piece's photo stays
  /// on the day.
  static const outfitAttempts = 3;

  final _making = <String, LatestUpdates<TryOnUpdate>>{};

  /// The last claim; the next waits for it.
  Future<void> _claiming = Future.value();

  /// The making's updates, ending with [TryOnDone], [TryOnFailed] or
  /// [TryOnElsewhere]; the latest update first when it is already under
  /// way.
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

  /// Whether this phone is making [params]'s outfit now.
  bool isMaking(MakeOutfitParams params) => _making.containsKey(params.key);

  Future<TryOnUpdate> _make(
    MakeOutfitParams params,
    void Function(TryOnUpdate update) report,
  ) async {
    // Nothing is chosen or claimed for a try-on that cannot run.
    if (!_tryOn.available) {
      return const TryOnFailed(TryOnFailure(TryOnProblem.unavailable));
    }
    final body = (await _photos.kept(
      PhotoRole.body,
    )).fold<UserPhoto?>((_) => null, (photo) => photo);
    if (body == null) {
      return const TryOnFailed(TryOnFailure(TryOnProblem.photo));
    }
    Day? refused;
    for (var tried = 1; ; tried++) {
      final claimed = await _oneAtATime(
        () => _claim(params, replacing: refused?.outfitId),
      );
      if (claimed case Left(value: final failure)) {
        // With no outfit to go on with, the refusal stays on the day.
        if (refused != null) {
          await _days.fail(
            params.accountId,
            refused,
            TryOnProblem.reference,
            device: _device,
          );
        }
        return TryOnFailed(failure);
      }
      final Day day;
      switch (claimed.getOrElse(() => const DayConflict())) {
        case DayKept(day: final kept) when kept.status == DayStatus.ready:
          return _shown(params, kept);
        case DayKept(day: final kept):
          return TryOnElsewhere(kept);
        case DayClaimed(day: final mine):
          day = mine;
        case DayConflict():
          return const TryOnFailed(ServerFailure());
      }
      final made = await _makeDay(params, day, body, report);
      if (made case TryOnFailed(
        failure: final TryOnFailure failure,
      ) when failure.problem == TryOnProblem.reference) {
        if (tried < outfitAttempts) {
          refused = day;
          continue;
        }
        return _failed(params, day, failure);
      }
      return made;
    }
  }

  /// Tries [day]'s outfit on [body], piece by piece. A piece's photo the
  /// try-on refuses is remembered, and the making ends without marking the
  /// day, so another outfit can take its place.
  Future<TryOnUpdate> _makeDay(
    MakeOutfitParams params,
    Day day,
    UserPhoto body,
    void Function(TryOnUpdate update) report,
  ) async {
    final outfit = (await _outfits.outfit(
      day.outfitId,
    )).fold<Outfit?>((_) => null, (outfit) => outfit);
    if (outfit == null) return const TryOnFailed(CacheFailure());

    final made = await _days.madePicture(
      params.accountId,
      photo: body.path,
      signature: day.signature,
    );
    if (made case Left(value: final failure)) return TryOnFailed(failure);
    if (made.getOrElse(() => null) case final String path) {
      return _reused(params, day, outfit, path);
    }

    var job = await _resumable(params, day, body);
    if (job == null) {
      job = TryOnJob(
        accountId: params.accountId,
        date: params.date,
        occasion: params.occasion,
        cell: day.cell,
        outfitId: day.outfitId,
        photoRevision: body.revision,
        updatedAt: clock.now(),
      );
      final kept = await _jobs.save(job);
      if (kept case Left(value: final failure)) return TryOnFailed(failure);
    }

    String? pictureUrl;
    final passes = outfit.passes;
    for (var index = 0; index < passes.length; index++) {
      report(TryOnProgress(piece: index + 1, pieces: passes.length));
      final still = await _days.progress(
        params.accountId,
        day,
        piece: index + 1,
        pieces: passes.length,
        device: _device,
      );
      if (still case Left(value: final failure)) return TryOnFailed(failure);
      if (!still.getOrElse(() => false)) return TryOnElsewhere(day);
      final String task;
      if (index < job!.tasks.length) {
        task = job.tasks[index];
      } else {
        String? fileId;
        if (pictureUrl == null) {
          final uploaded = await _tryOn.upload(body.path);
          if (uploaded case Left(value: final failure)) {
            return _failed(params, day, failure);
          }
          fileId = uploaded.getOrElse(() => throw StateError('uploaded'));
        }
        final started = await _tryOn.start(
          passes[index],
          fileId: fileId,
          pictureUrl: pictureUrl,
        );
        if (started case Left(value: final failure)) {
          return _failed(params, day, failure);
        }
        task = started.getOrElse(() => throw StateError('started'));
        job = job.started(task, clock.now());
        await _jobs.save(job);
      }
      final finished = await _finish(task);
      if (finished case Left(value: final failure)) {
        if (failure case TryOnFailure(problem: TryOnProblem.reference)) {
          await _days.refuse(
            params.accountId,
            day.signature,
            passes[index].piece,
          );
          await _drop(job);
          return TryOnFailed(failure);
        }
        // A failed pass is tried again next time.
        if (failure is TryOnFailure) {
          await _jobs.save(job.keeping(index, clock.now()));
        }
        return _failed(params, day, failure);
      }
      pictureUrl = finished.getOrElse(() => throw StateError('finished'));
    }

    final picture = await _tryOn.download(pictureUrl!);
    if (picture case Left(value: final failure)) return TryOnFailed(failure);
    final kept = await _days.finish(
      params.accountId,
      day,
      picture.getOrElse(() => const []),
      photo: body.path,
      device: _device,
    );
    if (kept case Left(value: final failure)) return TryOnFailed(failure);
    final file = kept.getOrElse(() => null);
    if (file == null) return TryOnElsewhere(day);
    await _drop(job!);
    return TryOnDone(
      DayOutfit(
        outfit: outfit,
        date: day.date,
        occasion: day.occasion,
        cell: day.cell,
        picture: file,
      ),
    );
  }

  /// Makes [day] with [outfit]'s picture made before at [path].
  Future<TryOnUpdate> _reused(
    MakeOutfitParams params,
    Day day,
    Outfit outfit,
    String path,
  ) async {
    final kept = await _days.reuse(
      params.accountId,
      day,
      path,
      device: _device,
    );
    if (kept case Left(value: final failure)) return TryOnFailed(failure);
    final file = kept.getOrElse(() => null);
    if (file == null) return TryOnElsewhere(day);
    // A try-on kept from before isn't needed any more.
    await _jobs.clear(params.key);
    return TryOnDone(
      DayOutfit(
        outfit: outfit,
        date: day.date,
        occasion: day.occasion,
        cell: day.cell,
        picture: file,
      ),
    );
  }

  /// Runs [claim] once the claim before it is done.
  Future<T> _oneAtATime<T>(Future<T> Function() claim) {
    final claimed = _claiming.then((_) => claim());
    _claiming = claimed.then<void>((_) {}, onError: (Object _) {});
    return claimed;
  }

  /// Claims [params]'s day: with a new outfit chosen when it needs one, or
  /// in place of the outfit this phone is [replacing].
  Future<Either<Failure, DayClaim>> _claim(
    MakeOutfitParams params, {
    String? replacing,
  }) async {
    for (var attempt = 0; attempt < claimAttempts; attempt++) {
      final current = await _days.day(
        params.accountId,
        date: params.date,
        occasion: params.occasion,
      );
      if (current case Left(value: final failure)) return Left(failure);
      final known = current.getOrElse(() => null);
      Day? proposal;
      var suggested = const <String, DateTime?>{};
      if (known == null || replacing != null || DayRules.replaceable(known)) {
        if (known == null) {
          final saved = await _saveSetupToAccount(params.accountId);
          if (saved case Left(value: final failure)) return Left(failure);
        }
        final ranked = await _outfits.outfitsFor(params.cell);
        if (ranked case Left(value: final failure)) return Left(failure);
        final outfits = ranked.getOrElse(() => const []);
        final seen = await _days.suggested(params.accountId, [
          for (final outfit in outfits) outfit.signature,
        ]);
        if (seen case Left(value: final failure)) return Left(failure);
        suggested = seen.getOrElse(() => const {});
        final refused = await _days.refusedPieces(params.accountId);
        if (refused case Left(value: final failure)) return Left(failure);
        final picks = (await _picks.picks()).getOrElse(() => const {});
        final outfit = ChooseOutfit.from(
          outfits,
          suggested: suggested,
          picks: picks,
          refused: refused.getOrElse(() => const {}),
        );
        if (outfit == null) {
          // No outfit in this build suits the day's weather, or every one
          // has a piece whose photo the try-on refused.
          return Left(
            TryOnFailure(
              outfits.isEmpty
                  ? TryOnProblem.unavailable
                  : TryOnProblem.reference,
            ),
          );
        }
        proposal = Day(
          date: params.date,
          occasion: params.occasion,
          cell: params.cell,
          outfitId: outfit.id,
          signature: outfit.signature,
          status: DayStatus.making,
          device: _device,
        );
      }
      final claim = await _days.claim(
        params.accountId,
        date: params.date,
        occasion: params.occasion,
        proposal: proposal,
        suggested: suggested,
        device: _device,
        replacing: replacing,
      );
      if (claim case Left(value: final failure)) return Left(failure);
      final result = claim.getOrElse(() => const DayConflict());
      if (result is! DayConflict) return Right(result);
    }
    return const Left(ServerFailure());
  }

  /// A day another phone made, with its picture on this phone.
  Future<TryOnUpdate> _shown(MakeOutfitParams params, Day day) async {
    final picture = await _days.picture(params.accountId, day);
    if (picture case Left(value: final failure)) return TryOnFailed(failure);
    final outfit =
        (await _outfits.outfit(
          day.outfitId,
        )).fold<Outfit?>((_) => null, (outfit) => outfit) ??
        Outfit(
          id: day.outfitId,
          signature: day.signature,
          pieces: const [],
          passes: const [],
        );
    return TryOnDone(
      DayOutfit(
        outfit: outfit,
        date: day.date,
        occasion: day.occasion,
        cell: day.cell,
        picture: picture.getOrElse(() => throw StateError('picture')),
      ),
    );
  }

  /// Ends the making with [failure]. The try-on service's refusals are
  /// kept on the day for every phone to see; others stay with this phone,
  /// which goes on with the day next time.
  Future<TryOnUpdate> _failed(
    MakeOutfitParams params,
    Day day,
    Failure failure,
  ) async {
    if (failure case TryOnFailure(:final problem)) {
      await _days.fail(params.accountId, day, problem, device: _device);
    }
    return TryOnFailed(failure);
  }

  /// Forgets [job] and lets the service delete its tasks.
  Future<void> _drop(TryOnJob job) async {
    await _jobs.clear(job.key);
    for (final task in job.tasks) {
      unawaited(_tryOn.discard(task));
    }
  }

  /// The kept job of [params] when it can go on: for the day's outfit and
  /// the same body photo, with its pictures still downloadable. Any other
  /// is dropped.
  Future<TryOnJob?> _resumable(
    MakeOutfitParams params,
    Day day,
    UserPhoto body,
  ) async {
    final job = (await _jobs.job(
      params.key,
    )).fold<TryOnJob?>((_) => null, (job) => job);
    if (job == null) return null;
    final fresh = clock.now().difference(job.updatedAt) < pictureLifetime;
    if (fresh &&
        job.outfitId == day.outfitId &&
        job.photoRevision == body.revision) {
      return job;
    }
    await _jobs.clear(job.key);
    return null;
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
        case TryOnErrored(:final problem, :final advice):
          return Left(TryOnFailure(problem, advice: advice));
        case TryOnRunning():
          if (!clock.now().isBefore(deadline)) {
            return const Left(ServerFailure());
          }
          await Future<void>.delayed(_checkEvery);
      }
    }
  }
}
