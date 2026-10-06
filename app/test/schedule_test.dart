// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/schedule.dart';

import 'support/dataset_fixture.dart';

void main() {
  test(
    'an incomplete manually created projection is not a notification candidate',
    () {
      final projection = DaySchedule(
        day: CalendarDate.parse('2026-10-05'),
        areaId: 'a',
        status: ScheduleStatus.collection,
      );
      expect(projection.canNotify, isFalse);
    },
  );
  ScheduleCalendar calendar([void Function(Map<String, dynamic>)? change]) =>
      ScheduleCalendar(dataset: fixtureDataset(change), areaId: 'a');
  test(
    'first/third Friday is monthly occurrence, not alternating ISO weeks',
    () {
      final value = calendar();
      expect(value.on(DateTime(2026, 1, 2)).labels, ['metals']);
      expect(value.on(DateTime(2026, 1, 16)).labels, ['metals']);
      expect(value.on(DateTime(2026, 1, 30)).status, ScheduleStatus.none);
      expect(value.on(DateTime(2026, 2, 6)).labels, ['metals']);
    },
  );
  test('fifth occurrence and leap day use civil dates', () {
    final value = calendar((json) {
      json['baselines'][2]['recurrences'][0]['monthOccurrences'] = [5];
    });
    expect(value.on(DateTime(2026, 1, 30)).labels, ['metals']);
    expect(value.on(DateTime(2026, 2, 27)).status, ScheduleStatus.none);
    expect(
      CalendarDate.parse('2028-02-29').addDays(1).toString(),
      '2028-03-01',
    );
    expect(() => CalendarDate.parse('2026-02-29'), throwsFormatException);
  });
  test(
    'category cancellation preserves another collection on the same day',
    () {
      final value = calendar((json) {
        json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
        json['exceptions'].add({
          'id': 'cancel-monday',
          'areaId': 'a',
          'categoryId': 'burnable',
          'date': '2026-10-05',
          'action': 'cancel',
          'sourceIds': ['schedule'],
        });
      });
      expect(value.on(DateTime(2026, 10, 5)).labels, ['recyclables']);
    },
  );
  test(
    'addition supplies its own category/deadline on a normally empty day',
    () {
      final value = calendar((json) {
        json['exceptions'].add({
          'id': 'extra',
          'areaId': 'a',
          'categoryId': 'recyclables',
          'date': '2026-10-03',
          'action': 'add',
          'deadline': '07:30',
          'sourceIds': ['schedule'],
        });
      });
      final result = value.on(DateTime(2026, 10, 3));
      expect(result.labels, ['recyclables']);
      expect(result.collections.single.deadline.toString(), '07:30');
    },
  );
  test(
    'year-crossing move cancels old date and adds to explicit target only',
    () {
      final value = calendar();
      expect(value.on(DateTime(2026, 12, 31)).status, ScheduleStatus.none);
      expect(value.on(DateTime(2027, 1, 1)).status, ScheduleStatus.none);
      expect(value.on(DateTime(2027, 1, 2)).labels, [
        'burnable',
        'recyclables',
      ]);
      expect(value.on(DateTime(2026, 1, 2)).labels, ['metals']);
    },
  );
  test(
    'explicit uncertainty wins over cancellation or an otherwise empty day',
    () {
      final value = calendar((json) {
        json['exceptions'].add({
          'id': 'known-cancel',
          'areaId': 'a',
          'categoryId': 'burnable',
          'date': '2026-10-08',
          'action': 'cancel',
          'sourceIds': ['schedule'],
        });
      });
      final result = value.on(DateTime(2026, 10, 8, 6));
      expect(result.status, ScheduleStatus.needsConfirmation);
      expect(result.labels, isEmpty);
      expect(result.reasons, contains(ScheduleReason.unknownException));
      expect(result.canNotify, isFalse);
    },
  );
  test('period start is included and end is excluded', () {
    final value = calendar();
    expect(
      value.on(DateTime(2025, 12, 31)).status,
      ScheduleStatus.needsConfirmation,
    );
    expect(value.on(DateTime(2026, 1, 1)).status, ScheduleStatus.collection);
    expect(value.on(DateTime(2027, 1, 31, 23)).status, ScheduleStatus.none);
    expect(
      value.on(DateTime(2027, 2, 1)).status,
      ScheduleStatus.needsConfirmation,
    );
  });
  test(
    'Japan midnight is evaluated from the instant, including a foreign offset',
    () {
      final value = calendar();
      expect(
        value.onInstant(DateTime.parse('2026-10-04T14:59:59Z')).status,
        ScheduleStatus.none,
      );
      final atMidnight = value.onInstant(
        DateTime.parse('2026-10-04T15:00:00Z'),
      );
      expect(atMidnight.day.toString(), '2026-10-05');
      expect(atMidnight.labels, ['burnable']);
      expect(
        value.onInstant(DateTime.parse('2026-10-04T08:00:00-07:00')).day,
        atMidnight.day,
      );
      expect(
        atMidnight.day.startInJapanUtc,
        DateTime.parse('2026-10-04T15:00:00Z'),
      );
    },
  );
  test(
    'missing baseline cannot be treated as no collection even on Sunday',
    () {
      final value = calendar((json) {
        json['baselines'].removeAt(2);
      });
      for (final date in [DateTime(2026, 10, 4), DateTime(2026, 10, 5)]) {
        final result = value.on(date);
        expect(result.status, ScheduleStatus.needsConfirmation);
        expect(result.reasons, contains(ScheduleReason.missingBaseline));
      }
    },
  );
  test('explicit reviewed empty recurrence differs from missing data', () {
    final value = calendar((json) {
      json['baselines'][2]['recurrences'] = [];
    });
    expect(value.on(DateTime(2026, 10, 2)).status, ScheduleStatus.none);
  });
  test('pending calendar evidence makes even an empty Sunday uncertain', () {
    final value = calendar((json) {
      json['sources'][1]['review'] = 'pending';
    });
    expect(
      value.on(DateTime(2026, 10, 4)).status,
      ScheduleStatus.needsConfirmation,
    );
    expect(
      value.on(DateTime(2026, 10, 5)).status,
      ScheduleStatus.needsConfirmation,
    );
    final separate = calendar((json) {
      json['sources'][2]['review'] = 'pending';
    });
    expect(
      separate.on(DateTime(2026, 10, 5)).status,
      ScheduleStatus.collection,
    );
  });
  test('evidence expiry keeps prior dates valid but blocks the end date', () {
    final value = calendar((json) {
      json['sources'][1]['validPeriod']['end'] = '2026-10-05';
    });
    expect(value.on(DateTime(2026, 10, 4)).status, ScheduleStatus.none);
    expect(
      value.on(DateTime(2026, 10, 5)).status,
      ScheduleStatus.needsConfirmation,
    );
  });
  test('conflicting deadlines do not choose a convenient value', () {
    final value = calendar((json) {
      json['baselines'][0]['recurrences'].add({
        'weekdays': [1],
        'monthOccurrences': [],
        'deadline': '07:30',
      });
    });
    final result = value.on(DateTime(2026, 10, 5));
    expect(result.status, ScheduleStatus.needsConfirmation);
    expect(result.reasons, contains(ScheduleReason.conflictingDeadline));
  });
  test('duplicate matching recurrences yield one category; multiple categories remain', () {
    final value = calendar((json) {
      json['baselines'][0]['recurrences'].add({
        'weekdays': [1],
        'monthOccurrences': [],
        'deadline': '08:00',
      });
      json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
    });
    expect(value.on(DateTime(2026, 10, 5)).labels, ['burnable', 'recyclables']);
  });
  test('unsupported district and unavailable data are unknown, never nearest/default', () {
    for (final value in [
      ScheduleCalendar(dataset: fixtureDataset(), areaId: 'missing'),
      const ScheduleCalendar(dataset: null, areaId: 'a'),
    ]) {
      expect(
        value.on(DateTime(2026, 10, 5)).status,
        ScheduleStatus.needsConfirmation,
      );
    }
  });
  test('shared projection keeps version, scoped IDs, deadline, evidence and fixture marker', () {
    final result = calendar().on(DateTime(2026, 10, 5));
    final projected =
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
    expect(projected['municipalityId'], 'demo-toshima');
    expect(projected['datasetVersion'], 'toshima-demo-v1');
    expect(projected['date'], '2026-10-05');
    expect(projected['collections'][0]['deadline'], '08:00');
    expect(projected['sources'].keys, contains('schedule'));
    expect(projected['fixture'], isTrue);
    expect(result.canNotify, isFalse);
    expect(() => result.collections.clear(), throwsUnsupportedError);
  });
}
