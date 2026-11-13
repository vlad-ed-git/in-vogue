import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_picture_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/data/models/widget_content_model.dart';
import 'package:in_vogue/features/home_widget/data/models/widget_refresh_context_model.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';

/// The home-screen widget on Android and iPhone: it shows the content kept
/// for it, with the day's pictures where it can read them, and picks its day
/// itself. It changes at midnight and refreshes in the background.
class HomeWidgetRepositoryImpl implements HomeWidgetRepository {
  HomeWidgetRepositoryImpl({
    required HomeWidgetDataSource dataSource,
    required this._pictures,
    required this._scheduler,
    required this._environment,
    required LogMessages logMessages,
    this.canPublish,
  }) : _widget = dataSource,
       _logger = logMessages;

  final Future<bool> Function()? canPublish;
  final HomeWidgetDataSource _widget;
  final WidgetPictureDataSource _pictures;
  final WidgetRefreshScheduler _scheduler;

  /// The flavor's name, kept for the morning refresh's Firebase.
  final String _environment;
  final LogMessages _logger;

  @override
  Future<bool> requestPin() async {
    try {
      if (!await _widget.canPin()) return false;
      await _widget.pin();
      return true;
    } on CacheException catch (error) {
      _log('requestPin', error);
      return false;
    }
  }

  /// The publish under way; the next one waits for it, so two never share
  /// pictures into the same folder at once.
  Future<void> _publishing = Future.value();

  @override
  Future<Either<Failure, Unit>> publish(
    WidgetContent content, {
    WidgetRefreshContext? refresh,
  }) {
    final published = _publishing.then(
      (_) => _publish(content, refresh: refresh),
    );
    _publishing = published.then<void>((_) {}, onError: (Object _) {});
    return published;
  }

  Future<Either<Failure, Unit>> _publish(
    WidgetContent content, {
    WidgetRefreshContext? refresh,
  }) => _guard('publish', () async {
    if (canPublish != null && !await canPublish!()) return;
    final now = clock.now();
    final previousRefresh = await savedRefresh();
    final samePerson =
        refresh == null ||
        (previousRefresh?.context.accountId == refresh.accountId &&
            previousRefresh?.context.bodyPhoto == refresh.bodyPhoto &&
            previousRefresh?.context.bodyPhotoRevision ==
                refresh.bodyPhotoRevision &&
            previousRefresh?.context.place == refresh.place &&
            previousRefresh?.context.language == refresh.language);
    WidgetContent? previous;
    if (samePerson) {
      final json = await _widget.read(HomeWidgetDataSourceImpl.contentKey);
      if (json != null) {
        try {
          previous = WidgetContentModel.fromJson(jsonDecode(json));
        } on FormatException {
          // An unreadable snapshot is replaced by the current results.
        }
      }
    }
    content = content.keeping(
      previous,
      today: DateTime.utc(now.year, now.month, now.day),
    );
    if (refresh != null) {
      await _widget.save(
        HomeWidgetDataSourceImpl.refreshKey,
        jsonEncode(
          WidgetRefreshContextModel.toJson(refresh, environment: _environment),
        ),
      );
      await _scheduler.schedule(WidgetSchedule.untilRefresh(now));
    }
    final shared = await _pictures.share({
      for (final day in content.days) ...[?day.picture, ?day.waitingPhoto],
    });
    if (canPublish != null && !await canPublish!()) return;
    await _widget.save(
      HomeWidgetDataSourceImpl.contentKey,
      jsonEncode(
        WidgetContentModel.toJson(content, picturePath: (path) => shared[path]),
      ),
    );
    await _widget.update();
    await _widget.schedule(WidgetSchedule.changesAfter(now));
  });

  /// What the morning refresh needs and the flavor that kept it; null
  /// before the app kept it.
  Future<({String environment, WidgetRefreshContext context})?>
  savedRefresh() async {
    try {
      final json = await _widget.read(HomeWidgetDataSourceImpl.refreshKey);
      return json == null
          ? null
          : WidgetRefreshContextModel.fromJson(jsonDecode(json));
    } on CacheException catch (error) {
      _log('savedRefresh', error);
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Either<Failure, Unit>> clear() {
    final cleared = _publishing.then((_) => _clear());
    _publishing = cleared.then<void>((_) {}, onError: (Object _) {});
    return cleared;
  }

  Future<Either<Failure, Unit>> _clear() async {
    var failed = false;
    for (final action in <Future<void> Function()>[
      () => _widget.save(HomeWidgetDataSourceImpl.refreshKey, null),
      _scheduler.cancel,
      () => _widget.save(HomeWidgetDataSourceImpl.contentKey, null),
      _widget.update,
      _pictures.clear,
    ]) {
      try {
        await action();
      } on CacheException catch (error) {
        failed = true;
        _log('clear', error);
      }
    }
    return failed ? const Left(CacheFailure()) : const Right(unit);
  }

  @override
  Stream<WidgetTap> taps() async* {
    Uri? first;
    try {
      first = await _widget.launchedWith();
    } on CacheException catch (error) {
      _log('taps', error);
    }
    if (WidgetContentModel.tapOf(first) case final tap?) yield tap;
    await for (final link in _widget.clicks()) {
      if (WidgetContentModel.tapOf(link) case final tap?) yield tap;
    }
  }

  Future<Either<Failure, Unit>> _guard(
    String method,
    Future<void> Function() call,
  ) async {
    try {
      await call();
      return const Right(unit);
    } on CacheException catch (error) {
      _log(method, error);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, CacheException error) => _logger.logError(
    callerClass: 'HomeWidgetRepositoryImpl',
    callerMethod: method,
    error: error.cause,
    stackTrace: error.stackTrace,
  );
}
