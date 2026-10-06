// SPDX-License-Identifier: GPL-3.0-or-later

enum ConditionStatus { accepted, rejected, unknown }

enum ConditionOperator { isValue, oneOf, range }

class ConditionResult {
  ConditionResult(this.status, [Iterable<String> missing = const []])
    : missingFields = Set.unmodifiable(missing);
  final ConditionStatus status;
  final Set<String> missingFields;
}

/// Missing, incorrectly typed, or non-finite answers cannot prove acceptance.
class DataCondition {
  DataCondition({
    required this.field,
    required this.question,
    required this.operator,
    Iterable<Object> values = const [],
    this.minimum,
    this.maximum,
  }) : values = List.unmodifiable(values);
  final String field;
  final String question;
  final ConditionOperator operator;
  final List<Object> values;
  final num? minimum;
  final num? maximum;

  ConditionResult evaluate(Map<String, Object?> facts) {
    final fact = facts[field];
    final expected = values.firstOrNull;
    final correctlyTyped = switch (operator) {
      ConditionOperator.range => fact is num && fact.isFinite,
      _ =>
        expected is String
            ? fact is String && fact.trim().isNotEmpty
            : expected is bool
            ? fact is bool
            : fact is num && fact.isFinite,
    };
    if (fact == null || !correctlyTyped) {
      return ConditionResult(ConditionStatus.unknown, [field]);
    }
    final accepted = switch (operator) {
      ConditionOperator.isValue => fact == expected,
      ConditionOperator.oneOf => values.contains(fact),
      ConditionOperator.range => (fact as num) >= minimum! && fact <= maximum!,
    };
    return ConditionResult(
      accepted ? ConditionStatus.accepted : ConditionStatus.rejected,
    );
  }
}

ConditionResult allConditions(
  Iterable<DataCondition> conditions,
  Map<String, Object?> facts,
) {
  final results = conditions
      .map((condition) => condition.evaluate(facts))
      .toList();
  if (results.any((result) => result.status == ConditionStatus.rejected)) {
    return ConditionResult(ConditionStatus.rejected);
  }
  final missing = results.expand((result) => result.missingFields).toSet();
  return ConditionResult(
    missing.isEmpty ? ConditionStatus.accepted : ConditionStatus.unknown,
    missing,
  );
}

ConditionResult anyConditionGroup(
  Iterable<List<DataCondition>> groups,
  Map<String, Object?> facts,
) {
  final results = groups.map((group) => allConditions(group, facts)).toList();
  if (results.any((result) => result.status == ConditionStatus.accepted)) {
    return ConditionResult(ConditionStatus.accepted);
  }
  final unknown = results
      .where((result) => result.status == ConditionStatus.unknown)
      .toList();
  return unknown.isEmpty
      ? ConditionResult(ConditionStatus.rejected)
      : ConditionResult(
          ConditionStatus.unknown,
          unknown.expand((result) => result.missingFields),
        );
}
