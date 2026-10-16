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
  });

  final WarmthBand band;
  final Precipitation precipitation;

  /// Gusts of Beaufort 6 or more.
  final bool windy;

  /// The knowledge base's cell for this class and [occasion], such as
  /// "cool|wet|windy|work".
  String cell(Occasion occasion) =>
      '${band.name}|${precipitation.name}|${windy ? 'windy' : 'calm'}|'
      '${_contexts[occasion]}';

  static const _contexts = {
    Occasion.work: 'work',
    Occasion.casual: 'casual',
    Occasion.goingOut: 'going_out',
    Occasion.stayingIn: 'staying_in',
  };

  @override
  List<Object?> get props => [band, precipitation, windy];
}
