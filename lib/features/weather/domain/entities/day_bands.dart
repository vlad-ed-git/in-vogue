import 'package:equatable/equatable.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// What an occasion's hours hold, for choosing an outfit: the feels-like
/// bands of its coldest and warmest hours, and whether rain, snow or strong
/// wind comes.
class DayBands extends Equatable {
  const DayBands({
    required this.start,
    required this.cold,
    required this.warm,
    required this.coldest,
    required this.coldestAt,
    required this.warmest,
    required this.warmestAt,
    required this.position,
    this.rainFrom,
    this.snowFrom,
    this.windFrom,
    this.indoors = false,
  });

  /// The occasion's first hour.
  final DateTime start;

  /// The band of the coldest hour.
  final WarmthBand cold;

  /// The band of the warmest hour; [cold] for one-band days.
  final WarmthBand warm;

  /// Feels-like, °C, and when.
  final double coldest;
  final DateTime coldestAt;
  final double warmest;
  final DateTime warmestAt;

  /// Where [coldest] sits in its band: 0 at the band's cold end, 1 at its
  /// warm end.
  final double position;

  /// The first hour of rain, snow or strong wind; null when none comes.
  final DateTime? rainFrom;
  final DateTime? snowFrom;
  final DateTime? windFrom;

  /// A day spent at home, held between Cool and Warm.
  final bool indoors;

  bool get rain => rainFrom != null;
  bool get snow => snowFrom != null;
  bool get windy => windFrom != null;

  /// Every band from the warmest hour's to the coldest hour's.
  List<WarmthBand> get span => [
    for (final band in WarmthBand.values)
      if (band.index >= warm.index && band.index <= cold.index) band,
  ];

  @override
  List<Object?> get props => [
    start,
    cold,
    warm,
    coldest,
    coldestAt,
    warmest,
    warmestAt,
    position,
    rainFrom,
    snowFrom,
    windFrom,
    indoors,
  ];
}
