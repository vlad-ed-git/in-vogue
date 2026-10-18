import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/home_widget/data/data_sources/widget_picture_data_source.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory group;
  late AppGroupWidgetPictureDataSource pictures;

  setUp(() {
    root = Directory.systemTemp.createTempSync('widget_pictures_');
    group = Directory(p.join(root.path, 'group'))..createSync();
    pictures = AppGroupWidgetPictureDataSource(() async => group.path);
  });

  tearDown(() => root.deleteSync(recursive: true));

  File picture(String name, String bytes) =>
      File(p.join(root.path, 'app', name))
        ..createSync(recursive: true)
        ..writeAsStringSync(bytes);

  Directory shared() =>
      Directory(p.join(group.path, AppGroupWidgetPictureDataSource.folder));

  test('copies each picture into the App Group, where the iPhone widget '
      'reads it', () async {
    final outfit = picture('outfits/uid-1/2026-10-19.jpg', 'outfit');
    final body = picture('photos/body.png', 'body');
    final copies = await pictures.share({outfit.path, body.path});
    expect(copies.keys, unorderedEquals([outfit.path, body.path]));
    for (final MapEntry(key: source, value: copy) in copies.entries) {
      expect(p.isWithin(shared().path, copy), isTrue);
      expect(p.extension(copy), p.extension(source));
      expect(File(copy).readAsStringSync(), File(source).readAsStringSync());
    }
  });

  test('leaves out a picture that is missing', () async {
    expect(
      await pictures.share({p.join(root.path, 'app', 'gone.jpg')}),
      isEmpty,
    );
  });

  test('copies a picture again only when it changes, and drops the copies '
      'no longer shown', () async {
    final outfit = picture('outfits/uid-1/2026-10-19.jpg', 'first');
    final first = (await pictures.share({outfit.path}))[outfit.path]!;
    expect((await pictures.share({outfit.path}))[outfit.path], first);

    outfit
      ..writeAsStringSync('second')
      ..setLastModifiedSync(DateTime(2030));
    final second = (await pictures.share({outfit.path}))[outfit.path]!;
    expect(second, isNot(first));
    expect(File(second).readAsStringSync(), 'second');
    expect(File(first).existsSync(), isFalse);

    await pictures.share(<String>{});
    expect(shared().listSync(), isEmpty);
  });

  test('stops sharing every picture', () async {
    await pictures.share({picture('photos/body.png', 'body').path});
    await pictures.clear();
    expect(shared().existsSync(), isFalse);
    await pictures.clear();
  });

  test('shares nothing when the app may not use the App Group', () async {
    final none = AppGroupWidgetPictureDataSource(() async => null);
    expect(
      await none.share({picture('photos/body.png', 'body').path}),
      <String, String>{},
    );
    await none.clear();
  });

  test('says when the App Group cannot be written', () async {
    final notFolder = File(p.join(root.path, 'not-a-folder'))
      ..writeAsStringSync('');
    final broken = AppGroupWidgetPictureDataSource(() async => notFolder.path);
    await expectLater(
      broken.share({picture('photos/body.png', 'body').path}),
      throwsA(isA<CacheException>()),
    );
  });

  test(
    "Android's widget reads the pictures where the app keeps them",
    () async {
      expect(
        await const InPlaceWidgetPictureDataSource().share({'/app/body.png'}),
        {'/app/body.png': '/app/body.png'},
      );
    },
  );
}
