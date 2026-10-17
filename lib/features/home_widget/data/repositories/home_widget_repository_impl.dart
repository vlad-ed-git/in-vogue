import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/models/widget_content_model.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';

/// The Android home-screen widget: it shows the content kept for it and
/// picks its day itself, redrawn at each turn of the day.
class HomeWidgetRepositoryImpl implements HomeWidgetRepository {
  HomeWidgetRepositoryImpl({
    required HomeWidgetDataSource dataSource,
    required LogMessages logMessages,
  }) : _widget = dataSource,
       _logger = logMessages;

  final HomeWidgetDataSource _widget;
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
  Future<Either<Failure, Unit>> publish(WidgetContent content) =>
      _guard('publish', () async {
        await _widget.save(
          HomeWidgetDataSourceImpl.contentKey,
          jsonEncode(WidgetContentModel.toJson(content)),
        );
        await _widget.update();
        await _widget.schedule(WidgetSchedule.changesAfter(clock.now()));
      });

  @override
  Future<Either<Failure, Unit>> clear() => _guard('clear', () async {
    await _widget.save(HomeWidgetDataSourceImpl.contentKey, null);
    await _widget.update();
  });

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
