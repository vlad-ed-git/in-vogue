import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// An outfit made for a day and an occasion, with its picture on the phone.
class DayOutfit extends Equatable {
  const DayOutfit({
    required this.outfit,
    required this.date,
    required this.occasion,
    required this.cell,
    required this.picture,
  });

  final Outfit outfit;

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The knowledge-base cell it was chosen for.
  final String cell;

  /// The picture of the person in the outfit.
  final String picture;

  /// The one-line reason for the cell it was chosen for.
  String? get reason => outfit.reasons[cell];

  @override
  List<Object?> get props => [outfit, date, occasion, cell, picture];
}
