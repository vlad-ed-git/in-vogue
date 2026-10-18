import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/home_widget_data_source.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';
import 'package:in_vogue/features/home_widget/data/repositories/home_widget_repository_impl.dart';
import 'package:in_vogue/features/home_widget/di/init.dart';

class _Scheduler implements WidgetRefreshScheduler {
  @override
  Future<void> schedule(Duration delay) async {}
}

void main() {
  HomeWidgetRepositoryImpl? widgetOn(
    TargetPlatform platform,
    AppEnvironment environment,
  ) {
    debugDefaultTargetPlatformOverride = platform;
    try {
      return platformHomeWidgetRepository(
        environment: environment,
        scheduler: _Scheduler(),
        logMessages: LogMessagesImpl(),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  test('Android has the widget in both flavors', () {
    for (final environment in AppEnvironment.values) {
      expect(widgetOn(TargetPlatform.android, environment), isNotNull);
    }
  });

  test("iPhone has it where the flavor has an App Group: development's, "
      'until production gets its own', () {
    expect(
      HomeWidgetDataSourceImpl.appGroupOf(AppEnvironment.development),
      'group.com.invogue.app.dev',
    );
    expect(widgetOn(TargetPlatform.iOS, AppEnvironment.development), isNotNull);
    expect(
      HomeWidgetDataSourceImpl.appGroupOf(AppEnvironment.production),
      isNull,
    );
    expect(widgetOn(TargetPlatform.iOS, AppEnvironment.production), isNull);
  });

  test('other platforms have none', () {
    expect(widgetOn(TargetPlatform.macOS, AppEnvironment.development), isNull);
  });
}
