import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/location/data/models/user_location_model.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';

abstract interface class LocationLocalDataSource {
  /// Null when nothing readable is saved.
  UserLocation? getLocation();
  Future<void> saveLocation(UserLocation location);
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  LocationLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const locationKey = 'location';

  @override
  UserLocation? getLocation() {
    final saved = _store.readString(locationKey);
    if (saved == null) return null;
    try {
      return UserLocationModel.fromJson(jsonDecode(saved));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveLocation(UserLocation location) => _store.writeString(
    locationKey,
    jsonEncode(UserLocationModel.toJson(location)),
  );
}
