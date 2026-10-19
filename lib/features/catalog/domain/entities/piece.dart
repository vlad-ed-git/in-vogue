import 'package:equatable/equatable.dart';

/// One colour of a piece, with its own photo and product page.
class Colourway extends Equatable {
  const Colourway({
    required this.id,
    required this.name,
    required this.hex,
    required this.photoUrl,
    required this.productUrl,
    this.flatUrl,
    this.material,
  });

  final String id;
  final String name;

  /// 0xAARRGGBB.
  final int hex;

  /// The piece worn by a model.
  final String photoUrl;

  /// The piece laid flat.
  final String? flatUrl;
  final String productUrl;

  /// What it is made of; null when the partner does not say.
  final String? material;

  @override
  List<Object?> get props => [
    id,
    name,
    hex,
    photoUrl,
    flatUrl,
    productUrl,
    material,
  ];
}

/// A piece of clothing from the partner's collection, in all its colours.
class Piece extends Equatable {
  const Piece({required this.id, required this.name, required this.colourways});

  final String id;
  final String name;
  final List<Colourway> colourways;

  @override
  List<Object?> get props => [id, name, colourways];
}
