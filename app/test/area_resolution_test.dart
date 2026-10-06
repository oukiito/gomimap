// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/area_resolution.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/conditions.dart';

import 'support/dataset_fixture.dart';

void main() {
  final date = CalendarDate.parse('2026-10-05');
  const address = {
    'address.town': '架空町',
    'address.chome': 1,
    'address.block': 10,
    'address.streetSide': 'away',
  };
  test(
    'town/chome/block/street side select a candidate within its municipality',
    () {
      final result = resolveArea(fixtureDataset(), date, address);
      expect(result.status, AreaResolutionStatus.matched);
      expect(result.matchedAreaId, 'a');
      expect(result.municipalityId, 'demo-toshima');
      expect(
        resolveArea(fixtureDataset(), date, {
          ...address,
          'address.streetSide': 'along',
        }).matchedAreaId,
        'b',
      );
    },
  );
  test(
    'same block on a street boundary requires an answer, never first area',
    () {
      final facts = Map<String, Object?>.from(address)
        ..remove('address.streetSide');
      final result = resolveArea(fixtureDataset(), date, facts);
      expect(result.status, AreaResolutionStatus.needsInformation);
      expect(result.candidates.length, 2);
      expect(result.missingFields, {'address.streetSide'});
      expect(result.matchedAreaId, isNull);
    },
  );
  test('range endpoints are included and unmatched address has no nearest fallback', () {
    for (final block in [1, 20]) {
      expect(
        resolveArea(fixtureDataset(), date, {
          ...address,
          'address.block': block,
        }).matchedAreaId,
        'a',
      );
    }
    expect(
      resolveArea(fixtureDataset(), date, {
        ...address,
        'address.block': 21,
      }).status,
      AreaResolutionStatus.unsupported,
    );
    expect(
      resolveArea(fixtureDataset(), date, {'address.town': '別の町'}).candidates,
      isEmpty,
    );
  });
  test('wrong types, empty answers and non-finite numbers stay unknown', () {
    for (final facts in [
      {...address, 'address.chome': '1'},
      {...address, 'address.block': double.nan},
      {...address, 'address.streetSide': ' '},
      <String, Object?>{},
    ]) {
      final result = resolveArea(fixtureDataset(), date, facts);
      expect(result.status, AreaResolutionStatus.needsInformation);
      expect(result.matchedAreaId, isNull);
    }
  });
  test('overlapping confirmed selectors return ambiguity instead of array-order selection', () {
    final data = fixtureDataset((json) {
      json['areas'][1]['addressSelectors'] =
          json['areas'][0]['addressSelectors'];
    });
    expect(
      resolveArea(data, date, address).status,
      AreaResolutionStatus.ambiguous,
    );
    expect(resolveArea(data, date, address).matchedAreaId, isNull);
  });
  test('expired coverage/unreviewed criteria cannot become unsupported or confirmed', () {
    expect(
      resolveArea(
        fixtureDataset(),
        CalendarDate.parse('2027-02-01'),
        address,
      ).status,
      AreaResolutionStatus.needsConfirmation,
    );
    final data = fixtureDataset((json) {
      json['sources'][0]['review'] = 'pending';
    });
    expect(
      resolveArea(data, date, address).status,
      AreaResolutionStatus.needsConfirmation,
    );
    expect(
      resolveArea(data, date, {'address.town': '別の町'}).status,
      AreaResolutionStatus.needsConfirmation,
    );
  });
  test('OR address groups and typed oneOf preserve three-valued logic', () {
    final data = fixtureDataset((json) {
      json['areas'][0]['addressSelectors'].add([
        {
          'field': 'address.town',
          'operator': 'oneOf',
          'values': ['追加の架空町', '他の架空町'],
          'question': '町名は？',
        },
      ]);
    });
    expect(
      resolveArea(data, date, {'address.town': '追加の架空町'}).matchedAreaId,
      'a',
    );
    final group = data.areas['a']!.selectors.last;
    expect(allConditions(group, {}).status, ConditionStatus.unknown);
  });
}
