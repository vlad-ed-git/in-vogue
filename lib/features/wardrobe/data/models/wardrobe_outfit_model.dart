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
    'colour': details.colour.name,
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
    if (json case {
      'name': final String name,
      'colour': final String colour,
      'bands': final List<Object?> bands,
      'occasions': final List<Object?> occasions,
      'photo': {'url': final String url},
      'createdAt': final Timestamp createdAt,
    }) {
      return WardrobeOutfit(
        id: id,
        details: OutfitDetails(
          name: name,
          colour: OutfitColour.values.asNameMap()[colour] ?? OutfitColour.mixed,
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

  /// Where an outfit's photo is kept in Storage.
  static String? photoPathOf(Map<String, Object?> json) => switch (json) {
    {'photo': {'path': final String path}} => path,
    _ => null,
  };
}
