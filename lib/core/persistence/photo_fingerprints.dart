import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';

/// A photo's fingerprint: the SHA-256 of its bytes, the same for the same
/// photo on every phone. Each file is read once, as a kept photo never
/// changes: a new photo gets a new file.
class PhotoFingerprints {
  PhotoFingerprints({Future<List<int>> Function(String path)? read})
    : _read = read ?? ((path) => File(path).readAsBytes());

  final Future<List<int>> Function(String path) _read;
  final _known = <String, Future<String>>{};

  /// The fingerprint of the photo at [path]. Throws [CacheException] when
  /// it can't be read.
  Future<String> of(String path) => _known[path] ??= _fingerprint(path);

  Future<String> _fingerprint(String path) async {
    try {
      return sha256.convert(await _read(path)).toString();
    } on FileSystemException catch (error, stack) {
      // Read again next time.
      unawaited(_known.remove(path));
      throw CacheException(error, stack);
    }
  }
}
