import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';

/// The sky a day's glyph shows.
enum Sky { clear, partlyCloudy, cloudy, fog, rain, snow, storm, wind }

/// Weather that changes what to wear.
enum WeatherEventKind { rain, showers, drizzle, snow, storm, wind }

/// When a [WeatherEvent] happens in the day's hours.
enum WeatherTiming {
  allDay,

  /// Begins at [WeatherEvent.at].
  from,

  /// Ends at [WeatherEvent.at].
  until,
}

class WeatherEvent extends Equatable {
  const WeatherEvent(this.kind, this.timing, [this.at]);

  final WeatherEventKind kind;
  final WeatherTiming timing;

  /// Local wall-clock start or end; null all day.
  final DateTime? at;

  @override
  List<Object?> get props => [kind, timing, at];
}

/// What the weather line says about one day's hours for one occasion.
class DayWeather extends Equatable {
  const DayWeather({
    required this.date,
    required this.occasion,
    required this.temperature,
    required this.feelsLike,
    required this.sky,
    this.event,
  });

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// °C at the warmest hour.
  final double temperature;

  /// °C, how that hour feels.
  final double feelsLike;
  final Sky sky;

  /// The one thing to highlight; null on a dry, calm day.
  final WeatherEvent? event;

  @override
  List<Object?> get props => [
    date,
    occasion,
    temperature,
    feelsLike,
    sky,
    event,
  ];
}
