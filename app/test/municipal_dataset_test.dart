// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/municipal_dataset.dart';
import 'package:gomimap/domain/schedule.dart';

import 'support/dataset_fixture.dart';

void main() {
  test('fixture loading requires explicit permission and cannot masquerade as verified', () {
    expect(
      () => MunicipalDataset.decode(jsonEncode(fixtureJson())),
      throwsFormatException,
    );
    expect(
      () => fixtureDataset((json) {
        json['kind'] = 'verified';
      }),
      throwsFormatException,
    );
    expect(fixtureDataset().kind, DatasetKind.fixture);
  });
  test('unsupported schema and unknown fields fail without guessing', () {
    expect(
      () => fixtureDataset((json) {
        json['schemaVersion'] = 2;
      }),
      throwsFormatException,
    );
    expect(
      () => fixtureDataset((json) {
        json['schemaVersion'] = 1.0;
      }),
      throwsFormatException,
    );
    expect(
      () => fixtureDataset((json) {
        json['extraInstruction'] = 'ignored';
      }),
      throwsFormatException,
    );
  });
  test(
    'dangling rule/facility/item/source references reject the whole candidate',
    () {
      for (final change in [
        (Map<String, dynamic> json) {
          json['baselines'][0]['areaId'] = 'missing';
        },
        (Map<String, dynamic> json) {
          json['baselines'][0]['categoryId'] = 'missing';
        },
        (Map<String, dynamic> json) {
          json['baselines'][0]['sourceIds'] = ['missing'];
        },
        (Map<String, dynamic> json) {
          json['services'][0]['facilityId'] = 'missing';
        },
        (Map<String, dynamic> json) {
          json['acceptanceRules'][0]['itemId'] = 'missing';
        },
      ]) {
        expect(() => fixtureDataset(change), throwsFormatException);
      }
    },
  );
  test('duplicate IDs and overlapping baseline periods are invalid', () {
    expect(
      () => fixtureDataset((json) {
        json['areas'].add(json['areas'][0]);
      }),
      throwsFormatException,
    );
    expect(
      () => fixtureDataset((json) {
        final duplicate = Map<String, dynamic>.from(json['baselines'][0]);
        duplicate['id'] = 'overlap';
        json['baselines'].add(duplicate);
      }),
      throwsFormatException,
    );
  });
  test(
    'adjacent non-overlapping baselines change precisely at the boundary',
    () {
      final data = fixtureDataset((json) {
        json['baselines'][0]['validPeriod'] = {
          'start': '2026-01-01',
          'end': '2026-10-05',
        };
        json['baselines'].add({
          'id': 'new-burnable',
          'areaId': 'a',
          'categoryId': 'burnable',
          'validPeriod': {'start': '2026-10-05', 'end': '2027-02-01'},
          'sourceIds': ['schedule'],
          'recurrences': [
            {
              'weekdays': [2, 5],
              'monthOccurrences': [],
              'deadline': '07:30',
            },
          ],
        });
      });
      final value = ScheduleCalendar(dataset: data, areaId: 'a');
      expect(value.on(DateTime(2026, 10, 5)).status, ScheduleStatus.none);
      expect(
        value.on(DateTime(2026, 10, 6)).collections.single.deadline.toString(),
        '07:30',
      );
    },
  );
  test(
    'invalid dates, weekday ordinals, deadlines and periods are rejected',
    () {
      for (final change in [
        (Map<String, dynamic> json) {
          json['validPeriod']['end'] = '2027-02-30';
        },
        (Map<String, dynamic> json) {
          json['baselines'][0]['recurrences'][0]['weekdays'] = [0];
        },
        (Map<String, dynamic> json) {
          json['baselines'][0]['recurrences'][0]['monthOccurrences'] = [6];
        },
        (Map<String, dynamic> json) {
          json['baselines'][0]['recurrences'][0]['deadline'] = '24:00';
        },
        (Map<String, dynamic> json) {
          json['validPeriod'] = {'start': '2027-02-01', 'end': '2026-01-01'};
        },
      ]) {
        expect(() => fixtureDataset(change), throwsFormatException);
      }
    },
  );
  test('conflicting changes to one category/date cannot silently win by array order', () {
    expect(
      () => fixtureDataset((json) {
        for (final action in ['cancel', 'add']) {
          json['exceptions'].add({
            'id': action,
            'areaId': 'a',
            'categoryId': 'burnable',
            'date': '2026-10-05',
            'action': action,
            if (action == 'add') 'deadline': '08:00',
            'sourceIds': ['schedule'],
          });
        }
      }),
      throwsFormatException,
    );
  });
  test(
    'moves require explicit different target, deadline and covered year',
    () {
      for (final change in [
        (Map<String, dynamic> json) {
          json['exceptions'][2].remove('targetDate');
        },
        (Map<String, dynamic> json) {
          json['exceptions'][2]['targetDate'] = '2026-12-31';
        },
        (Map<String, dynamic> json) {
          json['exceptions'][2].remove('deadline');
        },
        (Map<String, dynamic> json) {
          json['exceptions'][2]['targetDate'] = '2028-01-02';
        },
      ]) {
        expect(() => fixtureDataset(change), throwsFormatException);
      }
    },
  );
  test(
    'coordinates and typed condition values are validated, not inferred',
    () {
      expect(
        () => fixtureDataset((json) {
          json['facilities'][0]['coordinates']['latitude'] = 100;
        }),
        throwsFormatException,
      );
      expect(
        () => fixtureDataset((json) {
          json['areas'][0]['addressSelectors'][0][0]['values'] = ['架空町', true];
        }),
        throwsFormatException,
      );
      expect(
        () => fixtureDataset((json) {
          json['areas'][0]['addressSelectors'] = [[]];
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'source review/publication time and credential-bearing URLs are invalid',
    () {
      expect(
        () => fixtureDataset((json) {
          json['sources'][0]['url'] = 'https://user:secret@example.com/data';
        }),
        throwsFormatException,
      );
      expect(
        () => fixtureDataset((json) {
          json['sources'][0]['reviewedAt'] = '2026-10-07T12:00:00Z';
        }),
        throwsFormatException,
      );
    },
  );
  test('a second municipality changes data without adding city logic', () {
    final first = fixtureDataset();
    final second = fixtureDataset((json) {
      json['municipality']['id'] = 'demo-second';
      json['municipality']['name'] = '架空第二市';
      json['version'] = 'second-v1';
      json['baselines'][0]['recurrences'][0]['weekdays'] = [2];
    });
    expect(
      ScheduleCalendar(
        dataset: first,
        areaId: 'a',
      ).on(DateTime(2026, 10, 5)).labels,
      ['burnable'],
    );
    final next = ScheduleCalendar(
      dataset: second,
      areaId: 'a',
    ).on(DateTime(2026, 10, 5));
    expect(next.status, ScheduleStatus.none);
    expect(next.municipalityId, 'demo-second');
    expect(next.datasetVersion, 'second-v1');
  });
  test(
    'immutable snapshots protect nested references and canonical periods',
    () {
      final data = fixtureDataset();
      expect(() => data.areas.clear(), throwsUnsupportedError);
      expect(
        () => data.areas['a']!.selectors.first.clear(),
        throwsUnsupportedError,
      );
      expect(() => data.sources.clear(), throwsUnsupportedError);
      expect(data.period.contains(CalendarDate.parse('2027-02-01')), isFalse);
    },
  );
}
