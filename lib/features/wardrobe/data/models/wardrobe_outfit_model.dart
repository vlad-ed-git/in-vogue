import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// An outfit as the account keeps it in `users/{uid}/wardrobe/{id}`.
abstract final class WardrobeOutfitModel {
  /// The record of an outfit with [details], photographed at [photoPath]
  /// in Storage, downloadable at [photoUrl].
  static Map<String, Object?> toJson({
    required OutfitDetails details,
    required String photoPath,
    required String photoUrl,
    required DateTime createdAt,
  }) => {
    'name': details.name.trim(),
    'colours': [
      for (final colour in OutfitColour.values)
        if (details.colours.contains(colour)) colour.name,
    ],
    'bands': [
      for (final band in WarmthBand.values)
        if (details.bands.contains(band)) band.name,
    ],
    'rain': details.rain,
    'occasions': [
      for (final occasion in Occasion.values)
        if (details.occasions.contains(occasion)) occasion.name,
    ],
    'photo': {'path': photoPath, 'url': photoUrl},
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// Null when [json] is not an outfit; [photo] is its copy on the phone.
  static WardrobeOutfit? fromJson(
    String id,
    Map<String, Object?> json, {
    String? photo,
  }) {
    final colours = _coloursOf(json);
    if (json case {
      'name': final String name,
      'bands': final List<Object?> bands,
      'occasions': final List<Object?> occasions,
      'photo': {'url': final String url},
      'createdAt': final Timestamp createdAt,
    } when colours != null) {
      return WardrobeOutfit(
        id: id,
        details: OutfitDetails(
          name: name,
          colours: colours,
          bands: {
            for (final band in bands) ?WarmthBand.values.asNameMap()[band],
          },
          rain: json['rain'] == true,
          occasions: {
            for (final occasion in occasions)
              ?Occasion.values.asNameMap()[occasion],
          },
        ),
        photoUrl: url,
        photoPath: photo,
        createdAt: createdAt.toDate(),
      );
    }
    return null;
  }

  /// An outfit's colours; one saved before several could be chosen
  /// (October 18) has a single `colour`. A colour the app doesn't know
  /// reads as mixed.
  static Set<OutfitColour>? _coloursOf(Map<String, Object?> json) {
    OutfitColour named(Object? name) =>
        OutfitColour.values.asNameMap()[name] ?? OutfitColour.mixed;
    return switch (json) {
      {'colours': final List<Object?> names} => {
        for (final name in names) named(name),
      },
      {'colour': final String name} => {named(name)},
      _ => null,
    };
  }

  /// Where an outfit's photo is kept in Storage.
  static String? photoPathOf(Map<String, Object?> json) => switch (json) {
    {'photo': {'path': final String path}} => path,
    _ => null,
  };
}
