/// The feels-like bands, warmest first.
enum WarmthBand {
  /// 26 °C and above.
  hot,

  /// 20 to 26 °C.
  warm,

  /// 14 to 20 °C.
  mild,

  /// 8 to 14 °C.
  cool,

  /// 0 to 8 °C.
  cold,

  /// Below 0 °C.
  freezing;

  /// Lowest feels-like of the band, °C; null for the coldest.
  double? get from => switch (this) {
    hot => 26,
    warm => 20,
    mild => 14,
    cool => 8,
    cold => 0,
    freezing => null,
  };

  /// Feels-like the band ends below, °C; null for the warmest.
  double? get below => switch (this) {
    hot => null,
    warm => 26,
    mild => 20,
    cool => 14,
    cold => 8,
    freezing => 0,
  };

  /// The band of a feels-like temperature in °C.
  static WarmthBand forFeelsLike(double celsius) => switch (celsius) {
    >= 26 => hot,
    >= 20 => warm,
    >= 14 => mild,
    >= 8 => cool,
    >= 0 => cold,
    _ => freezing,
  };
}
