// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/schedule.dart';

void main() {
  ScheduleCalendar calendar({
    Map<DateTime, List<String>> exceptions = const {},
    Set<DateTime> uncertain = const {},
  }) => ScheduleCalendar(
    validFrom: DateTime(2026, 1, 1),
    validUntil: DateTime(2026, 12, 31),
    rules: const [
      CollectionRule('金属', {5}, monthWeeks: {1, 3}),
    ],
    exceptions: exceptions,
    uncertainDates: uncertain,
  );
  test('first and third weekdays are not an every-other-week sequence', () {
    final value = calendar();
    expect(value.on(DateTime(2026, 1, 2)).labels, ['金属']);
    expect(value.on(DateTime(2026, 1, 16)).labels, ['金属']);
    expect(value.on(DateTime(2026, 1, 30)).status, ScheduleStatus.none);
    expect(value.on(DateTime(2026, 2, 6)).labels, ['金属']);
  });
  test(
    'reviewed exceptions replace regular collection, including cancellation',
    () {
      final value = calendar(
        exceptions: {
          DateTime(2026, 1, 2): [],
          DateTime(2026, 1, 3): ['振替収集'],
        },
      );
      expect(value.on(DateTime(2026, 1, 2)).status, ScheduleStatus.none);
      expect(value.on(DateTime(2026, 1, 3)).labels, ['振替収集']);
    },
  );
  test('uncertainty wins over both regular and exception schedules', () {
    final value = calendar(
      exceptions: {
        DateTime(2026, 1, 2): ['振替'],
      },
      uncertain: {DateTime(2026, 1, 2)},
    );
    final result = value.on(DateTime(2026, 1, 2, 6));
    expect(result.status, ScheduleStatus.needsConfirmation);
    expect(result.labels, isEmpty);
  });
  test('validity is inclusive and year boundaries remain unknown', () {
    final value = calendar();
    expect(
      value.on(DateTime(2025, 12, 31)).status,
      ScheduleStatus.needsConfirmation,
    );
    expect(value.on(DateTime(2026, 1, 1)).status, ScheduleStatus.none);
    expect(value.on(DateTime(2026, 12, 31, 23)).status, ScheduleStatus.none);
    expect(
      value.on(DateTime(2027, 1, 1)).status,
      ScheduleStatus.needsConfirmation,
    );
  });
  test('multiple categories coexist without duplicate labels', () {
    final value = ScheduleCalendar(
      validFrom: DateTime(2026),
      validUntil: DateTime(2027),
      rules: const [
        CollectionRule('燃やすごみ', {1}),
        CollectionRule('資源', {1}),
        CollectionRule('資源', {1}),
      ],
    );
    expect(value.on(DateTime(2026, 10, 5)).labels, ['燃やすごみ', '資源']);
  });
}
