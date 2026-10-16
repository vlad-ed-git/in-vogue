/// The knowledge base's feels-like bands, warmest first.
enum WarmthBand {
  /// 26 °C and above.
  hot,

  /// 20 to 26 °C.
  warm,

  /// 14 to 20 °C.
  mild,

  /// 8 to 14 °C.
  cool,

  /// Below 8 °C.
  cold;

  /// Lowest feels-like of the band, °C; null for the coldest.
  double? get from => switch (this) {
    hot => 26,
    warm => 20,
    mild => 14,
    cool => 8,
    cold => null,
  };

  /// Feels-like the band ends below, °C; null for the warmest.
  double? get below => switch (this) {
    hot => null,
    warm => 26,
    mild => 20,
    cool => 14,
    cold => 8,
  };

  /// The band of a feels-like temperature in °C.
  static WarmthBand forFeelsLike(double celsius) => switch (celsius) {
    >= 26 => hot,
    >= 20 => warm,
    >= 14 => mild,
    >= 8 => cool,
    _ => cold,
  };
}
