import 'package:in_vogue/features/catalog/domain/entities/piece.dart';

/// Reads a piece of the catalog asset.
abstract final class PieceModel {
  /// Throws [FormatException] when [json] is not a piece.
  static Piece fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'colourways': final List<Object?> colourways,
    } =>
      Piece(
        id: id,
        name: name,
        colourways: [for (final colourway in colourways) _colourway(colourway)],
      ),
    _ => throw const FormatException('Not a piece'),
  };

  static Colourway _colourway(Object? json) => switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'hex': final String hex,
      'photo': final String photo,
      'flat': final String? flat,
      'url': final String url,
    } =>
      Colourway(
        id: id,
        name: name,
        hex: 0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16),
        photoUrl: photo,
        flatUrl: flat,
        productUrl: url,
        material: switch (json['material']) {
          final String material when material.trim().isNotEmpty => material,
          _ => null,
        },
      ),
    _ => throw const FormatException('Not a colourway'),
  };
}
