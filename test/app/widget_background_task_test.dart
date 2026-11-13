import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/app/widget_background_task.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_refresh_scheduler.dart';

void main() {
  Future<bool> run({
    String task = WorkmanagerWidgetRefreshScheduler.task,
    Map<String, dynamic>? input,
    String? flavor = 'development',
    bool isIOS = false,
    required Future<bool> Function(AppEnvironment, bool) refresh,
  }) => runWidgetBackgroundTask(
    task: task,
    input: input,
    nativeFlavor: flavor,
    refresh: refresh,
    isIOS: isIOS,
    log: LogMessagesImpl(),
  );

  test(
    'a cold launch without input uses the build flavor and prepares outfits',
    () async {
      expect(
        await run(
          refresh: (environment, prepare) async {
            expect(environment, AppEnvironment.development);
            expect(prepare, isTrue);
            return true;
          },
        ),
        isTrue,
      );
    },
  );

  test('iOS reserves generation for the processing task', () async {
    for (final task in [
      WorkmanagerWidgetRefreshScheduler.task,
      WorkmanagerWidgetRefreshScheduler.outfitTask,
    ]) {
      await run(
        task: task,
        isIOS: true,
        refresh: (_, prepare) async {
          expect(prepare, task == WorkmanagerWidgetRefreshScheduler.outfitTask);
          return true;
        },
      );
    }
  });

  test(
    'failed work requests retry, including thrown initialization errors',
    () async {
      expect(await run(refresh: (_, _) async => false), isFalse);
      expect(
        await run(refresh: (_, _) async => throw StateError('offline')),
        isFalse,
      );
    },
  );

  test(
    'unknown tasks and mismatched flavors never run Firebase or YouCam',
    () async {
      var calls = 0;
      Future<bool> refresh(AppEnvironment _, bool _) async {
        calls++;
        return true;
      }

      expect(await run(task: 'other', refresh: refresh), isTrue);
      expect(
        await run(input: {'environment': 'production'}, refresh: refresh),
        isFalse,
      );
      expect(await run(flavor: null, refresh: refresh), isFalse);
      expect(calls, 0);
    },
  );
}
