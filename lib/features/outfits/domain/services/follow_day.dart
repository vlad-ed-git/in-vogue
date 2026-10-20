import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';

/// Follows a day's outfit as every phone signed in to the account sees it,
/// and makes it on this phone when it needs making: when the day has none,
/// when this phone's making stopped, or when another phone's making went
/// stale. Nothing about a failure is kept: it is made again on [retry],
/// or the next time the day is followed.
class FollowDay {
  FollowDay({
    required this._days,
    required this._catalog,
    required this._makeOutfit,
    required InstallId installId,
  }) : _device = installId.value;

  final DayRepository _days;
  final OutfitCatalogRepository _catalog;
  final MakeOutfit _makeOutfit;
  final String _device;

  final _retries = <String, StreamController<void>>{};

  /// The day's outfit as it changes: progress while it is made, here or on
  /// another phone, then done or failed. Once done it stays done.
  Stream<TryOnUpdate> call(MakeOutfitParams params) {
    final out = StreamController<TryOnUpdate>();
    final retries = StreamController<void>();
    StreamSubscription<TryOnUpdate>? making;
    StreamSubscription<Object?>? watching;
    StreamSubscription<void>? retrying;
    var failedHere = false;
    var done = false;

    void emit(TryOnUpdate update) {
      if (done || out.isClosed) return;
      if (update is TryOnDone) done = true;
      out.add(update);
    }

    void make() {
      final previous = making;
      making = _makeOutfit(params).listen((update) {
        if (update is TryOnFailed) failedHere = true;
        if (update is! TryOnElsewhere) emit(update);
      });
      unawaited(previous?.cancel());
    }

    Future<void> follow(Day? day) async {
      if (day == null) {
        if (!failedHere) make();
        return;
      }
      switch (day.status) {
        case DayStatus.ready:
          emit(await _done(params, day));
        case DayStatus.making when day.device == _device:
          // Its updates come from the making here, started anew when the
          // making on this phone stopped.
          if (making == null && !failedHere) make();
        case DayStatus.making when DayRules.stale(day, clock.now()):
          if (!failedHere) make();
        case DayStatus.making:
          emit(TryOnProgress(piece: day.piece, pieces: day.pieces));
      }
    }

    out
      ..onListen = () {
        _retries[params.key] = retries;
        retrying = retries.stream.listen((_) {
          failedHere = false;
          make();
        });
        watching = _days
            .watch(
              params.accountId,
              date: params.date,
              occasion: params.occasion,
            )
            .asyncMap(
              (watched) => watched.fold(
                (failure) async => emit(TryOnFailed(failure)),
                follow,
              ),
            )
            .listen(null);
      }
      ..onCancel = () async {
        if (_retries[params.key] == retries) _retries.remove(params.key);
        await Future.wait([
          ?watching?.cancel(),
          ?making?.cancel(),
          ?retrying?.cancel(),
        ]);
        await retries.close();
      };
    return out.stream;
  }

  /// Makes [params]'s day again on the phone following it, after a
  /// failure.
  void retry(MakeOutfitParams params) => _retries[params.key]?.add(null);

  /// A made day, with its picture on this phone.
  Future<TryOnUpdate> _done(MakeOutfitParams params, Day day) async {
    final picture = await _days.picture(params.accountId, day);
    if (picture case Left(value: final failure)) return TryOnFailed(failure);
    final outfits = (await _catalog.outfits()).getOrElse(() => const []);
    return TryOnDone(
      DayOutfit(
        outfitId: day.outfitId,
        outfit: outfits
            .where((outfit) => outfit.id == day.outfitId)
            .firstOrNull,
        date: day.date,
        occasion: day.occasion,
        picture: picture.getOrElse(() => throw StateError('picture')),
        reason: day.reason,
      ),
    );
  }
}
