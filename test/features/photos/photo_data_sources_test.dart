import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_check_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_picker_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_store_data_source.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../helpers/memory_store.dart';
import 'photo_data_sources_test.mocks.dart' as base;

// The mixin makes image_picker accept the mock as its platform.
class _MockImagePickerPlatform extends base.MockImagePickerPlatform
    with MockPlatformInterfaceMixin {}

@GenerateMocks([], customMocks: [MockSpec<ImagePickerPlatform>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoPickerDataSourceImpl', () {
    late _MockImagePickerPlatform platform;
    late PhotoPickerDataSourceImpl source;

    setUp(() {
      final original = ImagePickerPlatform.instance;
      addTearDown(() => ImagePickerPlatform.instance = original);
      ImagePickerPlatform.instance = platform = _MockImagePickerPlatform();
      source = PhotoPickerDataSourceImpl();
    });

    void answer(Future<XFile?> Function() result) => when(
      platform.getImageFromSource(
        source: anyNamed('source'),
        options: anyNamed('options'),
      ),
    ).thenAnswer((_) => result());

    test(
      'opens the photo library, never the camera, with size limits',
      () async {
        answer(() async => XFile('/tmp/picked.jpg'));
        expect(await source.choose(), '/tmp/picked.jpg');
        verify(
          platform.getImageFromSource(
            source: ImageSource.gallery,
            options: argThat(
              isA<ImagePickerOptions>()
                  .having((o) => o.maxWidth, 'maxWidth', 2048)
                  .having((o) => o.maxHeight, 'maxHeight', 2048)
                  .having((o) => o.imageQuality, 'imageQuality', 90)
                  .having(
                    (o) => o.requestFullMetadata,
                    'requestFullMetadata',
                    isFalse,
                  ),
              named: 'options',
            ),
          ),
        ).called(1);
      },
    );

    test('chooses nothing when the person cancels', () async {
      answer(() async => null);
      expect(await source.choose(), isNull);
    });

    test('reports a picker error as a photo problem', () async {
      answer(() => throw PlatformException(code: 'invalid_image'));
      await expectLater(source.choose(), throwsA(isA<PhotoException>()));
    });
  });

  group('PhotoCheckDataSourceImpl', () {
    const channel = MethodChannel(PhotoCheckDataSourceImpl.channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final source = PhotoCheckDataSourceImpl();
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('asks the native check about the photo file', () async {
      MethodCall? asked;
      messenger.setMockMethodCallHandler(channel, (call) async {
        asked = call;
        return true;
      });
      expect(await source.isFullLength('/tmp/me.jpg'), isTrue);
      expect(asked?.method, 'isFullLength');
      expect(asked?.arguments, {'path': '/tmp/me.jpg'});
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      expect(await source.isFullLength('/tmp/me.jpg'), isFalse);
    });

    test('reports an unreadable photo or a missing check', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) => throw PlatformException(code: 'unreadable'),
      );
      await expectLater(
        source.isFullLength('/tmp/me.jpg'),
        throwsA(isA<PhotoException>()),
      );
      messenger.setMockMethodCallHandler(channel, null);
      await expectLater(
        source.isFullLength('/tmp/me.jpg'),
        throwsA(isA<PhotoException>()),
      );
    });
  });

  group('PhotoStoreDataSourceImpl', () {
    late Directory root;
    late MemoryStore store;
    late PhotoStoreDataSourceImpl source;

    Future<String> picked(String name, String content) async {
      final file = File(path.join(root.path, 'picked', name));
      await file.create(recursive: true);
      await file.writeAsString(content);
      return file.path;
    }

    setUp(() async {
      root = await Directory.systemTemp.createTemp('in_vogue_photos_');
      store = MemoryStore();
      source = PhotoStoreDataSourceImpl(
        directory: path.join(root.path, 'photos'),
        store: store,
      );
    });
    tearDown(() => root.delete(recursive: true));

    test('keeps a private copy and remembers it', () async {
      expect(source.kept(PhotoRole.body), isNull);
      final photo = await source.keep(
        await picked('a.jpg', 'first'),
        PhotoRole.body,
      );
      expect(photo.role, PhotoRole.body);
      expect(photo.revision, 1);
      expect(path.isWithin(path.join(root.path, 'photos'), photo.path), isTrue);
      expect(File(photo.path).readAsStringSync(), 'first');
      expect(source.kept(PhotoRole.body), photo);
    });

    test(
      'replaces the last photo, counts revisions and deletes the old file',
      () async {
        final first = await source.keep(
          await picked('a.jpg', 'first'),
          PhotoRole.body,
        );
        final second = await source.keep(
          await picked('b.png', 'second'),
          PhotoRole.body,
        );
        expect(second.revision, 2);
        expect(path.extension(second.path), '.png');
        expect(File(first.path).existsSync(), isFalse);
        expect(source.kept(PhotoRole.body), second);
      },
    );

    test('keeps body and face photos apart', () async {
      final body = await source.keep(
        await picked('a.jpg', 'body'),
        PhotoRole.body,
      );
      final face = await source.keep(
        await picked('b.jpg', 'face'),
        PhotoRole.face,
      );
      expect(source.kept(PhotoRole.body), body);
      expect(source.kept(PhotoRole.face), face);
      expect(face.revision, 1);
    });

    test('finds a kept photo after the app folder moves', () async {
      final photo = await source.keep(
        await picked('a.jpg', 'body'),
        PhotoRole.body,
      );
      final moved = Directory(path.join(root.path, 'moved'));
      await Directory(path.join(root.path, 'photos')).rename(moved.path);
      final reopened = PhotoStoreDataSourceImpl(
        directory: moved.path,
        store: store,
      );
      expect(
        reopened.kept(PhotoRole.body),
        UserPhoto(
          role: PhotoRole.body,
          path: path.join(moved.path, path.basename(photo.path)),
          revision: 1,
        ),
      );
    });

    test('forgets a kept photo whose file is gone', () async {
      final photo = await source.keep(
        await picked('a.jpg', 'body'),
        PhotoRole.body,
      );
      await File(photo.path).delete();
      expect(source.kept(PhotoRole.body), isNull);
    });

    test('reports a photo it cannot copy as a cache problem', () async {
      await expectLater(
        source.keep(path.join(root.path, 'missing.jpg'), PhotoRole.body),
        throwsA(isA<CacheException>()),
      );
      expect(source.kept(PhotoRole.body), isNull);
    });
  });
}
