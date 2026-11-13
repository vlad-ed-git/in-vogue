import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/home_widget/domain/repositories/home_widget_repository.dart';
import 'package:in_vogue/features/home_widget/domain/services/refresh_widget.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_pass.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/catalog_outfits.dart';
import '../../helpers/day_bands.dart';

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
  accountId: 'uid-1',
  bodyPhotoRevision: 1,
  bodyPhoto: '/photos/body-1.jpg',
  occasions: {_tomorrow: Occasion.goingOut},
);

final _outfit = outfitOf('o1', const [
  ('everlane:tee', GarmentCategory.upperBody, 'tee'),
]);

final _reason = OutfitReason(
  kind: ReasonKind.steady,
  coldest: 15,
  coldestAt: DateTime.utc(2026, 10, 18, 9),
  warmest: 18,
  warmestAt: DateTime.utc(2026, 10, 18, 14),
);

final _made = Day(
  date: _today,
  occasion: Occasion.casual,
  outfitId: 'o1',
  status: DayStatus.ready,
  device: 'phone-b',
  picturePath: 'users/uid-1/days/2026-10-18_casual.jpg',
  reason: _reason,
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
  bands: bandsFor(WarmthBand.mild),
  fetchedAt: DateTime.utc(2026, 10, 18, 4),
  isSaved: false,
);

@GenerateMocks([
  GetWeatherReport,
  DayRepository,
  OutfitCatalogRepository,
  HomeWidgetRepository,
])
void main() {
  late MockGetWeatherReport weather;
  late MockDayRepository days;
  late MockOutfitCatalogRepository outfits;
  late MockHomeWidgetRepository widget;
  late List<WidgetDay> described;

  RefreshWidget refresh({
    String? accountId = 'uid-1',
    Stream<TryOnUpdate> Function(MakeOutfitParams)? makeOutfit,
    Future<bool> Function()? stillCurrent,
    bool lookAhead = false,
  }) => RefreshWidget(
    makeOutfit: makeOutfit,
    lookAhead: lookAhead,
    stillCurrent: stillCurrent,
    getWeatherReport: weather,
    days: days,
    catalog: outfits,
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
    outfits = MockOutfitCatalogRepository();
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
    when(days.day(any, date: anyNamed('date'), occasion: anyNamed('occasion')))
        .thenAnswer(
          (invocation) async =>
              Right(invocation.namedArguments[#date] == _today ? _made : null),
        );
    when(days.picture(any, any)).thenAnswer(
      (_) async => const Right('/phone/outfits/uid-1/2026-10-18_casual.jpg'),
    );
    when(outfits.outfits()).thenAnswer((_) async => Right([_outfit]));
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
    expect(today.outfit?.reason, _reason);
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
    expect(await refresh()(_context), isFalse);
    verifyNever(widget.publish(any));
  });

  test(
    'prepares a missing day and publishes the result without opening Home',
    () async {
      final made = <MakeOutfitParams>[];
      expect(
        await refresh(
          makeOutfit: (params) async* {
            made.add(params);
            yield TryOnDone(
              DayOutfit(
                outfitId: 'o1',
                outfit: _outfit,
                date: params.date,
                occasion: params.occasion,
                picture: '/new-outfit.jpg',
              ),
            );
          },
        )(_context),
        isTrue,
      );
      expect(made, [
        MakeOutfitParams(
          accountId: 'uid-1',
          date: _tomorrow,
          occasion: Occasion.goingOut,
          bands: bandsFor(WarmthBand.mild),
        ),
      ]);
      expect(described.last.outfit?.picture, '/new-outfit.jpg');
      verify(widget.publish(_content)).called(2);
    },
  );

  test(
    'a failed try-on keeps the weather and asks the scheduler to retry',
    () async {
      expect(
        await refresh(
          makeOutfit: (_) => Stream.value(const TryOnFailed(NetworkFailure())),
        )(_context),
        isFalse,
      );
      expect(described.first.outfit?.picture, isNotNull);
      verify(widget.publish(_content)).called(1);
    },
  );

  test(
    'does not publish or make outfits after logout or a context change',
    () async {
      var made = false;
      expect(
        await refresh(
          stillCurrent: () async => false,
          makeOutfit: (_) async* {
            made = true;
          },
        )(_context),
        isTrue,
      );
      expect(made, isFalse);
      verifyNever(widget.publish(any));
    },
  );

  test('a publish failure is reported for retry', () async {
    when(widget.publish(any))
        .thenAnswer((_) async => const Left(CacheFailure()));
    expect(await refresh()(_context), isFalse);
  });
  test(
    'prepares the preferred day first and keeps another day for midnight',
    () async {
      final third = _tomorrow.add(const Duration(days: 1));
      when(
        days.day(any, date: anyNamed('date'), occasion: anyNamed('occasion')),
      ).thenAnswer((_) async => const Right(null));
      when(weather(any)).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.single as WeatherReportParams;
        final date =
            params.date ??
            (params.day == ForecastDay.today ? _today : _tomorrow);
        return Right(
          WeatherReport(
            day: params.day!,
            weather: DayWeather(
              date: date,
              occasion: Occasion.casual,
              temperature: 17,
              feelsLike: 16,
              sky: Sky.clear,
            ),
            bands: bandsFor(WarmthBand.mild),
            fetchedAt: _today,
            isSaved: false,
          ),
        );
      });
      final made = <DateTime>[];
      expect(
        await refresh(
          lookAhead: true,
          makeOutfit: (params) async* {
            made.add(params.date);
            yield TryOnDone(
              DayOutfit(
                outfitId: 'o1',
                outfit: _outfit,
                date: params.date,
                occasion: params.occasion,
                picture: '/new-${params.date.day}.jpg',
              ),
            );
          },
        )(_context),
        isTrue,
      );
      expect(made, [_tomorrow, _today, third]);
      expect(described.map((day) => day.report.weather.date), [
        _today,
        _tomorrow,
        third,
      ]);
      expect(described.every((day) => day.outfit != null), isTrue);
    },
  );
}
