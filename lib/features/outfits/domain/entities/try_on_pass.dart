import 'package:equatable/equatable.dart';

/// What a try-on pass dresses.
enum GarmentCategory { lowerBody, upperBody, fullBody, outer }

/// One try-on pass: a piece put on the person, with the piece's worn photo
/// as the reference.
class TryOnPass extends Equatable {
  const TryOnPass({
    required this.category,
    required this.piece,
    required this.reference,
  });

  final GarmentCategory category;

  /// The piece's colourway id.
  final String piece;

  /// URL of the photo of the piece worn.
  final String reference;

  @override
  List<Object?> get props => [category, piece, reference];
}
