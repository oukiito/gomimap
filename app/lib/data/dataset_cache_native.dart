// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'dataset_cache.dart';

Future<DatasetCache> createDatasetCache() async => FileDatasetCache(
  Directory('${(await getApplicationSupportDirectory()).path}/datasets-demo'),
);

class FileDatasetCache implements DatasetCache {
  FileDatasetCache(this.directory);
  final Directory directory;

  @override
  Future<List<String>> read() async {
    final records = <String>[];
    for (final name in ['current', 'previous']) {
      try {
        final file = File('${directory.path}/$name.json');
        final bytes = <int>[];
        await for (final chunk in file.openRead()) {
          if (bytes.length + chunk.length > maxCacheBytes) {
            throw const FormatException('Cache too large');
          }
          bytes.addAll(chunk);
        }
        records.add(utf8.decode(bytes));
      } catch (_) {
        // Missing, oversized or unreadable record: try the other complete file.
      }
    }
    return records;
  }

  Future<void> _replace(String name, String text) async {
    final bytes = utf8.encode(text);
    if (bytes.length > maxCacheBytes) {
      throw const FormatException('Cache too large');
    }
    final temporary = File('${directory.path}/$name.pending');
    await temporary.writeAsBytes(bytes, flush: true);
    // Same-directory rename replaces one complete file. .pending is never read.
    await temporary.rename('${directory.path}/$name.json');
  }

  @override
  Future<bool> save(String record, {String? previous}) async {
    try {
      await directory.create(recursive: true);
      if (previous != null) await _replace('previous', previous);
      await _replace('current', record);
      return true;
    } catch (_) {
      return false;
    }
  }
}
