// SPDX-License-Identifier: GPL-3.0-or-later
// Explicit helper: flutter test tool/maestro_expectation_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/municipal_dataset.dart';
import 'package:gomimap/widgets/widget_projection.dart';

void main() {
  test(
    'export the current Japanese fixture expectation for the UI runner',
    () async {
      await initializeDateFormatting();
      final now = DateTime.now();
      final date = CalendarDate.inJapan(now);
      final japan = now.toUtc().add(const Duration(hours: 9));
      final minute = japan.hour * 60 + japan.minute;
      final data = MunicipalDataset.decode(
        File('../data/datasets/fixtures/toshima-demo-v1.json')
            .readAsStringSync(),
        allowFixtures: true,
      );
      final root = jsonDecode(
        buildWidgetProjection(
          dataset: data,
          area: DemoArea.a,
          start: date,
          generatedAt: now,
        ),
      ) as Map<String, dynamic>;
      final rows =
          root['locales']['ja']['days'][date.toString()]['segments'] as List;
      final segment = rows.lastWhere(
        (entry) => (entry['minute'] as int) <= minute,
      );
      String pattern(String value) =>
          '^${value.split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s+')}'
          r'$';
      final output = File('../.tooling/maestro-results/expectation.json');
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(
        jsonEncode({
          'generatedAt': now.toUtc().toIso8601String(),
          'fixture': true,
          'datasetVersion': root['datasetVersion'],
          'env': {
            'APP_ID': 'dev.gomimap.gomimap',
            'EXPECTED_DATE_PATTERN': pattern(segment['dateLabel'] as String),
            'EXPECTED_DESCRIPTION_PATTERN': pattern(segment['title'] as String),
            'WIDGET_DATE_ID': RegExp.escape(
              'dev.gomimap.gomimap:id/widget_date',
            ),
            'WIDGET_ROOT_ID': RegExp.escape(
              'dev.gomimap.gomimap:id/widget_root',
            ),
            'WIDGET_DESCRIPTION_ID': r'dev\.gomimap\.gomimap:id/(compact_title|widget_row_text|widget_empty)',
          },
        }),
      );
      expect(segment['title'], isNotEmpty);
      expect(segment['targetDate'], isNotEmpty);
    },
  );
}
