import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// A day in one [band] from 07:00 on [date], with rain or strong wind from
/// its start when asked.
DayBands bandsFor(
  WarmthBand band, {
  DateTime? date,
  bool rain = false,
  bool windy = false,
}) {
  final start = (date ?? DateTime.utc(2026, 10, 16)).add(
    const Duration(hours: 7),
  );
  final feelsLike = (band.from ?? -6) + 2;
  return DayBands(
    start: start,
    cold: band,
    warm: band,
    coldest: feelsLike,
    coldestAt: start,
    warmest: feelsLike,
    warmestAt: start,
    position: 0.3,
    rainFrom: rain ? start : null,
    windFrom: windy ? start : null,
  );
}
