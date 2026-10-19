import 'package:in_vogue/features/catalog/data/models/catalog_outfit_model.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_pass.dart';

/// An outfit document as the catalog stores it.
Map<String, Object?> document(
  String id, {
  int order = 0,
  bool sample = false,
  List<String> weathers = const ['mild'],
  String rain = 'fine',
  String name = 'Parchment merino crop top, cream seamed midi skirt',
}) => {
  'id': id,
  'version': 2,
  'order': order,
  'name': name,
  'sample': sample,
  'image': {
    'path': 'catalog/v2/outfits/$id-77dd9ef4.jpg',
    'source': 'https://cdn.shopify.com/$id.jpg',
    'url': 'https://firebasestorage.googleapis.com/$id.jpg',
  },
  'weathers': weathers,
  'baseWeathers': weathers,
  'seasons': ['lightSpring', 'softAutumn'],
  'occasions': ['work', 'casual', 'event', 'in'],
  'fits': ['lightSpring|mild', 'softAutumn|mild'],
  'families': ['cream'],
  'styles': ['minimal'],
  'kinds': ['sweater', 'skirt'],
  'dressy': 2.5,
  'warmth': 3,
  'rain': rain,
  'wind': 'fine',
  'coat': false,
  'pieces': [
    {
      'colourway': 'everlane:$id-top',
      'style': 'top-style',
      'name': 'The Cropped Crew Top in Ultrafine Merino',
      'colour': 'Parchment',
      'hex': '#d6cdc2',
      'family': 'cream',
      'accent': null,
      'pattern': 'plain',
      'neutral': true,
      'role': 'top',
      'kind': 'sweater',
      'weathers': ['mild', 'cool', 'cold', 'freezing'],
      'warmth': 'medium',
      'dressy': 3,
      'styles': ['minimal'],
      'fibre': 'merino',
      'shape': null,
      'length': 'cropped',
      'rain': 'fine',
      'wind': 'fine',
      'url': 'https://www.everlane.com/products/$id-top',
      'photo': 'https://cdn.shopify.com/$id-top.jpg',
    },
    {
      'colourway': 'everlane:$id-skirt',
      'style': 'skirt-style',
      'name': 'Seamed Midi Skirt',
      'colour': 'Bone',
      'hex': '#ddd2cc',
      'family': 'cream',
      'accent': 'navy',
      'pattern': 'striped',
      'neutral': true,
      'role': 'bottom',
      'kind': 'skirt',
      'weathers': ['hot', 'warm', 'mild'],
      'warmth': 'verywarm',
      'dressy': 2,
      'styles': ['minimal', 'classic'],
      'fibre': 'silk',
      'shape': 'aline',
      'length': 'midi',
      'rain': 'avoid',
      'wind': 'avoid',
      'url': 'https://www.everlane.com/products/$id-skirt',
      'photo': 'https://cdn.shopify.com/$id-skirt.jpg',
    },
  ],
  'passes': [
    {
      'category': 'lower_body',
      'piece': 'everlane:$id-skirt',
      'reference': 'https://cdn.shopify.com/$id-skirt.jpg',
    },
    {
      'category': 'upper_body',
      'piece': 'everlane:$id-top',
      'reference': 'https://cdn.shopify.com/$id-top.jpg',
    },
  ],
  'retailer': 'everlane',
};

CatalogOutfit outfit(
  String id, {
  int order = 0,
  bool sample = false,
  List<String> weathers = const ['mild'],
  String rain = 'fine',
  String name = 'Parchment merino crop top, cream seamed midi skirt',
}) => CatalogOutfitModel.fromJson(
  document(
    id,
    order: order,
    sample: sample,
    weathers: weathers,
    rain: rain,
    name: name,
  ),
);

/// A catalog outfit of [pieces], each a colourway, what the try-on dresses
/// with it and its kind, tried on in that order.
CatalogOutfit outfitOf(
  String id,
  List<(String colourway, GarmentCategory category, String kind)> pieces, {
  List<String> weathers = const ['cool'],
  List<String> occasions = const ['work', 'casual'],
  String rain = 'fine',
  List<ColourSeason> seasons = ColourSeason.values,
}) {
  final base = document(id, weathers: weathers, rain: rain);
  final template = (base['pieces']! as List<Object?>).first! as Map;
  String photo(String colourway) =>
      'https://cdn.example/${colourway.split(':').last}.jpg';
  return CatalogOutfitModel.fromJson({
    ...base,
    'occasions': occasions,
    'seasons': [for (final season in seasons) season.name],
    'pieces': [
      for (final (colourway, category, kind) in pieces)
        {
          ...template,
          'colourway': colourway,
          'kind': kind,
          'role': switch (category) {
            GarmentCategory.lowerBody => 'bottom',
            GarmentCategory.upperBody => 'top',
            GarmentCategory.fullBody => 'whole',
            GarmentCategory.outer => 'over',
          },
          'weathers': weathers,
          'photo': photo(colourway),
        },
    ],
    'passes': [
      for (final (colourway, category, _) in pieces)
        {
          'category': switch (category) {
            GarmentCategory.lowerBody => 'lower_body',
            GarmentCategory.upperBody => 'upper_body',
            GarmentCategory.fullBody => 'full_body',
            GarmentCategory.outer => 'outer',
          },
          'piece': colourway,
          'reference': photo(colourway),
        },
    ],
  });
}
