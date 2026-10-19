import 'dart:convert';
import 'dart:io';

import 'package:in_vogue/core/persistence/cache_exception.dart';

/// The catalog as kept on the phone: its version, whether it holds every
/// outfit or only the onboarding sample, and the outfits' documents.
typedef CatalogCopy = ({
  int version,
  bool whole,
  List<Map<String, Object?>> outfits,
});

/// The catalog's copy on this phone, in one file.
abstract interface class OutfitCatalogLocalDataSource {
  /// Null when no readable copy is kept.
  Future<CatalogCopy?> read();

  /// Replaces the copy. Throws [CacheException].
  Future<void> save(CatalogCopy copy);
}

class OutfitCatalogLocalDataSourceImpl implements OutfitCatalogLocalDataSource {
  const OutfitCatalogLocalDataSourceImpl(this._path);

  final String _path;

  @override
  Future<CatalogCopy?> read() async {
    try {
      final file = File(_path);
      if (!file.existsSync()) return null;
      return switch (jsonDecode(await file.readAsString())) {
        {
          'version': final int version,
          'whole': final bool whole,
          'outfits': final List<Object?> outfits,
        } =>
          (
            version: version,
            whole: whole,
            outfits: outfits.whereType<Map<String, Object?>>().toList(),
          ),
        _ => null,
      };
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> save(CatalogCopy copy) async {
    try {
      final file = File(_path);
      await file.parent.create(recursive: true);
      // Written beside it first, so a copy is never left half written.
      final next = File('$_path.next');
      await next.writeAsString(
        jsonEncode({
          'version': copy.version,
          'whole': copy.whole,
          'outfits': copy.outfits,
        }),
        flush: true,
      );
      await next.rename(_path);
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
