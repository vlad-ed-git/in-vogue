import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:in_vogue/features/catalog/data/models/piece_model.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';

abstract interface class CatalogAssetDataSource {
  /// Throws [FormatException] when the catalog cannot be read.
  Future<List<Piece>> pieces();
}

/// The partner's collection bundled with the app, made from the catalog pull
/// by scripts/export_catalog.py.
class CatalogAssetDataSourceImpl implements CatalogAssetDataSource {
  CatalogAssetDataSourceImpl(this._bundle);
  final AssetBundle _bundle;

  static const path = 'assets/catalog/everlane_women.json';

  @override
  Future<List<Piece>> pieces() async {
    final json = jsonDecode(await _bundle.loadString(path));
    if (json case {'pieces': final List<Object?> pieces}) {
      return [for (final piece in pieces) PieceModel.fromJson(piece)];
    }
    throw const FormatException('Not a catalog');
  }
}
