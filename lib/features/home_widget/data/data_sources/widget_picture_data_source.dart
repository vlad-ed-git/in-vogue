import 'dart:convert';
import 'dart:io';

import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:path/path.dart' as p;

/// The day's pictures, where the native widget can read them.
///
/// Every method throws [CacheException].
abstract interface class WidgetPictureDataSource {
  /// Shares the pictures at [paths] with the widget and stops sharing any
  /// other. Maps each path to where the widget reads it, leaving out the
  /// pictures that are missing.
  Future<Map<String, String>> share(Set<String> paths);

  /// Stops sharing every picture.
  Future<void> clear();
}

/// Android draws its widget in the app's own process, so the widget reads
/// the pictures where the app keeps them.
class InPlaceWidgetPictureDataSource implements WidgetPictureDataSource {
  const InPlaceWidgetPictureDataSource();

  @override
  Future<Map<String, String>> share(Set<String> paths) async => {
    for (final path in paths) path: path,
  };

  @override
  Future<void> clear() async {}
}

/// The iPhone widget runs apart from the app and reads only the App Group's
/// container, so each picture is copied into its [folder], under a name that
/// changes when the picture does.
class AppGroupWidgetPictureDataSource implements WidgetPictureDataSource {
  const AppGroupWidgetPictureDataSource(this._container);

  /// The App Group's container; null when the app may not use it.
  final Future<String?> Function() _container;

  static const folder = 'widget';

  @override
  Future<Map<String, String>> share(Set<String> paths) => _guard(() async {
    final container = await _container();
    if (container == null) return const {};
    final directory = await Directory(
      p.join(container, folder),
    ).create(recursive: true);
    final shared = <String, String>{};
    for (final path in paths) {
      final picture = File(path);
      if (!await picture.exists()) continue;
      final modified = (await picture.lastModified()).millisecondsSinceEpoch;
      final copy = p.join(
        directory.path,
        '${_name(path)}-$modified${p.extension(path)}',
      );
      if (!await File(copy).exists()) {
        // Copied aside first, so the widget never reads half a picture.
        await picture.copy('$copy.part');
        await File('$copy.part').rename(copy);
      }
      shared[path] = copy;
    }
    final kept = shared.values.toSet();
    await for (final entry in directory.list()) {
      if (entry is File && !kept.contains(entry.path)) await entry.delete();
    }
    return shared;
  });

  @override
  Future<void> clear() => _guard(() async {
    final container = await _container();
    if (container == null) return;
    final directory = Directory(p.join(container, folder));
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  /// A short name for [path] that stays the same from run to run (FNV-1a).
  static String _name(String path) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(path)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
