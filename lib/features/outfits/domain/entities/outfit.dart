import 'package:equatable/equatable.dart';

/// What a try-on pass dresses.
enum GarmentCategory { lowerBody, upperBody, fullBody, outer }

/// The colours of an outfit's pieces, as the knowledge base groups them.
enum OutfitPalette {
  /// Mostly beige, brown and cream.
  warmNeutral,

  /// Mostly black, white, grey and navy.
  coolNeutral,

  /// Neutrals with neither warm nor cool ones in the majority.
  mixedNeutral,

  /// At least one piece in a colour.
  colourful,
}

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

/// An outfit from the knowledge base, tried on one piece at a time.
class Outfit extends Equatable {
  const Outfit({
    required this.id,
    required this.signature,
    required this.pieces,
    required this.passes,
    this.reasons = const {},
    this.palette,
  });

  final String id;

  /// The same for every outfit of the same pieces.
  final String signature;

  /// Colourway ids of the pieces.
  final List<String> pieces;

  /// Try-on passes, in order.
  final List<TryOnPass> passes;

  /// A one-line reason for each knowledge-base cell the outfit suits.
  final Map<String, String> reasons;

  /// Null when the knowledge base does not say.
  final OutfitPalette? palette;

  /// Colourway ids of the pieces from the outer layer in: the try-on's
  /// passes in reverse.
  List<String> get outsideIn => passes.isEmpty
      ? pieces.reversed.toList()
      : [for (final pass in passes.reversed) pass.piece];

  @override
  List<Object?> get props => [id, signature, pieces, passes, reasons, palette];
}
