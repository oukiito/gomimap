// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dataset_cache.dart';

Future<DatasetCache> createDatasetCache() async =>
    BrowserDatasetCache(await SharedPreferences.getInstance());

/// Web preview cache only. Browser storage may be cleared/denied/evicted.
class BrowserDatasetCache implements DatasetCache {
  BrowserDatasetCache(this.preferences);
  final SharedPreferences preferences;
  static const currentKey = 'dataset.demo.current.v1';
  static const previousKey = 'dataset.demo.previous.v1';

  @override
  Future<List<String>> read() async {
    await preferences.reload();
    return [
      for (final key in [currentKey, previousKey])
        if (preferences.get(key) case final String value)
          if (utf8.encode(value).length <= maxCacheBytes) value,
    ];
  }

  @override
  Future<bool> save(String record, {String? previous}) async {
    try {
      if (utf8.encode(record).length > maxCacheBytes ||
          (previous != null && utf8.encode(previous).length > maxCacheBytes)) {
        return false;
      }
      if (previous != null &&
          !await preferences.setString(previousKey, previous)) {
        return false;
      }
      if (!await preferences.setString(currentKey, record)) return false;
      await preferences.reload();
      return preferences.get(currentKey) == record;
    } catch (_) {
      try {
        await preferences.reload();
      } catch (_) {
        // In-memory repository still retains its previously confirmed record.
      }
      return false;
    }
  }
}
