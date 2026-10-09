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
import 'package:gomimap/qa/qa_runtime.dart';

void main() {
  test('export the current fixture expectation for the UI runner', () async {
    await initializeDateFormatting();
    const scenario = String.fromEnvironment('GOMIMAP_MAESTRO_SCENARIO');
    const instant = String.fromEnvironment('GOMIMAP_MAESTRO_INSTANT');
    if (scenario.isEmpty != instant.isEmpty) {
      throw StateError('A QA expectation needs both scenario and UTC instant');
    }
    final now = instant.isEmpty ? DateTime.now() : DateTime.parse(instant);
    final date = CalendarDate.inJapan(now);
    final japan = now.toUtc().add(const Duration(hours: 9));
    final minute = japan.hour * 60 + japan.minute;
    final source = File('../data/datasets/fixtures/toshima-demo-v1.json')
        .readAsStringSync();
    final data = scenario.isEmpty
        ? MunicipalDataset.decode(source, allowFixtures: true)
        : qaDataset(source, scenario);
    final appId = scenario.isEmpty ? 'dev.gomimap.gomimap' : qaPackage;
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
    final lines = segment['lines'] as List;
    String pattern(String value) =>
        '^${value.split(RegExp(r'\s+')).map(RegExp.escape).join(r'\s+')}'
        r'$';
    final output = File('../.tooling/maestro-results/expectation.json');
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      jsonEncode({
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'clockInstant': now.toUtc().toIso8601String(),
        'fixture': true,
        'datasetVersion': root['datasetVersion'],
        'locale': locale,
        'scenario': scenario,
        'env': {
          'APP_ID': appId,
          'CLOCK_MS': now.millisecondsSinceEpoch.toString(),
          'CLOCK_SCENARIO': scenario,
          'EXPECTED_LOCALE': locale,
          'RUN_ID': DateTime.now().toUtc().toIso8601String().replaceAll(
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
            lines.isEmpty ? '' : lines.first as String,
          ),
          'EXPECTED_SECOND_DEADLINE_PATTERN': pattern(
            lines.length < 2 ? '' : lines[1] as String,
          ),
          'EXPECTED_HAS_SECOND_DEADLINE': lines.length > 1 ? 'true' : 'false',
          'EXPECTED_HAS_DEADLINE': lines.isNotEmpty ? 'true' : 'false',
          'WIDGET_DEADLINE_ID': RegExp.escape('$appId:id/widget_row_text'),
          'WIDGET_DATE_ID': RegExp.escape('$appId:id/widget_date'),
          'WIDGET_ROOT_ID': RegExp.escape('$appId:id/widget_root'),
          'WIDGET_ROWS_ID': RegExp.escape('$appId:id/widget_rows'),
          'WIDGET_AREA_ID':
              '${RegExp.escape(appId)}:id/(compact_area|widget_area)',
          'WIDGET_DESCRIPTION_ID':
              '${RegExp.escape(appId)}:id/(compact_title|widget_row_text|widget_empty)',
        },
      }),
    );
    expect(segment['title'], isNotEmpty);
    expect(segment['targetDate'], isNotEmpty);
  });
}
