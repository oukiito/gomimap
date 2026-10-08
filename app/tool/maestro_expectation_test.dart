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
import 'package:gomimap/l10n/languages.dart';
import 'package:gomimap/l10n/generated/app_localizations.dart';

void main() {
  test('export the current fixture expectation for the UI runner', () async {
    await initializeDateFormatting();
    final now = DateTime.now();
    final date = CalendarDate.inJapan(now);
    final japan = now.toUtc().add(const Duration(hours: 9));
    final minute = japan.hour * 60 + japan.minute;
    final data = MunicipalDataset.decode(
      File('../data/datasets/fixtures/toshima-demo-v1.json').readAsStringSync(),
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
    const locale = String.fromEnvironment(
      'GOMIMAP_MAESTRO_LOCALE',
      defaultValue: 'ja',
    );
    final variant = root['locales'][locale];
    if (variant == null) throw StateError('Unsupported test locale');
    final l10n = lookupAppLocalizations(
      appLocales.firstWhere((value) => value.toLanguageTag() == locale),
    );
    final rows = variant['days'][date.toString()]['segments'] as List;
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
        'locale': locale,
        'env': {
          'APP_ID': 'dev.gomimap.gomimap',
          'EXPECTED_LOCALE': locale,
          'RUN_ID': now.toUtc().toIso8601String().replaceAll(
            RegExp('[^a-zA-Z0-9]'),
            '',
          ),
          'EXPECTED_DATE_PATTERN': pattern(segment['dateLabel'] as String),
          'EXPECTED_DESCRIPTION_PATTERN': pattern(segment['title'] as String),
          'EXPECTED_AREA_PATTERN': pattern(variant['areaName'] as String),
          'EXPECTED_APP_AREA_PATTERN': pattern(
            l10n.collectionArea(variant['areaName'] as String),
          ),
          'EXPECTED_DEADLINE_PATTERN': pattern(
            (segment['lines'] as List).join('\n'),
          ),
          'EXPECTED_HAS_DEADLINE': (segment['lines'] as List).isNotEmpty
              ? 'true'
              : 'false',
          'WIDGET_DEADLINE_ID': RegExp.escape(
            'dev.gomimap.gomimap:id/widget_row_text',
          ),
          'WIDGET_DATE_ID': RegExp.escape('dev.gomimap.gomimap:id/widget_date'),
          'WIDGET_ROOT_ID': RegExp.escape('dev.gomimap.gomimap:id/widget_root'),
          'WIDGET_AREA_ID':
              r'dev\.gomimap\.gomimap:id/(compact_area|widget_area)',
          'WIDGET_DESCRIPTION_ID': r'dev\.gomimap\.gomimap:id/(compact_title|widget_row_text|widget_empty)',
        },
      }),
    );
    expect(segment['title'], isNotEmpty);
    expect(segment['targetDate'], isNotEmpty);
  });
}
