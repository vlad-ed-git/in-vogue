import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';
import 'package:in_vogue/features/home_widget/presentation/widget_content_text.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

final _today = DateTime.utc(2026, 10, 18);
final _tomorrow = DateTime.utc(2026, 10, 19);
const _cell = 'cool|wet|calm|work';

WeatherReport _report(DateTime date, ForecastDay day) => WeatherReport(
  day: day,
  weather: DayWeather(
    date: date,
    occasion: Occasion.work,
    temperature: 12.4,
    feelsLike: 9.6,
    sky: Sky.rain,
  ),
  weatherClass: const WeatherClass(
    band: WarmthBand.cool,
    precipitation: Precipitation.wet,
    windy: false,
  ),
  fetchedAt: DateTime.utc(2026, 10, 18, 5),
  isSaved: false,
);

final _outfit = DayOutfit(
  outfit: const Outfit(
    id: 'o1',
    signature: 'coat+tee',
    pieces: [],
    passes: [],
    reasons: {
      _cell: LocalizedText(
        'A coat over a tee.',
        translations: {'es': 'Un abrigo sobre una camiseta.'},
      ),
    },
  ),
  date: _today,
  occasion: Occasion.work,
  cell: _cell,
  picture: '/support/outfits/uid-1/2026-10-18_work.jpg',
);

void main() {
  setUpAll(initializeDateFormatting);

  test("writes each day's words in the person's language, with its picture "
      'once made and the photo waiting until then', () {
    final l10n = lookupAppLocalizations(const Locale('es'));
    final content = WidgetContentText.of(
      days: [
        (report: _report(_today, ForecastDay.today), outfit: _outfit),
        (report: _report(_tomorrow, ForecastDay.tomorrow), outfit: null),
      ],
      preferred: ForecastDay.tomorrow,
      countryCode: 'ES',
      bodyPhoto: '/support/photos/body-1.jpg',
      l10n: l10n,
      language: SupportedLanguages.spanish,
      now: DateTime(2026, 10, 18, 21, 12),
    );
    expect(content.preferred, ForecastDay.tomorrow);
    expect(
      content.savedLine,
      l10n.widgetSaved(l10n.savedAt('dom 18 oct', '21:12')),
    );
    final [made, waiting] = content.days;
    expect(made.date, _today);
    expect(made.today, l10n.today);
    expect(made.tomorrow, l10n.tomorrow);
    expect(
      made.dateLine,
      '${InVogueFormat.shortDate(_today, 'es')} · '
      '${Occasion.work.kicker(l10n)}',
    );
    expect(made.temperature, 12);
    expect(made.feelsLike, l10n.feelsLike(10));
    expect(made.glyph, 'cloud-rain');
    expect(made.picture, _outfit.picture);
    expect(made.waitingPhoto, isNull);
    expect(made.spokenToday, startsWith(l10n.today));
    expect(made.spokenToday, endsWith('Un abrigo sobre una camiseta.'));
    expect(waiting.picture, isNull);
    expect(waiting.waitingPhoto, '/support/photos/body-1.jpg');
    expect(waiting.gettingReady, l10n.widgetGettingReady);
    expect(
      waiting.spokenTomorrow,
      l10n.widgetPreviewSpoken(
        l10n.weatherSpokenWithDay(l10n.tomorrow, 12, waiting.condition, 10),
      ),
    );
  });

  test('gives temperatures in the unit of where the person is', () {
    final content = WidgetContentText.of(
      days: [(report: _report(_today, ForecastDay.today), outfit: null)],
      preferred: ForecastDay.today,
      countryCode: 'US',
      bodyPhoto: null,
      l10n: lookupAppLocalizations(const Locale('en')),
      language: SupportedLanguages.english,
      now: DateTime(2026, 10, 18, 7),
    );
    expect(content.days.single.temperature, 54);
    expect(content.days.single.feelsLike, 'Feels like 49°');
  });
}
