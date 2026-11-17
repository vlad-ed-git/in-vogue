import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';

/// How long iPhone's short refresh may run: iOS gives it about 30 seconds,
/// and runs an app that overruns less often.
const iPhoneRefreshTimeLimit = Duration(seconds: 20);

/// How long a background run makes outfits before it pauses, keeping its
/// progress: iPhone seldom gives a processing task longer than a few
/// minutes, and Android gives a worker ten.
const iPhoneOutfitTime = Duration(minutes: 4);
const androidOutfitTime = Duration(minutes: 7);

/// Routes a headless task using the build flavor when native input is absent.
Future<bool> runWidgetBackgroundTask({
  required String task,
  required Map<String, dynamic>? input,
  required String? nativeFlavor,
  required Future<bool> Function(
    AppEnvironment environment,
    bool prepareOutfits,
  )
  refresh,
  required bool isIOS,
  required LogMessages log,
}) async {
  if (task != WorkmanagerWidgetRefreshScheduler.task &&
      task != WorkmanagerWidgetRefreshScheduler.outfitTask) {
    return true;
  }
  final name =
      input?[WorkmanagerWidgetRefreshScheduler.environmentInput] ??
      nativeFlavor;
  final environment = AppEnvironment.values.asNameMap()[name];
  if (environment == null ||
      (nativeFlavor != null && environment.name != nativeFlavor)) {
    return false;
  }
  try {
    final run = refresh(
      environment,
      !isIOS || task == WorkmanagerWidgetRefreshScheduler.outfitTask,
    );
    return await (isIOS && task == WorkmanagerWidgetRefreshScheduler.task
        ? run.timeout(iPhoneRefreshTimeLimit)
        : run);
  } on Object catch (error, stack) {
    log.logError(
      callerClass: 'widgetRefreshDispatcher',
      callerMethod: 'executeTask',
      error: error,
      stackTrace: stack,
    );
    return false;
  }
}
