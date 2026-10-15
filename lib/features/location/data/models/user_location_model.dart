import 'package:in_vogue/features/location/domain/entities/user_location.dart';

/// The JSON form of a [UserLocation].
abstract final class UserLocationModel {
  static Map<String, Object?> toJson(UserLocation location) => {
    'latitude': location.latitude,
    'longitude': location.longitude,
    'city': location.city,
    'countryCode': location.countryCode,
  };

  /// Throws [FormatException] when [json] is not a location.
  static UserLocation fromJson(Object? json) => switch (json) {
    {
      'latitude': final num latitude,
      'longitude': final num longitude,
      'city': final String? city,
      'countryCode': final String? countryCode,
    } =>
      UserLocation(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        city: city,
        countryCode: countryCode,
      ),
    _ => throw const FormatException('Not a saved location'),
  };
}
