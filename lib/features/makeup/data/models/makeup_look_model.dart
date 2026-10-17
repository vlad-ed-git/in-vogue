import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_recipes_model.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/services/makeup_rules.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:path/path.dart' as p;

/// A look as its record in `users/{uid}/makeupLooks/{outfit signature}`
/// holds it: pictures by file name, kept in Storage under
/// `users/{uid}/makeup/{outfit signature}/`.
abstract final class MakeupLookModel {
  /// Where the picture [name] of the look for [signature] is in Storage.
  static String storagePath(String accountId, String signature, String name) =>
      'users/$accountId/makeup/$signature/$name';

  /// "jpg" or "png", from the picture's first bytes; "jpg" when unknown.
  static String extensionOf(List<int> picture) =>
      picture.length >= 4 &&
          picture[0] == 0x89 &&
          picture[1] == 0x50 &&
          picture[2] == 0x4E &&
          picture[3] == 0x47
      ? 'png'
      : 'jpg';

  static String contentType(String name) =>
      p.extension(name) == '.png' ? 'image/png' : 'image/jpeg';

  /// The record's fields, without its creation time; pictures by file name.
  static Map<String, Object?> toJson(MakeupLook look) => {
    'forDate': TryOnJob.dateKey(look.date),
    'occasion': look.occasion.name,
    'palette': MakeupRules.palettes[look.palette],
    'cheeks': _nameOf(MakeupRecipesModel.cheeks, look.cheeks),
    'lips': _nameOf(MakeupRecipesModel.lips, look.lips),
    'matched': look.matched,
    'before': p.basename(look.before),
    'steps': [
      for (final step in look.steps)
        {
          'title': step.title.toJson(),
          'howTo': step.howTo.toJson(),
          'products': [for (final product in step.products) product.toJson()],
          'picture': p.basename(step.picture!),
        },
    ],
  };

  /// The look in [json], its pictures by file name; null when it is not a
  /// readable look.
  static MakeupLook? fromJson(String signature, Map<String, Object?> json) {
    if (json case {
      'forDate': final String forDate,
      'occasion': final String occasion,
      'palette': final String palette,
      'cheeks': final String cheeks,
      'lips': final String lips,
      'matched': final bool matched,
      'before': final String before,
      'steps': final List<Object?> steps,
    }) {
      final date = DateTime.tryParse('${forDate}T00:00:00Z');
      final kind = Occasion.values.asNameMap()[occasion];
      final outfitPalette = _keyOf(MakeupRules.palettes, palette);
      final cheekColour = MakeupRecipesModel.cheeks[cheeks];
      final lipColour = MakeupRecipesModel.lips[lips];
      final lookSteps = [
        for (final step in steps)
          if (step case {
            'title': final Object title,
            'howTo': final Object howTo,
            'products': final List<Object?> products,
            'picture': final String picture,
          })
            if ((LocalizedText.fromJson(title), LocalizedText.fromJson(howTo))
                case (final LocalizedText title, final LocalizedText howTo))
              LookStep(
                title: title,
                howTo: howTo,
                products: [
                  for (final product in products)
                    ?LocalizedText.fromJson(product),
                ],
                picture: picture,
              ),
      ];
      if (date == null ||
          kind == null ||
          outfitPalette == null ||
          cheekColour == null ||
          lipColour == null ||
          lookSteps.isEmpty ||
          lookSteps.length != steps.length) {
        return null;
      }
      return MakeupLook(
        outfitSignature: signature,
        date: date,
        occasion: kind,
        palette: outfitPalette,
        cheeks: cheekColour,
        lips: lipColour,
        before: before,
        steps: lookSteps,
        matched: matched,
      );
    }
    return null;
  }

  static String _nameOf<T>(Map<String, T> names, T value) =>
      names.entries.firstWhere((entry) => entry.value == value).key;

  static K? _keyOf<K>(Map<K, String> names, String name) {
    for (final MapEntry(:key, :value) in names.entries) {
      if (value == name) return key;
    }
    return null;
  }
}
