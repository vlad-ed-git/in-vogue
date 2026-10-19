import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';

/// An outfit made for a day and an occasion, with its picture on the phone.
class DayOutfit extends Equatable {
  const DayOutfit({
    required this.outfitId,
    required this.date,
    required this.occasion,
    required this.picture,
    this.outfit,
    this.reason,
  });

  /// The catalog outfit's id.
  final String outfitId;

  /// The catalog's outfit; null when the catalog on the phone lacks it.
  final CatalogOutfit? outfit;

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The picture of the person in the outfit.
  final String picture;

  /// Why it was chosen for the day.
  final OutfitReason? reason;

  @override
  List<Object?> get props => [
    outfitId,
    outfit,
    date,
    occasion,
    picture,
    reason,
  ];
}
