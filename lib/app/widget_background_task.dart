import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';

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
    return await refresh(
      environment,
      !isIOS || task == WorkmanagerWidgetRefreshScheduler.outfitTask,
    );
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
