// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/dataset_cache.dart';
import 'package:gomimap/data/dataset_cache_native.dart';

void main() {
  late Directory directory;
  late FileDatasetCache cache;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gomimap-cache-test-');
    cache = FileDatasetCache(directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  test('complete current and previous survive repository reconstruction; pending ignored', () async {
    expect(await cache.save('old'), isTrue);
    expect(await cache.save('new', previous: 'old'), isTrue);
    await File('${directory.path}/current.pending').writeAsString('unfinished');
    expect(await FileDatasetCache(directory).read(), ['new', 'old']);
  });
  test('unwritable candidate retains complete active and previous', () async {
    await cache.save('old');
    await Directory('${directory.path}/current.pending').create();
    expect(await cache.save('new', previous: 'old'), isFalse);
    expect(await cache.read(), ['old', 'old']);
  });
  test(
    'oversized save is refused and oversized/unreadable read skips to previous',
    () async {
      await cache.save('old');
      expect(await cache.save('x' * (maxCacheBytes + 1)), isFalse);
      expect(await cache.read(), ['old']);
      await File('${directory.path}/previous.json').writeAsString('previous');
      await File('${directory.path}/current.json')
          .writeAsString('x' * (maxCacheBytes + 1));
      expect(await cache.read(), ['previous']);
    },
  );
}
