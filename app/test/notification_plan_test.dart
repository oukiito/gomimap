// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/schedule.dart';
import 'package:gomimap/l10n/generated/app_localizations.dart';
import 'package:gomimap/l10n/languages.dart';
import 'package:gomimap/notifications/notification_plan.dart';
import 'package:gomimap/notifications/notification_state.dart';
import 'package:gomimap/qa/qa_runtime.dart';

import 'support/dataset_fixture.dart';

void main() {
  final l10n = lookupAppLocalizations(savedLocale('ja')!);
  Map<String, Object?> plan({
    bool qa = false,
    String scenario = 'tomorrow',
    DateTime? instant,
    NotificationSettings settings = const NotificationSettings(enabled: true),
    DateTime? end,
  }) {
    final now = instant ?? DateTime.utc(2026, 10, 4, 20);
    final data = qaDataset(File(fixturePath).readAsStringSync(), scenario);
    final today = CalendarDate.inJapan(now);
    final calendar = demoCalendar(DemoArea.a, dataset: data);
    return notificationPlan(
      days: [for (var i = 0; i < 14; i++) calendar.onDate(today.addDays(i))],
      settings: settings,
      now: now,
      l10n: l10n,
      areaLabel: 'サンプルA',
      locale: 'ja',
      validUntil: end ?? data.period.end.startInJapanUtc,
      allowQaFixtures: qa,
    );
  }

  test(
    'ordinary builds never reserve owned fixtures even with reminders on',
    () {
      expect(plan()['entries'], isEmpty);
    },
  );
  test('off reserves nothing and morning starts at six in Japan', () {
    expect(
      plan(qa: true, settings: const NotificationSettings())['entries'],
      isEmpty,
    );
    final rows = plan(qa: true)['entries'] as List;
    expect(rows.first['date'], '2026-10-05');
    expect(
      rows.first['due'],
      DateTime.utc(2026, 10, 4, 21).millisecondsSinceEpoch,
    );
    expect(rows.first['title'], '今日2026-10-05のごみ');
  });
  test('past reminders are not backfilled and all-expired categories do not schedule', () {
    final rows =
        plan(qa: true, instant: DateTime.utc(2026, 10, 4, 22))['entries']
            as List;
    expect(rows.every((e) => e['date'] != '2026-10-05'), isTrue);
    final late =
        plan(
              qa: true,
              settings: const NotificationSettings(
                enabled: true,
                morningMinute: 600,
              ),
            )['entries']
            as List;
    expect(late, isEmpty);
  });
  test('a partial deadline reserves only the remaining category', () {
    final rows =
        plan(
              qa: true,
              scenario: 'multi',
              settings: const NotificationSettings(
                enabled: true,
                morningMinute: 510,
              ),
            )['entries']
            as List;
    expect(rows.first['collections'].map((e) => e['name']).toList(), ['資源']);
    expect(
      rows.first['expires'],
      DateTime.utc(2026, 10, 5, 0, 30).millisecondsSinceEpoch,
    );
  });
  test('evening prepares tomorrow; unknown days have no kind notification', () {
    final rows =
        plan(
              qa: true,
              scenario: 'normal',
              settings: const NotificationSettings(
                enabled: true,
                eveningEnabled: true,
              ),
            )['entries']
            as List;
    final evening = rows.firstWhere((e) => e['kind'] == 'evening');
    expect(
      evening['expires'],
      CalendarDate.parse(evening['date'])
          .startInJapanUtc
          .millisecondsSinceEpoch,
    );
    expect(rows.every((e) => e['date'] != '2026-10-08'), isTrue);
    expect(rows.length, lessThanOrEqualTo(28));
    expect(rows.map((e) => e['id']).toSet().length, rows.length);
  });
  test(
    'data validity is an exclusive cap, not extended to fill the horizon',
    () {
      expect(
        plan(qa: true, end: DateTime.utc(2026, 10, 4, 21))['entries'],
        isEmpty,
      );
      expect(
        plan(qa: true, instant: DateTime.utc(2027, 3, 1))['entries'],
        isEmpty,
      );
    },
  );
  test('fixture permission cannot make missing evidence notifyable', () {
    final data = qaDataset(File(fixturePath).readAsStringSync(), 'tomorrow');
    final original = demoCalendar(
      DemoArea.a,
      dataset: data,
    ).onDate(CalendarDate(2026, 10, 5));
    final missing = DaySchedule(
      day: original.day,
      areaId: 'a',
      municipalityId: 'demo-toshima',
      datasetVersion: data.version,
      fixture: true,
      status: ScheduleStatus.collection,
      collections: original.collections,
    );
    expect(
      notificationPlan(
        days: [missing],
        settings: const NotificationSettings(enabled: true),
        now: DateTime.utc(2026, 10, 4, 20),
        l10n: l10n,
        areaLabel: 'A',
        locale: 'ja',
        validUntil: DateTime.utc(2026, 10, 6),
        allowQaFixtures: true,
      )['entries'],
      isEmpty,
    );
  });
}
