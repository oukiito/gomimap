// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/conditions.dart';
import 'package:gomimap/domain/sorting_decision.dart';

EvaluatedSortingRule rule(
  String id,
  int priority,
  String category, {
  ConditionStatus status = ConditionStatus.accepted,
  List<String> missing = const [],
}) => EvaluatedSortingRule(
  id: id,
  priority: priority,
  outcome: SortingOutcome(categoryId: category),
  condition: ConditionResult(status, missing),
);

void main() {
  for (final size in [299, 300, 301]) {
    test('fictional threshold $size mm is evaluated before selection', () {
      // This 300mm threshold is owned test data, not Toshima guidance.
      final small = DataCondition(
        field: 'maxEdgeMm',
        question: 'size',
        operator: ConditionOperator.range,
        minimum: 0,
        maximum: 299,
      );
      final large = DataCondition(
        field: 'maxEdgeMm',
        question: 'size',
        operator: ConditionOperator.range,
        minimum: 300,
        maximum: 100000,
      );
      final result = decideSorting([
        EvaluatedSortingRule(
          id: 'small',
          priority: 0,
          outcome: SortingOutcome(categoryId: 'ordinary'),
          condition: small.evaluate({'maxEdgeMm': size}),
        ),
        EvaluatedSortingRule(
          id: 'large',
          priority: 0,
          outcome: SortingOutcome(categoryId: 'bulky'),
          condition: large.evaluate({'maxEdgeMm': size}),
        ),
      ]);
      expect(result.status, SortingDecisionStatus.classified);
      expect(result.outcome!.categoryId, size < 300 ? 'ordinary' : 'bulky');
    });
  }
  test(
    'unknown priority excludes lower fallback and asks only highest questions',
    () {
      final result = decideSorting([
        rule('fallback', 0, 'bulky'),
        rule(
          'recycle',
          20,
          'special',
          status: ConditionStatus.unknown,
          missing: ['battery'],
        ),
        rule(
          'size',
          10,
          'ordinary',
          status: ConditionStatus.unknown,
          missing: ['maxEdgeMm'],
        ),
      ]);
      expect(result.status, SortingDecisionStatus.needsInput);
      expect(result.outcome, isNull);
      expect(result.questionIds, ['battery']);
    },
  );
  test('same-priority unknown is not overridden by an accepted result', () {
    final result = decideSorting([
      rule('a', 10, 'ordinary'),
      rule(
        'b',
        10,
        'bulky',
        status: ConditionStatus.unknown,
        missing: ['size'],
      ),
    ]);
    expect(result.status, SortingDecisionStatus.needsInput);
    expect(result.questionIds, ['size']);
  });
  test('answering highest condition can expose next question or classify the exception', () {
    final lower = rule(
      'lower',
      10,
      'ordinary',
      status: ConditionStatus.unknown,
      missing: ['size'],
    );
    var result = decideSorting([
      rule('high', 20, 'special', status: ConditionStatus.rejected),
      lower,
    ]);
    expect(result.questionIds, ['size']);
    result = decideSorting([rule('high', 20, 'special'), lower]);
    expect(result.status, SortingDecisionStatus.classified);
    expect(result.outcome!.categoryId, 'special');
  });
  test(
    'competing evidence uncertainty cannot be answered away or become ordinary',
    () {
      final result = decideSorting([
        rule('low', 0, 'ordinary'),
        rule(
          'unknown-evidence',
          20,
          'special',
          status: ConditionStatus.unknown,
        ),
        rule(
          'question',
          20,
          'bulky',
          status: ConditionStatus.unknown,
          missing: ['size'],
        ),
      ]);
      expect(result.reason, SortingConfirmationReason.evidenceUnknown);
      expect(result.questionIds, isEmpty);
      expect(result.outcome, isNull);
    },
  );
  test('a higher answer may resolve a lower evidence uncertainty', () {
    final low = rule('low', 10, 'ordinary', status: ConditionStatus.unknown);
    var result = decideSorting([
      low,
      rule(
        'high',
        20,
        'special',
        status: ConditionStatus.unknown,
        missing: ['battery'],
      ),
    ]);
    expect(result.questionIds, ['battery']);
    result = decideSorting([low, rule('high', 20, 'special')]);
    expect(result.status, SortingDecisionStatus.classified);
    result = decideSorting([
      low,
      rule('high', 20, 'special', status: ConditionStatus.rejected),
    ]);
    expect(result.reason, SortingConfirmationReason.evidenceUnknown);
  });
  test('a missing or non-finite measurement never establishes a category', () {
    final condition = DataCondition(
      field: 'maxEdgeMm',
      question: 'size',
      operator: ConditionOperator.range,
      minimum: 0,
      maximum: 100000,
    );
    for (final value in [null, double.nan, double.infinity, '300']) {
      final result = decideSorting([
        EvaluatedSortingRule(
          id: 'size',
          priority: 0,
          outcome: SortingOutcome(categoryId: 'bulky'),
          condition: condition.evaluate({'maxEdgeMm': value}),
        ),
      ]);
      expect(result.status, SortingDecisionStatus.needsInput);
      expect(result.outcome, isNull);
    }
  });
  test('lower unknown does not invalidate an established higher exception', () {
    final result = decideSorting([
      rule('low', 0, 'ordinary', status: ConditionStatus.unknown),
      rule('high', 1, 'special'),
    ]);
    expect(result.status, SortingDecisionStatus.classified);
  });
  test('equal conflicting results are held regardless of input order', () {
    for (final input in [
      [rule('a', 2, 'ordinary'), rule('b', 2, 'bulky')],
      [rule('b', 2, 'bulky'), rule('a', 2, 'ordinary')],
    ]) {
      final result = decideSorting(input);
      expect(result.reason, SortingConfirmationReason.conflictingRules);
      expect(result.ruleIds, ['a', 'b']);
      expect(result.outcome, isNull);
    }
  });
  test('equal consistent results preserve all evidence identities', () {
    final result = decideSorting([
      rule('b', 2, 'ordinary'),
      rule('a', 2, 'ordinary'),
    ]);
    expect(result.status, SortingDecisionStatus.classified);
    expect(result.ruleIds, ['a', 'b']);
  });
  test('different route or preparation order is a conflicting result', () {
    for (final other in [
      SortingOutcome(
        categoryId: 'bulky',
        routeId: 'other',
        preparationIds: ['a', 'b'],
      ),
      SortingOutcome(
        categoryId: 'bulky',
        routeId: 'booking',
        preparationIds: ['b', 'a'],
      ),
    ]) {
      final result = decideSorting([
        EvaluatedSortingRule(
          id: 'first',
          priority: 1,
          outcome: SortingOutcome(
            categoryId: 'bulky',
            routeId: 'booking',
            preparationIds: ['a', 'b'],
          ),
          condition: ConditionResult(ConditionStatus.accepted),
        ),
        EvaluatedSortingRule(
          id: 'second',
          priority: 1,
          outcome: other,
          condition: ConditionResult(ConditionStatus.accepted),
        ),
      ]);
      expect(result.reason, SortingConfirmationReason.conflictingRules);
    }
  });
  test('empty or all rejected has no invented category', () {
    for (final input in [
      <EvaluatedSortingRule>[],
      [rule('r', 0, 'ordinary', status: ConditionStatus.rejected)],
    ]) {
      expect(
        decideSorting(input).reason,
        SortingConfirmationReason.noMatchingRule,
      );
    }
  });
  test('question order and deduplication do not depend on input iteration', () {
    final a = rule(
      'a',
      2,
      'ordinary',
      status: ConditionStatus.unknown,
      missing: ['z', 'a'],
    );
    final b = rule(
      'b',
      2,
      'bulky',
      status: ConditionStatus.unknown,
      missing: ['a'],
    );
    expect(decideSorting([b, a]).questionIds, ['a', 'z']);
    expect(decideSorting([a, b]).questionIds, ['a', 'z']);
  });
  test('rejects malformed outcome, duplicate identity, and impossible condition state', () {
    expect(() => SortingOutcome(), throwsFormatException);
    expect(
      () => SortingOutcome(routeId: 'arbitrary/url'),
      throwsFormatException,
    );
    expect(
      () => SortingOutcome(
        categoryId: 'ordinary',
        preparationIds: ['same', 'same'],
      ),
      throwsFormatException,
    );
    expect(() => rule('bad', -1, 'ordinary'), throwsFormatException);
    expect(() => rule('bad', 65536, 'ordinary'), throwsFormatException);
    expect(
      () => rule('a', 0, 'ordinary', missing: ['missing']),
      throwsFormatException,
    );
    expect(
      () => decideSorting([rule('a', 1, 'ordinary'), rule('a', 2, 'bulky')]),
      throwsFormatException,
    );
  });
}
