// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/bundled_dataset.dart';
import 'package:gomimap/domain/schedule.dart';

import 'support/dataset_fixture.dart';

class TextBundle extends CachingAssetBundle {
  TextBundle(this.text);
  final String? text;
  @override
  Future<ByteData> load(String key) async {
    if (text == null) throw StateError('Missing asset');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text!)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled asset is the prepared canonical fixture and is used by the calendar', () async {
    final text = await rootBundle.loadString(demoDatasetAsset);
    expect(jsonDecode(text), fixtureJson());
    final data = await loadBundledDemoDataset();
    expect(data, isNotNull);
    expect(
      ScheduleCalendar(
        dataset: data,
        areaId: 'a',
      ).on(DateTime(2026, 10, 5)).labels,
      ['burnable'],
    );
  });
  test('missing/malformed bundled data returns an unknown schedule without inventing a default', () async {
    for (final text in [null, 'bad-json']) {
      final data = await loadBundledDemoDataset(bundle: TextBundle(text));
      expect(data, isNull);
      expect(
        ScheduleCalendar(
          dataset: data,
          areaId: 'a',
        ).on(DateTime(2026, 10, 5)).status,
        ScheduleStatus.needsConfirmation,
      );
    }
  });
  test(
    'wrong municipality or revision is not loaded under the Toshima demo label',
    () async {
      for (final field in ['municipality', 'version']) {
        final json = fixtureJson();
        if (field == 'municipality') {
          json['municipality']['id'] = 'other-city';
        } else {
          json['version'] = 'other-v2';
        }
        expect(
          await loadBundledDemoDataset(bundle: TextBundle(jsonEncode(json))),
          isNull,
        );
      }
    },
  );
}
