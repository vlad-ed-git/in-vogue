import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:in_vogue/core/config/app_environment.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';

/// The home-screen widget on Android and iPhone, through home_widget.
///
/// Every method throws [CacheException].
abstract interface class HomeWidgetDataSource {
  /// Keeps [value] under [key] where the widget reads it; null removes it.
  Future<void> save(String key, String? value);

  /// What is kept under [key]; null when nothing is.
  Future<String?> read(String key);

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
  /// [appGroupId] is the App Group the iPhone widget reads; null on Android.
  HomeWidgetDataSourceImpl({this._appGroupId});

  final String? _appGroupId;
  bool _grouped = false;

  /// Where the widget's content is kept, as JSON.
  static const contentKey = 'in_vogue_widget';

  /// Where what the morning refresh needs is kept, as JSON.
  static const refreshKey = 'in_vogue_widget_refresh';

  /// The widget's provider; qualified, because the development flavor's
  /// package name differs from the code's.
  static const provider = 'com.invogue.app.InVogueWidgetProvider';

  /// The iPhone widget's kind (`InVogueWidget.swift`).
  static const iOSKind = 'InVogueWidget';

  /// The App Group each flavor shares with the iPhone widget. Production has
  /// none yet: its entitlements still name development's group.
  static String? appGroupOf(AppEnvironment environment) =>
      switch (environment) {
        AppEnvironment.development => 'group.com.invogue.app.dev',
        AppEnvironment.production => null,
      };

  @override
  Future<void> save(String key, String? value) => _guard(() async {
    await _useGroup();
    await HomeWidget.saveWidgetData<String>(key, value);
  });

  @override
  Future<String?> read(String key) => _guard(() async {
    await _useGroup();
    return HomeWidget.getWidgetData<String>(key);
  });

  @override
  Future<void> update() => _guard(
    () => HomeWidget.updateWidget(
      qualifiedAndroidName: provider,
      iOSName: iOSKind,
    ),
  );

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

  /// On iPhone, home_widget keeps everything in the App Group, named once
  /// for each isolate.
  Future<void> _useGroup() async {
    final group = _appGroupId;
    if (group == null || _grouped) return;
    await HomeWidget.setAppGroupId(group);
    _grouped = true;
  }

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
