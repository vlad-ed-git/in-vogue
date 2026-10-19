import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_pass.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// Reads an outfit document of the catalog, `outfits/{id}`.
abstract final class CatalogOutfitModel {
  /// The catalog's names of the app's occasions. Its Event and Active
  /// labels are not the app's, so they are left out.
  static const occasions = {
    'work': Occasion.work,
    'casual': Occasion.casual,
    'out': Occasion.goingOut,
    'in': Occasion.stayingIn,
  };

  static const _categories = {
    'lower_body': GarmentCategory.lowerBody,
    'upper_body': GarmentCategory.upperBody,
    'full_body': GarmentCategory.fullBody,
    'outer': GarmentCategory.outer,
  };

  static const _warmth = {
    'light': PieceWarmth.light,
    'medium': PieceWarmth.medium,
    'warm': PieceWarmth.warm,
    'verywarm': PieceWarmth.veryWarm,
  };

  /// Throws [FormatException] when [json] is not an outfit.
  static CatalogOutfit fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'order': final int order,
      'name': final String name,
      'sample': final bool sample,
      'image': {'url': final String imageUrl},
      'weathers': final List<Object?> weathers,
      'baseWeathers': final List<Object?> baseWeathers,
      'seasons': final List<Object?> seasons,
      'occasions': final List<Object?> occasions,
      'families': final List<Object?> families,
      'styles': final List<Object?> styles,
      'kinds': final List<Object?> kinds,
      'dressy': final num dressy,
      'warmth': final int warmth,
      'rain': final String rain,
      'wind': final String wind,
      'coat': final bool coat,
      'pieces': final List<Object?> pieces,
      'passes': final List<Object?> passes,
    } =>
      CatalogOutfit(
        id: id,
        order: order,
        name: name,
        sample: sample,
        imageUrl: imageUrl,
        weathers: _named(WarmthBand.values, weathers),
        baseWeathers: _named(WarmthBand.values, baseWeathers),
        seasons: _named(ColourSeason.values, seasons),
        occasions: {
          for (final name in occasions) ?CatalogOutfitModel.occasions[name],
        },
        families: _strings(families),
        styles: _strings(styles),
        kinds: _strings(kinds),
        dressy: dressy.toDouble(),
        warmth: warmth,
        rain: _name(RainFit.values, rain),
        wind: _name(WindFit.values, wind),
        coat: coat,
        pieces: [for (final piece in pieces) _piece(piece)],
        passes: [for (final pass in passes) _pass(pass)],
      ),
    _ => throw const FormatException('Not a catalog outfit'),
  };

  static OutfitPiece _piece(Object? json) => switch (json) {
    {
      'colourway': final String colourway,
      'style': final String style,
      'name': final String name,
      'colour': final String colour,
      'hex': final String hex,
      'family': final String family,
      'pattern': final String pattern,
      'neutral': final bool neutral,
      'role': final String role,
      'kind': final String kind,
      'weathers': final List<Object?> weathers,
      'warmth': final String warmth,
      'dressy': final num dressy,
      'styles': final List<Object?> styles,
      'rain': final String rain,
      'wind': final String wind,
      'url': final String url,
      'photo': final String photo,
    } =>
      OutfitPiece(
        colourway: colourway,
        style: style,
        name: name,
        colour: colour,
        hex: 0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16),
        family: family,
        accent: switch (json['accent']) {
          final String accent => accent,
          _ => null,
        },
        pattern: _name(ColourPattern.values, pattern),
        neutral: neutral,
        role: _name(PieceRole.values, role),
        kind: kind,
        weathers: _named(WarmthBand.values, weathers),
        warmth: _warmth[warmth] ?? (throw FormatException('Warmth', warmth)),
        dressy: dressy.toDouble(),
        styles: _strings(styles),
        rain: _name(RainFit.values, rain),
        wind: _name(WindFit.values, wind),
        productUrl: url,
        photoUrl: photo,
      ),
    _ => throw const FormatException('Not an outfit piece'),
  };

  static TryOnPass _pass(Object? json) => switch (json) {
    {
      'category': final String category,
      'piece': final String piece,
      'reference': final String reference,
    } =>
      TryOnPass(
        category:
            _categories[category] ?? (throw FormatException('Pass', category)),
        piece: piece,
        reference: reference,
      ),
    _ => throw const FormatException('Not a try-on pass'),
  };

  static T _name<T extends Enum>(List<T> values, Object? name) =>
      values.asNameMap()[name] ?? (throw FormatException('Unknown name', name));

  static Set<T> _named<T extends Enum>(List<T> values, List<Object?> names) => {
    for (final name in names) _name(values, name),
  };

  static Set<String> _strings(List<Object?> values) =>
      values.whereType<String>().toSet();
}
