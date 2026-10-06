// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/dataset_snapshot.dart';
import 'package:gomimap/domain/schedule.dart';

import 'support/dataset_fixture.dart';

void main() {
  DatasetSnapshot store() =>
      DatasetSnapshot(municipalityId: 'demo-toshima', allowFixtures: true);
  test('invalid, wrong-municipality and wrong-version updates retain the same usable snapshot', () {
    final snapshot = store();
    expect(
      snapshot.tryApply(
        jsonEncode(fixtureJson()),
        expectedVersion: 'toshima-demo-v1',
      ),
      isTrue,
    );
    final previous = snapshot.current;
    final badReference = fixtureJson()..['version'] = 'v2';
    badReference['baselines'][0]['sourceIds'] = ['missing'];
    final wrongCity = fixtureJson()..['version'] = 'v2';
    wrongCity['municipality']['id'] = 'another-city';
    for (final content in [
      'not-json',
      jsonEncode(badReference),
      jsonEncode(wrongCity),
      jsonEncode(fixtureJson()),
    ]) {
      expect(snapshot.tryApply(content, expectedVersion: 'v2'), isFalse);
      expect(identical(snapshot.current, previous), isTrue);
      expect(
        ScheduleCalendar(
          dataset: snapshot.current,
          areaId: 'a',
        ).on(DateTime(2026, 10, 5)).labels,
        ['burnable'],
      );
    }
  });
  test('fully validated new revision replaces one snapshot; a version is immutable', () {
    final snapshot = store();
    final first = jsonEncode(fixtureJson());
    expect(
      snapshot.tryApply(first, expectedVersion: 'toshima-demo-v1'),
      isTrue,
    );
    final current = snapshot.current;
    expect(
      snapshot.tryApply(first, expectedVersion: 'toshima-demo-v1'),
      isTrue,
    );
    expect(identical(snapshot.current, current), isTrue);
    final changed = fixtureJson();
    changed['baselines'][0]['recurrences'][0]['weekdays'] = [2];
    expect(
      snapshot.tryApply(
        jsonEncode(changed),
        expectedVersion: 'toshima-demo-v1',
      ),
      isFalse,
    );
    changed['version'] = 'v2';
    changed['publishedAt'] = '2026-10-07T12:20:00Z';
    expect(
      snapshot.tryApply(jsonEncode(changed), expectedVersion: 'v2'),
      isTrue,
    );
    expect(snapshot.current!.version, 'v2');
    expect(
      ScheduleCalendar(
        dataset: snapshot.current,
        areaId: 'a',
      ).on(DateTime(2026, 10, 5)).status,
      ScheduleStatus.none,
    );
    expect(
      snapshot.tryApply(first, expectedVersion: 'toshima-demo-v1'),
      isFalse,
    );
    expect(snapshot.current!.version, 'v2');
  });
  test('production snapshot rejects fixture data by default', () {
    final snapshot = DatasetSnapshot(municipalityId: 'demo-toshima');
    expect(
      snapshot.tryApply(
        jsonEncode(fixtureJson()),
        expectedVersion: 'toshima-demo-v1',
      ),
      isFalse,
    );
    expect(snapshot.current, isNull);
  });
}
