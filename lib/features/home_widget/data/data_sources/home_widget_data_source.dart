import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';

/// The Android home-screen widget, through home_widget.
///
/// Every method throws [CacheException].
abstract interface class HomeWidgetDataSource {
  /// Keeps [value] under [key] where the widget reads it; null removes it.
  Future<void> save(String key, String? value);

  /// Redraws every placed widget.
  Future<void> update();

  /// Redraws every placed widget at each of [times].
  Future<void> schedule(List<DateTime> times);

  /// Whether the launcher can place the widget from the app.
  Future<bool> canPin();

  /// Asks the launcher to place the widget.
  Future<void> pin();

  /// The link of the widget tap that started the app; null otherwise.
  Future<Uri?> launchedWith();

  /// The links of widget taps while the app runs.
  Stream<Uri?> clicks();
}

class HomeWidgetDataSourceImpl implements HomeWidgetDataSource {
  const HomeWidgetDataSourceImpl();

  /// Where the widget's content is kept, as JSON.
  static const contentKey = 'in_vogue_widget';

  /// The widget's provider; qualified, because the development flavor's
  /// package name differs from the code's.
  static const provider = 'com.invogue.app.InVogueWidgetProvider';

  @override
  Future<void> save(String key, String? value) =>
      _guard(() => HomeWidget.saveWidgetData<String>(key, value));

  @override
  Future<void> update() =>
      _guard(() => HomeWidget.updateWidget(qualifiedAndroidName: provider));

  @override
  Future<void> schedule(List<DateTime> times) => _guard(
    () =>
        HomeWidget.scheduleWidgetUpdates(times, qualifiedAndroidName: provider),
  );

  @override
  Future<bool> canPin() async =>
      await _guard<bool?>(HomeWidget.isRequestPinWidgetSupported) ?? false;

  @override
  Future<void> pin() =>
      _guard(() => HomeWidget.requestPinWidget(qualifiedAndroidName: provider));

  @override
  Future<Uri?> launchedWith() =>
      _guard(HomeWidget.initiallyLaunchedFromHomeWidget);

  @override
  Stream<Uri?> clicks() => HomeWidget.widgetClicked;

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error, stack) {
      throw CacheException(error, stack);
    } on MissingPluginException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
