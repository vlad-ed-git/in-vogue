import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// A step of a makeup look, with the face after it once it is made.
class LookStep extends Equatable {
  const LookStep({
    required this.title,
    required this.howTo,
    required this.products,
    this.picture,
  });

  final LocalizedText title;
  final LocalizedText howTo;

  /// Kinds of product; never brands.
  final List<LocalizedText> products;

  /// The face after this step; null until it is made.
  final String? picture;

  LookStep withPicture(String picture) => LookStep(
    title: title,
    howTo: howTo,
    products: products,
    picture: picture,
  );

  @override
  List<Object?> get props => [title, howTo, products, picture];
}

/// A makeup look made on the person's face for one outfit.
class MakeupLook extends Equatable {
  const MakeupLook({
    required this.outfitSignature,
    required this.date,
    required this.occasion,
    required this.palette,
    required this.cheeks,
    required this.lips,
    required this.before,
    required this.steps,
    required this.matched,
  });

  /// The outfit's signature; each outfit has at most one look.
  final String outfitSignature;

  /// Midnight UTC of the outfit's local date.
  final DateTime date;
  final Occasion occasion;

  /// The outfit's palette the look was chosen for.
  final OutfitPalette palette;
  final CheekColour cheeks;
  final LipColour lips;

  /// The face photo the look was made on.
  final String before;

  /// Every step with its picture, in order.
  final List<LookStep> steps;

  /// Whether the shades were matched to the person's own colours.
  final bool matched;

  /// The face with the finished look.
  String get after => steps.last.picture ?? before;

  @override
  List<Object?> get props => [
    outfitSignature,
    date,
    occasion,
    palette,
    cheeks,
    lips,
    before,
    steps,
    matched,
  ];
}
