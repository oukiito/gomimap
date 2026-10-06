// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/conditions.dart';
import 'package:gomimap/domain/service_matching.dart';

import 'support/dataset_fixture.dart';

void main() {
  final date = CalendarDate.parse('2026-10-05');
  test('only public special-item services can be recommended, never household collection points', () {
    final matches = matchServices(fixtureDataset(), 'dryBattery', date, {});
    expect(matches.map((value) => value.service.id), [
      'a-battery',
      'b-battery',
    ]);
    expect(matches.every((value) => value.canRecommend), isTrue);
    expect(matchServices(fixtureDataset(), 'pet', date, {}), isEmpty);
    expect(matchServices(fixtureDataset(), 'unknown', date, {}), isEmpty);
  });
  test('appliance dimensions and battery condition all need confirmation', () {
    final data = fixtureDataset();
    var result = matchServices(data, 'appliance', date, {}).single;
    expect(result.acceptance.status, ConditionStatus.unknown);
    expect(result.acceptance.missingFields, {
      'item.widthMm',
      'item.heightMm',
      'item.batteryRemoved',
    });
    result = matchServices(data, 'appliance', date, {
      'item.widthMm': 300,
      'item.heightMm': 150,
      'item.batteryRemoved': true,
    }).single;
    expect(result.canRecommend, isTrue);
    expect(
      matchServices(data, 'appliance', date, {
        'item.widthMm': 301,
      }).single.acceptance.status,
      ConditionStatus.rejected,
    );
  });
  test('damaged or unknown batteries cannot be accepted by a condition for undamaged batteries', () {
    final data = fixtureDataset((json) {
      json['services'][4]['state'] = 'active';
    });
    expect(
      matchServices(data, 'rechargeable', date, {}).single.canRecommend,
      isFalse,
    );
    expect(
      matchServices(data, 'rechargeable', date, {
        'item.damaged': true,
      }).single.acceptance.status,
      ConditionStatus.rejected,
    );
    expect(
      matchServices(data, 'rechargeable', date, {
        'item.damaged': false,
      }).single.canRecommend,
      isTrue,
    );
  });
  test('paused service does not automatically reactivate or recommend after time passes', () {
    final result = matchServices(
      fixtureDataset(),
      'rechargeable',
      CalendarDate.parse('2027-01-20'),
      {'item.damaged': false},
    ).single;
    expect(result.acceptance.status, ConditionStatus.accepted);
    expect(result.blocks, contains(ServiceBlock.paused));
    expect(result.canRecommend, isFalse);
  });
  test(
    'unknown hours, location evidence or service status prevent recommendation',
    () {
      for (final change in [
        (Map<String, dynamic> json) {
          json['services'][0]['hours'] = [];
        },
        (Map<String, dynamic> json) {
          json['facilities'][0].remove('coordinates');
        },
        (Map<String, dynamic> json) {
          json['sources'][2]['review'] = 'pending';
        },
        (Map<String, dynamic> json) {
          json['services'][0]['state'] = 'unconfirmed';
        },
      ]) {
        final results = matchServices(
          fixtureDataset(change),
          'dryBattery',
          date,
          {},
        );
        expect(results.first.canRecommend, isFalse);
      }
    },
  );
  test(
    'expired acceptance does not borrow another service in the same facility',
    () {
      final data = fixtureDataset((json) {
        json['acceptanceRules'][0]['validPeriod']['end'] = '2026-10-05';
      });
      final matches = matchServices(data, 'dryBattery', date, {});
      expect(matches.first.acceptance.status, ConditionStatus.unknown);
      expect(matches.first.canRecommend, isFalse);
      expect(matches.last.canRecommend, isTrue);
    },
  );
  test('service opening windows use Japan local time, with exclusive close and pause priority', () {
    final data = fixtureDataset();
    final service = data.services['a-battery']!;
    expect(
      openingAt(data, service, DateTime.parse('2026-10-04T23:59:00Z')),
      OpeningStatus.closed,
    );
    expect(
      openingAt(data, service, DateTime.parse('2026-10-05T00:00:00Z')),
      OpeningStatus.open,
    );
    expect(
      openingAt(data, service, DateTime.parse('2026-10-05T08:00:00Z')),
      OpeningStatus.closed,
    );
    expect(
      openingAt(
        data,
        data.services['b-rechargeable']!,
        DateTime.parse('2026-10-05T00:00:00Z'),
      ),
      OpeningStatus.closed,
    );
  });
  test('requesting a closed day preserves a place for a later visit but exposes hours separately', () {
    final data = fixtureDataset();
    final sunday = CalendarDate.parse('2026-10-04');
    expect(
      matchServices(data, 'dryBattery', sunday, {}).first.canRecommend,
      isTrue,
    );
    expect(
      openingAt(
        data,
        data.services['a-battery']!,
        DateTime.parse('2026-10-04T01:00:00Z'),
      ),
      OpeningStatus.closed,
    );
  });
}
