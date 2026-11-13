import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';

/// Turns the widget's days into the content it shows, in the person's
/// language.
typedef DescribeWidget = WidgetContent Function(
  List<WidgetDay> days,
  WidgetRefreshContext context,
);

/// Refreshes both days and optionally prepares their missing outfits.
class RefreshWidget {
  RefreshWidget({
    required this._getWeatherReport,
    required this._days,
    required this._catalog,
    required this._widget,
    required this._accountId,
    required this._describe,
    this._makeOutfit,
    this._stillCurrent,
    this.lookAhead = false,
    this.loadOutfits = true,
  });

  final GetWeatherReport _getWeatherReport;
  final DayRepository _days;
  final OutfitCatalogRepository _catalog;
  final HomeWidgetRepository _widget;
  final String? _accountId;
  final DescribeWidget _describe;
  final bool lookAhead;
  final bool loadOutfits;
  final Stream<TryOnUpdate> Function(MakeOutfitParams)? _makeOutfit;
  final Future<bool> Function()? _stillCurrent;

  Future<bool> _current() async => await _stillCurrent?.call() ?? true;

  /// Redraws the widget; without any weather it keeps what it shows.
  Future<bool> call(WidgetRefreshContext context) async {
    if (!await _current()) return true;
    final days = <WidgetDay>[];
    var complete = true;
    for (final day in ForecastDay.values) {
      final report = (await _getWeatherReport(
        WeatherReportParams(
          location: context.place,
          day: day,
          chosen: context.occasions,
        ),
      )).fold<WeatherReport?>((_) => null, (report) => report);
      if (report == null) {
        complete = false;
        continue;
      }
      days.add((
        report: report,
        outfit: loadOutfits ? await _made(report) : null,
      ));
    }
    if (lookAhead && days.isNotEmpty) {
      final first = days.first.report;
      final date = first.weather.date.add(
        Duration(days: first.day == ForecastDay.today ? 2 : 1),
      );
      final next = (await _getWeatherReport(
        WeatherReportParams(
          location: context.place,
          day: ForecastDay.tomorrow,
          date: date,
          chosen: context.occasions,
        ),
      )).fold<WeatherReport?>((_) => null, (report) => report);
      if (next != null) {
        days.add((
          report: next,
          outfit: loadOutfits ? await _made(next) : null,
        ));
      } else {
        complete = false;
      }
    }
    if (days.isEmpty) return false;
    if (!await _current()) return true;
    if ((await _widget.publish(_describe(days, context))).isLeft()) {
      complete = false;
    }
    final make = _makeOutfit;
    final account = _accountId;
    if (make == null || account == null) return complete;
    final order = [for (var i = 0; i < days.length; i++) i];
    final preferred = days.indexWhere(
      (day) => day.report.day == context.preferred,
    );
    if (preferred > 0) {
      order
        ..remove(preferred)
        ..insert(0, preferred);
    }
    for (final index in order) {
      if (!await _current()) return true;
      final day = days[index];
      if (day.outfit != null) continue;
      final result = await make(
        MakeOutfitParams(
          accountId: account,
          date: day.report.weather.date,
          occasion: day.report.weather.occasion,
          bands: day.report.bands,
        ),
      ).last;
      if (result case TryOnDone(:final outfit)) {
        days[index] = (report: day.report, outfit: outfit);
        if (!await _current()) return true;
        if ((await _widget.publish(_describe(days, context))).isLeft()) {
          complete = false;
        }
      } else {
        complete = false;
        if (result is TryOnPaused) break;
      }
    }
    return complete;
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
    final outfits = (await _catalog.outfits()).getOrElse(() => const []);
    return DayOutfit(
      outfitId: day.outfitId,
      outfit: outfits.where((outfit) => outfit.id == day.outfitId).firstOrNull,
      date: day.date,
      occasion: day.occasion,
      picture: picture,
      reason: day.reason,
    );
  }
}
