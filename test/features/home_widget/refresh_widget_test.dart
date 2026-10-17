import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/services/refresh_widget.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'refresh_widget_test.mocks.dart';

final _today = DateTime.utc(2026, 10, 18);
final _tomorrow = DateTime.utc(2026, 10, 19);
const _paris = UserLocation(
  latitude: 48.86,
  longitude: 2.35,
  countryCode: 'FR',
);

final _context = WidgetRefreshContext(
  place: _paris,
  language: SupportedLanguages.spanish,
  preferred: ForecastDay.tomorrow,
  bodyPhoto: '/photos/body-1.jpg',
  occasions: {_tomorrow: Occasion.goingOut},
);

const _outfit = Outfit(
  id: 'o1',
  signature: 'tee',
  pieces: [],
  passes: [],
  reasons: {'mild|dry|calm|casual': LocalizedText('A tee.')},
);

final _made = Day(
  date: _today,
  occasion: Occasion.casual,
  cell: 'mild|dry|calm|casual',
  outfitId: 'o1',
  signature: 'tee',
  status: DayStatus.ready,
  device: 'phone-b',
  picturePath: 'users/uid-1/days/2026-10-18_casual.jpg',
);

const _content = WidgetContent(
  days: [],
  preferred: ForecastDay.tomorrow,
  savedLine: 'Guardado',
);

WeatherReport _report(ForecastDay day, Occasion occasion) => WeatherReport(
  day: day,
  weather: DayWeather(
    date: day == ForecastDay.today ? _today : _tomorrow,
    occasion: occasion,
    temperature: 17,
    feelsLike: 16,
    sky: Sky.clear,
  ),
  weatherClass: const WeatherClass(
    band: WarmthBand.mild,
    precipitation: Precipitation.dry,
    windy: false,
  ),
  fetchedAt: DateTime.utc(2026, 10, 18, 4),
  isSaved: false,
);

@GenerateMocks([
  GetWeatherReport,
  DayRepository,
  OutfitRepository,
  HomeWidgetRepository,
])
void main() {
  late MockGetWeatherReport weather;
  late MockDayRepository days;
  late MockOutfitRepository outfits;
  late MockHomeWidgetRepository widget;
  late List<WidgetDay> described;

  RefreshWidget refresh({String? accountId = 'uid-1'}) => RefreshWidget(
    getWeatherReport: weather,
    days: days,
    outfits: outfits,
    widget: widget,
    accountId: accountId,
    describe: (widgetDays, context) {
      described = widgetDays;
      return _content;
    },
  );

  setUp(() {
    weather = MockGetWeatherReport();
    days = MockDayRepository();
    outfits = MockOutfitRepository();
    widget = MockHomeWidgetRepository();
    described = [];
    when(weather(any)).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as WeatherReportParams;
      final day = params.day!;
      final date = day == ForecastDay.today ? _today : _tomorrow;
      return Right(
        _report(day, params.chosen[date] ?? Occasion.defaultFor(date)),
      );
    });
    when(
      days.day(any, date: anyNamed('date'), occasion: anyNamed('occasion')),
    ).thenAnswer(
      (invocation) async =>
          Right(invocation.namedArguments[#date] == _today ? _made : null),
    );
    when(days.picture(any, any)).thenAnswer(
      (_) async => const Right('/phone/outfits/uid-1/2026-10-18_casual.jpg'),
    );
    when(outfits.outfit(any)).thenAnswer((_) async => const Right(_outfit));
    when(widget.publish(any)).thenAnswer((_) async => const Right(unit));
  });

  test("refreshes both days' weather, each in its own occasion, and fetches "
      'a picture already made', () async {
    await refresh()(_context);
    verify(
      weather(
        WeatherReportParams(
          location: _paris,
          day: ForecastDay.today,
          chosen: _context.occasions,
        ),
      ),
    ).called(1);
    final [today, tomorrow] = described;
    expect(today.report.weather.occasion, Occasion.casual);
    expect(today.outfit?.picture, '/phone/outfits/uid-1/2026-10-18_casual.jpg');
    expect(today.outfit?.outfit, _outfit);
    expect(tomorrow.report.weather.occasion, Occasion.goingOut);
    expect(tomorrow.outfit, isNull);
    verify(days.picture('uid-1', _made)).called(1);
    verify(widget.publish(_content)).called(1);
  });

  test('without an account it refreshes only the weather', () async {
    await refresh(accountId: null)(_context);
    expect([for (final day in described) day.outfit], [null, null]);
    verifyZeroInteractions(days);
    verify(widget.publish(_content)).called(1);
  });

  test('keeps what the widget shows when there is no weather', () async {
    when(weather(any)).thenAnswer((_) async => const Left(NetworkFailure()));
    await refresh()(_context);
    verifyNever(widget.publish(any));
  });
}
