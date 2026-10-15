// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'In Vogue';

  @override
  String get tagline => '以时尚穿搭，迎接明天的天气。';

  @override
  String get welcomeDescription => '穿搭随天气，妆容配风格。';

  @override
  String get language => '语言';

  @override
  String get cacheFailure => '无法保存更改，请重试。';

  @override
  String get networkFailure => '网络已断开，请检查网络连接。';

  @override
  String get serverFailure => '出现了一些问题，请重试。';

  @override
  String get startupFailure => 'In Vogue 无法启动，请重试。';

  @override
  String get retry => '重试';
}
