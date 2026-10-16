import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';

/// Reads the makeup asset made by scripts/export_makeup.py.
abstract final class MakeupRecipesModel {
  static const cheeks = {
    'soft_pink': CheekColour.softPink,
    'peach': CheekColour.peach,
    'rose': CheekColour.rose,
    'terracotta': CheekColour.terracotta,
  };

  static const lips = {
    'nude': LipColour.nude,
    'rosy_nude': LipColour.rosyNude,
    'rose': LipColour.rose,
    'terracotta': LipColour.terracotta,
    'red': LipColour.red,
    'berry': LipColour.berry,
    'brick': LipColour.brick,
  };

  /// The recipes by key. Throws [FormatException] when [json] is not the
  /// makeup asset.
  static Map<String, MakeupRecipe> fromJson(Object? json) {
    if (json case {
      'steps': final List<Object?> steps,
      'recipes': final Map<String, Object?> recipes,
    }) {
      final table = [for (final step in steps) _step(step)];
      return {
        for (final MapEntry(:key, :value) in recipes.entries)
          key: _recipe(key, value, table),
      };
    }
    throw const FormatException('Not the makeup asset');
  }

  static MakeupRecipe _recipe(
    String key,
    Object? json,
    List<RecipeStep> table,
  ) => switch (json) {
    {
      'cheeks': final String cheeks,
      'lips': final String lips,
      'steps': final List<Object?> steps,
    } =>
      MakeupRecipe(
        key: key,
        cheeks:
            MakeupRecipesModel.cheeks[cheeks] ??
            (throw FormatException('Unknown cheeks', cheeks)),
        lips:
            MakeupRecipesModel.lips[lips] ??
            (throw FormatException('Unknown lips', lips)),
        steps: [
          for (final index in steps)
            if (index is int && index >= 0 && index < table.length)
              table[index]
            else
              throw FormatException('Unknown step', index),
        ],
      ),
    _ => throw FormatException('Not a recipe', key),
  };

  static RecipeStep _step(Object? json) => switch (json) {
    {
      'title': final String title,
      'howTo': final String howTo,
      'products': final List<Object?> products,
      'effects': final List<Object?> effects,
    } =>
      RecipeStep(
        title: title,
        howTo: howTo,
        products: products.whereType<String>().toList(),
        effects: effects.whereType<Map<String, Object?>>().toList(),
      ),
    _ => throw const FormatException('Not a recipe step'),
  };
}
