import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/data/models/widget_content_model.dart';
import 'package:in_vogue/features/home_widget/data/models/widget_refresh_context_model.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';

/// The Android home-screen widget: it shows the content kept for it and
/// picks its day itself, redrawn at each turn of the day and refreshed each
/// morning in the background.
class HomeWidgetRepositoryImpl implements HomeWidgetRepository {
  HomeWidgetRepositoryImpl({
    required HomeWidgetDataSource dataSource,
    required this._scheduler,
    required this._environment,
    required LogMessages logMessages,
  }) : _widget = dataSource,
       _logger = logMessages;

  final HomeWidgetDataSource _widget;
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

  @override
  Future<Either<Failure, Unit>> publish(
    WidgetContent content, {
    WidgetRefreshContext? refresh,
  }) => _guard('publish', () async {
    await _widget.save(
      HomeWidgetDataSourceImpl.contentKey,
      jsonEncode(WidgetContentModel.toJson(content)),
    );
    await _widget.update();
    final now = clock.now();
    await _widget.schedule(WidgetSchedule.changesAfter(now));
    if (refresh == null) return;
    await _widget.save(
      HomeWidgetDataSourceImpl.refreshKey,
      jsonEncode(
        WidgetRefreshContextModel.toJson(refresh, environment: _environment),
      ),
    );
    await _scheduler.schedule(WidgetSchedule.untilRefresh(now));
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
  Future<Either<Failure, Unit>> clear() => _guard('clear', () async {
    await _widget.save(HomeWidgetDataSourceImpl.contentKey, null);
    await _widget.update();
  });

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
