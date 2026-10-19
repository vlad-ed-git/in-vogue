import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// What falls during a day's hours, as the knowledge base indexes it.
enum Precipitation { dry, wet, snow }

/// A day's weather class in the knowledge base (weather.v1.json): the band
/// of its coldest feels-like, what falls and whether it is windy.
class WeatherClass extends Equatable {
  const WeatherClass({
    required this.band,
    required this.precipitation,
    required this.windy,
    this.drizzle = false,
    WarmthBand? warmest,
  }) : warmest = warmest ?? band;

  final WarmthBand band;
  final Precipitation precipitation;

  /// Gusts of Beaufort 6 or more.
  final bool windy;

  /// Drizzle falls on an otherwise [Precipitation.dry] day.
  final bool drizzle;

  /// The band of the warmest feels-like.
  final WarmthBand warmest;

  /// The knowledge base's cell for this class and [occasion], such as
  /// "cool|wet|windy|work". Its cold band also holds freezing days.
  String cell(Occasion occasion) =>
      '${band == WarmthBand.freezing ? WarmthBand.cold.name : band.name}|'
      '${precipitation.name}|${windy ? 'windy' : 'calm'}|'
      '${contexts[occasion]}';

  /// The class a [cell] names, without its drizzle or warmest band; null
  /// when it names none.
  static WeatherClass? fromCell(String cell) {
    if (cell.split('|') case [final band, final falls, final wind, ...]) {
      final named = (
        WarmthBand.values.asNameMap()[band],
        Precipitation.values.asNameMap()[falls],
      );
      if (named case (
        final band?,
        final precipitation?,
      ) when wind == 'windy' || wind == 'calm') {
        return WeatherClass(
          band: band,
          precipitation: precipitation,
          windy: wind == 'windy',
        );
      }
    }
    return null;
  }

  /// The knowledge base's name of each occasion's context.
  static const contexts = {
    Occasion.work: 'work',
    Occasion.casual: 'casual',
    Occasion.goingOut: 'going_out',
    Occasion.stayingIn: 'staying_in',
  };

  @override
  List<Object?> get props => [band, precipitation, windy, drizzle, warmest];
}
