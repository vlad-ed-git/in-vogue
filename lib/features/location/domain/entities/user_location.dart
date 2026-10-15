import 'package:equatable/equatable.dart';

/// Where the person is, to about a kilometre.
class UserLocation extends Equatable {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.countryCode,
  });

  final double latitude;
  final double longitude;

  /// Town or city name; null when unknown.
  final String? city;

  /// ISO 3166-1 alpha-2 code, such as "US"; null when unknown.
  final String? countryCode;

  @override
  List<Object?> get props => [latitude, longitude, city, countryCode];
}
