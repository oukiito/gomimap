// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/dataset_cache_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeniedPreferences implements SharedPreferences {
  final persisted = <String, Object>{BrowserDatasetCache.currentKey: 'old'};
  final optimistic = <String, Object>{};
  @override
  Object? get(String key) => optimistic[key] ?? persisted[key];
  @override
  Future<bool> setString(String key, String value) async {
    optimistic[key] = value;
    return false;
  }

  @override
  Future<void> reload() async => optimistic.clear();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'browser cache persists complete values and ignores wrong types',
    () async {
      SharedPreferences.setMockInitialValues({
        BrowserDatasetCache.currentKey: 42,
        BrowserDatasetCache.previousKey: 'old',
      });
      final preferences = await SharedPreferences.getInstance();
      expect(await BrowserDatasetCache(preferences).read(), ['old']);
      expect(
        await BrowserDatasetCache(preferences).save('new', previous: 'old'),
        isTrue,
      );
      expect(await BrowserDatasetCache(preferences).read(), ['new', 'old']);
    },
  );
  test(
    'denied browser storage does not expose optimistic writes after reload',
    () async {
      final cache = BrowserDatasetCache(DeniedPreferences());
      expect(await cache.save('new'), isFalse);
      expect(await cache.read(), ['old']);
    },
  );
}
