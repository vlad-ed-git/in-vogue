import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// The knowledge base's ranked outfit ids per cell, and the outfits.
typedef OutfitIndex = ({
  Map<String, List<String>> cells,
  Map<String, Outfit> outfits,
});

/// Reads the outfits asset made by scripts/export_outfits.py.
abstract final class OutfitsModel {
  static const _categories = {
    'lower_body': GarmentCategory.lowerBody,
    'upper_body': GarmentCategory.upperBody,
    'full_body': GarmentCategory.fullBody,
    'outer': GarmentCategory.outer,
  };

  static const _palettes = {
    'warm_neutral': OutfitPalette.warmNeutral,
    'cool_neutral': OutfitPalette.coolNeutral,
    'mixed_neutral': OutfitPalette.mixedNeutral,
    'colourful': OutfitPalette.colourful,
  };

  /// The service's name of [category].
  static String categoryName(GarmentCategory category) =>
      _categories.entries.firstWhere((entry) => entry.value == category).key;

  /// Throws [FormatException] when [json] is not the outfits asset.
  static OutfitIndex fromJson(Object? json) {
    if (json case {
      'cells': final Map<String, Object?> cells,
      'outfits': final Map<String, Object?> outfits,
    }) {
      return (
        cells: {
          for (final MapEntry(key: cell, value: ids) in cells.entries)
            cell: switch (ids) {
              final List<Object?> ids => ids.whereType<String>().toList(),
              _ => throw const FormatException('Cell without ids'),
            },
        },
        outfits: {
          for (final MapEntry(key: id, value: outfit) in outfits.entries)
            id: _outfit(id, outfit),
        },
      );
    }
    throw const FormatException('Not the outfits asset');
  }

  static Outfit _outfit(String id, Object? json) => switch (json) {
    {
          'signature': final String signature,
          'pieces': final List<Object?> pieces,
          'passes': final List<Object?> passes,
          'reasons': final Map<String, Object?> reasons,
        } &&
        final Map<String, Object?> fields =>
      Outfit(
        id: id,
        signature: signature,
        pieces: pieces.cast<String>(),
        passes: [for (final pass in passes) _pass(pass)],
        reasons: {
          for (final MapEntry(key: cell, value: reason) in reasons.entries)
            cell: ?LocalizedText.fromJson(reason),
        },
        palette: _palettes[fields['palette']],
      ),
    _ => throw FormatException('Not an outfit', id),
  };

  static TryOnPass _pass(Object? json) => switch (json) {
    {
      'category': final String category,
      'piece': final String piece,
      'reference': final String reference,
    } =>
      TryOnPass(
        category:
            _categories[category] ??
            (throw FormatException('Unknown category', category)),
        piece: piece,
        reference: reference,
      ),
    _ => throw const FormatException('Not a try-on pass'),
  };
}
