import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';

/// The day, date and place, then the weather line and the occasion, in the
/// place's temperature unit.
class DayWeatherHeader extends StatelessWidget {
  const DayWeatherHeader({
    required this.report,
    required this.place,
    super.key,
  });

  final WeatherReport report;
  final UserLocation? place;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final language = Localizations.localeOf(context).languageCode;
    final weather = report.weather;
    final unit = TemperatureUnit.forCountry(place?.countryCode);
    final day = report.day == ForecastDay.today ? l10n.today : l10n.tomorrow;
    final date = InVogueFormat.shortDate(weather.date, language);
    final city = place?.city;
    final savedAt = report.fetchedAt.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: InVogueSpace.s1),
        Text(
          city == null
              ? l10n.dayDate(day, date)
              : l10n.dayDatePlace(day, date, city),
          style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
        ),
        if (report.isSaved) ...[
          const SizedBox(height: InVogueSpace.s3),
          Notice(
            icon: InVogueIcons.offline,
            message: l10n.weatherSaved(
              l10n.savedAt(
                InVogueFormat.shortDate(savedAt, language),
                InVogueFormat.time(savedAt, language),
              ),
            ),
          ),
        ],
        WeatherLine(
          temperature: unit.degrees(weather.temperature),
          feelsLike: unit.degrees(weather.feelsLike),
          condition: weather.condition(l10n, language),
          glyph: weather.sky.glyph,
          highlight: weather.highlight,
          dayLabel: day,
        ),
        OccasionLine(occasion: weather.occasion),
      ],
    );
  }
}
