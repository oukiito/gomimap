// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/schedule.dart';
import 'package:gomimap/domain/schedule_focus.dart';

import 'support/dataset_fixture.dart';

void main() {
  List<DaySchedule> days({bool multi = false, int day = 5}) {
    final data = fixtureDataset(
      multi
          ? (json) {
              json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
              json['baselines'][1]['recurrences'][0]['deadline'] = '09:30';
            }
          : null,
    );
    final calendar = demoCalendar(DemoArea.a, dataset: data);
    return [
      for (var i = 0; i < 35; i++)
        calendar.onDate(CalendarDate(2026, 10, day).addDays(i)),
    ];
  }

  test('switch at local disposal deadline, not a hardcoded 10am', () {
    final entries = days();
    expect(scheduleFocus(entries, 479).day, entries.first.day);
    expect(scheduleFocus(entries, 480).day, CalendarDate(2026, 10, 7));
    expect(scheduleFocus(entries, 600).day, CalendarDate(2026, 10, 7));
    expect(entries.first.collections, hasLength(1)); // Original day unchanged.
  });
  test('multiple deadlines leave still available categories, then move on', () {
    final entries = days(multi: true);
    expect(focusBoundaries(entries.first), [0, 480, 570]);
    expect(scheduleFocus(entries, 479).collections, hasLength(2));
    final remaining = scheduleFocus(entries, 480);
    expect(remaining.collections, hasLength(1));
    expect(remaining.collections.single.deadline, LocalTime(9, 30));
    expect(scheduleFocus(entries, 570).day, CalendarDate(2026, 10, 8));
    expect(
      scheduleFocus(entries, 570).status,
      ScheduleStatus.needsConfirmation,
    );
  });
  test('uncertainty is never bypassed or expired by clock time', () {
    expect(scheduleFocus(days(day: 7), 600).day, CalendarDate(2026, 10, 8));
    expect(
      scheduleFocus(days(day: 7), 600).status,
      ScheduleStatus.needsConfirmation,
    );
    expect(scheduleFocus(days(day: 8), 1439).day, CalendarDate(2026, 10, 8));
  });
  test(
    'no collection today shows next; bounded horizon never invents next',
    () {
      expect(scheduleFocus(days(day: 6), 0).day, CalendarDate(2026, 10, 7));
      final today = days().first;
      expect(
        scheduleFocus([today], 480).status,
        ScheduleStatus.needsConfirmation,
      );
    },
  );
}
