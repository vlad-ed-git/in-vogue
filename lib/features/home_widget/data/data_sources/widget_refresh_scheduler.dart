import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/domain/services/widget_schedule.dart';
import 'package:workmanager/workmanager.dart';

/// Schedules weather refresh and outfit preparation on the native scheduler.
///
/// Every method throws [CacheException].
abstract interface class WidgetRefreshScheduler {
  /// Registers periodic work, requesting the first run after [delay].
  Future<void> schedule(Duration delay);

  Future<void> cancel();
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
  static const outfitTask = 'in_vogue_outfit_prepare';
  static const retryDelay = Duration(minutes: 15);

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
        frequency: WidgetSchedule.refreshEvery,
        initialDelay: delay,
        inputData: {environmentInput: _environment},
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: retryDelay,
      );
      await scheduleOutfits(delay);
    } on PlatformException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  /// iOS gives processing tasks longer than its short weather refresh.
  Future<void> scheduleOutfits(Duration delay) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await Workmanager().registerProcessingTask(
        outfitTask,
        outfitTask,
        initialDelay: delay,
        inputData: {environmentInput: _environment},
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } on PlatformException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await Workmanager().cancelByUniqueName(task);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Workmanager().cancelByUniqueName(outfitTask);
      }
    } on PlatformException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
