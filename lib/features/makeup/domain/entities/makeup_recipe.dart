import 'package:equatable/equatable.dart';

/// A recipe's blush colour.
enum CheekColour { softPink, peach, rose, terracotta }

/// A recipe's lip colour; [nude] is the person's own, a little deeper.
enum LipColour { nude, rosyNude, rose, terracotta, red, berry, brick }

/// One step of a makeup recipe: what to do, with which products, and the
/// effects that put it on a face in one render.
class RecipeStep extends Equatable {
  const RecipeStep({
    required this.title,
    required this.howTo,
    required this.products,
    required this.effects,
  });

  final String title;
  final String howTo;

  /// Kinds of product, such as "cream blush"; never brands.
  final List<String> products;

  /// The render's effects. A colour may name a [SkinColour] placeholder,
  /// such as "{skin}", filled in for each face.
  final List<Map<String, Object?>> effects;

  @override
  List<Object?> get props => [title, howTo, products, effects];
}

/// The placeholders a recipe's effects name for the face's own colours.
enum SkinColour {
  skin('{skin}'),
  concealer('{concealer}'),
  brow('{brow}'),
  nudeLip('{nudeLip}');

  const SkinColour(this.placeholder);
  final String placeholder;
}

/// A makeup look from the knowledge base, before it is matched to a face.
class MakeupRecipe extends Equatable {
  const MakeupRecipe({
    required this.key,
    required this.cheeks,
    required this.lips,
    required this.steps,
  });

  /// occasion|outfit palette|shade group|contrast|weather.
  final String key;
  final CheekColour cheeks;
  final LipColour lips;

  /// In the order they are put on.
  final List<RecipeStep> steps;

  @override
  List<Object?> get props => [key, cheeks, lips, steps];
}
