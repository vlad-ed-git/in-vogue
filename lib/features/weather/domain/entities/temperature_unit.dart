/// The unit temperatures are shown in.
enum TemperatureUnit {
  celsius,
  fahrenheit;

  /// Countries and territories that use Fahrenheit.
  static const _fahrenheit = {
    'US', 'PR', 'GU', 'VI', 'AS', 'MP', 'UM', // The United States
    'BS', 'BZ', 'KY', 'LR', 'PW', 'FM', 'MH',
  };

  /// Fahrenheit where the region uses it, Celsius elsewhere.
  static TemperatureUnit forCountry(String? countryCode) =>
      _fahrenheit.contains(countryCode?.toUpperCase()) ? fahrenheit : celsius;

  /// [celsius] in this unit, rounded to whole degrees.
  int degrees(double celsius) =>
      (this == fahrenheit ? celsius * 9 / 5 + 32 : celsius).round();
}
