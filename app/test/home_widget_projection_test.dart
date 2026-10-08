// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/widgets/widget_projection.dart';

import 'support/dataset_fixture.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  test('widget projection is one version/area with dated, localized shared outcomes', () {
    final text = buildWidgetProjection(
      dataset: fixtureDataset(),
      area: DemoArea.a,
      start: CalendarDate(2026, 10, 5),
      generatedAt: DateTime.utc(2026, 10, 5),
    );
    final json = jsonDecode(text) as Map<String, dynamic>;
    expect(json['areaId'], 'a');
    expect(json['datasetVersion'], 'toshima-demo-v1');
    expect(json['fixture'], true);
    expect(json['end'], '2026-11-09');
    final locales = json['locales'] as Map;
    expect(locales.length, 10);
    for (final variant in locales.values) {
      final days = variant['days'] as Map;
      expect(days.length, 35);
      expect(days['2026-10-05']['status'], 'collection');
      expect(days['2026-10-05']['lines'], hasLength(1));
      expect(days['2026-10-06']['status'], 'none');
      expect(days['2026-10-08']['status'], 'needsConfirmation');
      expect(days['2026-10-08']['lines'], isEmpty);
    }
    expect(locales['en']['days']['2026-10-05']['title'], 'Burnable waste');
    expect(locales['ja']['days']['2026-10-05']['lines'][0], contains('08:00'));
    if (const bool.fromEnvironment('GOMIMAP_EXPORT_WIDGET_FIXTURE')) {
      final file = File(
        'android/app/src/androidTest/assets/widget_projection.json',
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(text);
    } else {
      expect(
        jsonDecode(
          File('android/app/src/androidTest/assets/widget_projection.json')
              .readAsStringSync(),
        ),
        json,
      );
    }
  });
  test('missing data and coverage expiry never become no collection', () {
    for (final data in [null, fixtureDataset()]) {
      final json = jsonDecode(
        buildWidgetProjection(
          dataset: data,
          area: DemoArea.b,
          start: CalendarDate(2027, 2, 1),
          generatedAt: DateTime.utc(2027, 2, 1),
        ),
      );
      expect(json['areaId'], 'b');
      for (final variant in (json['locales'] as Map).values) {
        expect(variant['days']['2027-02-01']['status'], 'needsConfirmation');
      }
    }
  });
  test('multiple categories and distinct deadlines survive projection without losing one', () {
    final data = fixtureDataset((json) {
      json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
      json['baselines'][1]['recurrences'][0]['deadline'] = '09:30';
    });
    final json = jsonDecode(
      buildWidgetProjection(
        dataset: data,
        area: DemoArea.a,
        start: CalendarDate(2026, 10, 5),
        generatedAt: DateTime.utc(2026, 10, 5),
      ),
    );
    final lines = json['locales']['ja']['days']['2026-10-05']['lines'] as List;
    expect(lines.length, 2);
    expect(lines.join(' '), contains('08:00'));
    expect(lines.join(' '), contains('09:30'));
    final segments =
        json['locales']['ja']['days']['2026-10-05']['segments'] as List;
    expect(segments.map((entry) => entry['minute']), [0, 480, 570]);
    expect(segments[1]['lines'], hasLength(1));
    expect(segments[1]['lines'][0], contains('09:30'));
    expect(segments[2]['targetDate'], '2026-10-08');
    expect(segments[2]['status'], 'needsConfirmation');
    if (const bool.fromEnvironment('GOMIMAP_EXPORT_WIDGET_FIXTURE')) {
      File('android/app/src/androidTest/assets/widget_multi_projection.json')
          .writeAsStringSync(jsonEncode(json));
    } else {
      expect(
        jsonDecode(
          File(
            'android/app/src/androidTest/assets/widget_multi_projection.json',
          ).readAsStringSync(),
        ),
        json,
      );
    }
  });
}
