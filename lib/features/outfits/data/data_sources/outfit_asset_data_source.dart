import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:in_vogue/features/outfits/data/models/outfits_model.dart';

abstract interface class OutfitAssetDataSource {
  /// Throws [FormatException] when the asset cannot be read.
  Future<OutfitIndex> index();
}

/// The knowledge base's outfits bundled with the app, made by
/// scripts/export_outfits.py.
class OutfitAssetDataSourceImpl implements OutfitAssetDataSource {
  OutfitAssetDataSourceImpl(this._bundle);
  final AssetBundle _bundle;

  static const path = 'assets/outfits/outfits.json';

  @override
  Future<OutfitIndex> index() async {
    final text = await _bundle.loadString(path, cache: false);
    // About 4 MB: read on another isolate so the screen keeps moving.
    return Isolate.run(() => OutfitsModel.fromJson(jsonDecode(text)));
  }
}
