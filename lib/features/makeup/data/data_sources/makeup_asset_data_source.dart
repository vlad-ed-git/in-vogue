import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_recipes_model.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';

abstract interface class MakeupAssetDataSource {
  /// The recipes by key. Throws [FormatException] when the asset cannot be
  /// read.
  Future<Map<String, MakeupRecipe>> recipes();
}

/// The knowledge base's makeup recipes bundled with the app, made by
/// scripts/export_makeup.py.
class MakeupAssetDataSourceImpl implements MakeupAssetDataSource {
  MakeupAssetDataSourceImpl(this._bundle);
  final AssetBundle _bundle;

  static const path = 'assets/makeup/recipes.json';

  @override
  Future<Map<String, MakeupRecipe>> recipes() async {
    final text = await _bundle.loadString(path, cache: false);
    return Isolate.run(() => MakeupRecipesModel.fromJson(jsonDecode(text)));
  }
}
