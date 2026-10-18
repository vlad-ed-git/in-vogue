import 'package:flutter/services.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:workmanager/workmanager.dart';

/// Runs the widget's morning refresh in the background: through WorkManager
/// on Android, and background app refresh on iPhone, which picks the time
/// itself.
///
/// Every method throws [CacheException].
abstract interface class WidgetRefreshScheduler {
  /// Runs the refresh once a day, the first in [delay]; a refresh already
  /// scheduled stays as it is.
  Future<void> schedule(Duration delay);
}

class WorkmanagerWidgetRefreshScheduler implements WidgetRefreshScheduler {
  WorkmanagerWidgetRefreshScheduler(
    this._dispatcher, {
    required this._environment,
  });

  /// The background entry point that runs the refresh.
  final void Function() _dispatcher;

  /// The flavor's name, handed to the refresh as [environmentInput].
  final String _environment;
  bool _initialized = false;

  static const task = 'in_vogue_widget_refresh';

  /// The input naming the flavor that scheduled the refresh.
  static const environmentInput = 'environment';

  @override
  Future<void> schedule(Duration delay) async {
    try {
      if (!_initialized) {
        await Workmanager().initialize(_dispatcher);
        _initialized = true;
      }
      await Workmanager().registerPeriodicTask(
        task,
        task,
        frequency: const Duration(days: 1),
        initialDelay: delay,
        inputData: {environmentInput: _environment},
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } on PlatformException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
