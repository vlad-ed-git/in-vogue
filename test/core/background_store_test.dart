import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/persistence/directory_key_value_store.dart';

void main() {
  test(
    'background state survives a new worker and reads current disk values',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'background-store',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = DirectoryKeyValueStore(directory.path);
      await first.writeString('try_on_jobs', '{"task":"running"}');
      final second = DirectoryKeyValueStore(directory.path);
      expect(second.readString('try_on_jobs'), '{"task":"running"}');
      await second.writeString('try_on_jobs', '{"task":"finished"}');
      expect(first.readString('try_on_jobs'), '{"task":"finished"}');
      await first.delete('try_on_jobs');
      expect(second.readString('try_on_jobs'), isNull);
      await first.close();
      await second.close();
    },
  );
}
