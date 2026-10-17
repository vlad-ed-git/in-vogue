import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_refresh_context.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// What the morning refresh needs, kept with the flavor that kept it.
abstract final class WidgetRefreshContextModel {
  static const version = 1;

  static Map<String, Object?> toJson(
    WidgetRefreshContext context, {
    required String environment,
  }) => {
    'version': version,
    'environment': environment,
    'latitude': context.place.latitude,
    'longitude': context.place.longitude,
    'city': context.place.city,
    'countryCode': context.place.countryCode,
    'language': context.language.languageCode,
    'preferred': context.preferred.name,
    'bodyPhoto': context.bodyPhoto,
    'occasions': {
      for (final MapEntry(key: date, value: occasion)
          in context.occasions.entries)
        TryOnJob.dateKey(date): occasion.name,
    },
  };

  /// The context in [json] and its flavor; null when it isn't readable.
  static ({String environment, WidgetRefreshContext context})? fromJson(
    Object? json,
  ) {
    if (json
        case {
              'environment': final String environment,
              'latitude': final num latitude,
              'longitude': final num longitude,
              'language': final String language,
              'preferred': final String preferred,
              'occasions': final Map<String, Object?> occasions,
            } &&
            final Map<String, Object?> fields) {
      final day = ForecastDay.values.asNameMap()[preferred];
      if (day == null) return null;
      return (
        environment: environment,
        context: WidgetRefreshContext(
          place: UserLocation(
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
            city: fields['city'] as String?,
            countryCode: fields['countryCode'] as String?,
          ),
          language: SupportedLanguages.fromLanguageCode(language),
          preferred: day,
          bodyPhoto: fields['bodyPhoto'] as String?,
          occasions: {
            for (final MapEntry(key: date, value: occasion)
                in occasions.entries)
              if ((
                    DateTime.tryParse('${date}T00:00:00Z'),
                    Occasion.values.asNameMap()[occasion],
                  )
                  case (final DateTime date, final Occasion occasion))
                date: occasion,
          },
        ),
      );
    }
    return null;
  }
}
