import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';

/// Turns the widget's days into the content it shows, in the person's
/// language.
typedef DescribeWidget =
    WidgetContent Function(List<WidgetDay> days, WidgetRefreshContext context);

/// The morning refresh: today's and tomorrow's weather again, each day in
/// its own occasion, with the picture of a day already made, on another
/// phone too, fetched when the phone lacks it. It never makes an outfit.
class RefreshWidget {
  RefreshWidget({
    required this._getWeatherReport,
    required this._days,
    required this._outfits,
    required this._widget,
    required this._accountId,
    required this._describe,
  });

  final GetWeatherReport _getWeatherReport;
  final DayRepository _days;
  final OutfitRepository _outfits;
  final HomeWidgetRepository _widget;
  final String? _accountId;
  final DescribeWidget _describe;

  /// Redraws the widget; without any weather it keeps what it shows.
  Future<void> call(WidgetRefreshContext context) async {
    final days = <WidgetDay>[];
    for (final day in ForecastDay.values) {
      final report = (await _getWeatherReport(
        WeatherReportParams(
          location: context.place,
          day: day,
          chosen: context.occasions,
        ),
      )).fold<WeatherReport?>((_) => null, (report) => report);
      if (report == null) continue;
      days.add((report: report, outfit: await _made(report)));
    }
    if (days.isEmpty) return;
    await _widget.publish(_describe(days, context));
  }

  /// The outfit of [report]'s day once made, its picture on the phone.
  Future<DayOutfit?> _made(WeatherReport report) async {
    final accountId = _accountId;
    if (accountId == null) return null;
    final day = (await _days.day(
      accountId,
      date: report.weather.date,
      occasion: report.weather.occasion,
    )).fold<Day?>((_) => null, (day) => day);
    if (day == null || day.status != DayStatus.ready) return null;
    final picture = (await _days.picture(
      accountId,
      day,
    )).fold<String?>((_) => null, (picture) => picture);
    if (picture == null) return null;
    final outfit =
        (await _outfits.outfit(
          day.outfitId,
        )).fold<Outfit?>((_) => null, (outfit) => outfit) ??
        Outfit(
          id: day.outfitId,
          signature: day.signature,
          pieces: const [],
          passes: const [],
        );
    return DayOutfit(
      outfit: outfit,
      date: day.date,
      occasion: day.occasion,
      cell: day.cell,
      picture: picture,
    );
  }
}
