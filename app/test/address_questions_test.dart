// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/address_questions.dart';
import 'package:gomimap/domain/area_resolution.dart';
import 'package:gomimap/domain/calendar_date.dart';

import 'support/dataset_fixture.dart';

void main() {
  test('questions follow explicit selectors and have no default answers', () {
    final data = fixtureDataset();
    final questions = addressQuestions(data, CalendarDate(2026, 10, 5));
    expect(questions.map((q) => q.field), [
      'address.town',
      'address.chome',
      'address.block',
      'address.streetSide',
    ]);
    expect(questions.last.choices.toSet(), {'away', 'along'});
    expect(
      resolveArea(data, CalendarDate(2026, 10, 5), {}).matchedAreaId,
      isNull,
    );
  });
  test('changing a higher field drops every dependent answer', () {
    final questions = addressQuestions(
      fixtureDataset(),
      CalendarDate(2026, 10, 5),
    );
    final facts = {
      'address.town': '架空町',
      'address.chome': 1,
      'address.block': 4,
      'address.streetSide': 'away',
    };
    expect(changeAddressAnswer(questions, facts, 'address.chome', 2), {
      'address.town': '架空町',
      'address.chome': 2,
    });
    expect(
      changeAddressAnswer(questions, facts, 'address.town', null),
      isEmpty,
    );
  });
  test(
    'local digits parse; punctuation, decimals and excessive input do not',
    () {
      for (final text in ['12', '１２', '१२', '١٢']) {
        expect(addressInteger(text), 12);
      }
      for (final text in ['', '1.2', '1-2', '1番', '-1', '1000000', 'NaN']) {
        expect(addressInteger(text), isNull);
      }
    },
  );
  test('expired evidence does not become a usable address form', () {
    expect(
      addressQuestions(fixtureDataset(), CalendarDate(2027, 3, 1)),
      isEmpty,
    );
  });
}
