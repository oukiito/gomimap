// SPDX-License-Identifier: GPL-3.0-or-later
import 'conditions.dart';

bool _validId(String value) =>
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$').hasMatch(value);

/// Meaning IDs only. A caller must validate their source, scope, period and
/// catalogue references before evaluating rules; this is not a JSON loader.
class SortingOutcome {
  SortingOutcome({
    this.categoryId,
    this.routeId,
    Iterable<String> preparationIds = const [],
  }) : preparationIds = List.unmodifiable(preparationIds) {
    if (categoryId == null && routeId == null ||
        categoryId != null && !_validId(categoryId!) ||
        routeId != null && !_validId(routeId!) ||
        this.preparationIds.any((id) => !_validId(id)) ||
        this.preparationIds.toSet().length != this.preparationIds.length) {
      throw const FormatException('Invalid sorting outcome');
    }
  }
  final String? categoryId, routeId;
  final List<String> preparationIds;
  bool sameAs(SortingOutcome other) {
    if (categoryId != other.categoryId ||
        routeId != other.routeId ||
        preparationIds.length != other.preparationIds.length) {
      return false;
    }
    for (var i = 0; i < preparationIds.length; i++) {
      if (preparationIds[i] != other.preparationIds[i]) return false;
    }
    return true;
  }
}

/// rejected rules do not match; unknown with no missing fields means that
/// answering questions cannot establish the rule (for example stale evidence).
class EvaluatedSortingRule {
  EvaluatedSortingRule({
    required this.id,
    required this.priority,
    required this.outcome,
    required this.condition,
  }) {
    if (!_validId(id) ||
        priority < 0 ||
        priority > 65535 ||
        condition.missingFields.any((field) => !_validId(field)) ||
        condition.status != ConditionStatus.unknown &&
            condition.missingFields.isNotEmpty) {
      throw const FormatException('Invalid evaluated sorting rule');
    }
  }
  final String id;
  final int priority;
  final SortingOutcome outcome;
  final ConditionResult condition;
}

enum SortingDecisionStatus { classified, needsInput, needsConfirmation }

enum SortingConfirmationReason {
  noMatchingRule,
  evidenceUnknown,
  conflictingRules,
}

class SortingDecision {
  SortingDecision._(
    this.status, {
    this.outcome,
    this.reason,
    Iterable<String> ruleIds = const [],
    Iterable<String> questionIds = const [],
  }) : ruleIds = List.unmodifiable(ruleIds),
       questionIds = List.unmodifiable(questionIds);
  final SortingDecisionStatus status;
  final SortingOutcome? outcome;
  final SortingConfirmationReason? reason;
  final List<String> ruleIds, questionIds;
}

/// D2: higher priorities override only once they can be proven. The input is
/// already scoped to one municipality/release/item/area/date by the caller.
SortingDecision decideSorting(Iterable<EvaluatedSortingRule> input) {
  final rules = input.toList();
  if (rules.map((r) => r.id).toSet().length != rules.length) {
    throw const FormatException('Duplicate rule identity');
  }
  rules.sort((a, b) {
    final priority = b.priority.compareTo(a.priority);
    return priority != 0 ? priority : a.id.compareTo(b.id);
  });
  final accepted = rules
      .where((r) => r.condition.status == ConditionStatus.accepted)
      .toList();
  final winningPriority = accepted.firstOrNull?.priority;
  final unknown = rules
      .where(
        (r) =>
            r.condition.status == ConditionStatus.unknown &&
            (winningPriority == null || r.priority >= winningPriority),
      )
      .toList();
  if (unknown.isNotEmpty) {
    final highest = unknown
        .where((r) => r.priority == unknown.first.priority)
        .toList();
    // Ask only the highest unresolved group. A proven higher exception can
    // make lower uncertain rules irrelevant; otherwise reevaluate afterward.
    final evidenceUnknown = highest
        .where((r) => r.condition.missingFields.isEmpty)
        .toList();
    if (evidenceUnknown.isNotEmpty) {
      return SortingDecision._(
        SortingDecisionStatus.needsConfirmation,
        reason: SortingConfirmationReason.evidenceUnknown,
        ruleIds: evidenceUnknown.map((r) => r.id),
      );
    }
    final questions =
        highest.expand((r) => r.condition.missingFields).toSet().toList()
          ..sort();
    return SortingDecision._(
      SortingDecisionStatus.needsInput,
      ruleIds: highest.map((r) => r.id),
      questionIds: questions,
    );
  }
  if (accepted.isEmpty) {
    return SortingDecision._(
      SortingDecisionStatus.needsConfirmation,
      reason: SortingConfirmationReason.noMatchingRule,
    );
  }
  final winners = accepted.where((r) => r.priority == winningPriority).toList();
  final outcome = winners.first.outcome;
  if (winners.any((r) => !r.outcome.sameAs(outcome))) {
    return SortingDecision._(
      SortingDecisionStatus.needsConfirmation,
      reason: SortingConfirmationReason.conflictingRules,
      ruleIds: winners.map((r) => r.id),
    );
  }
  return SortingDecision._(
    SortingDecisionStatus.classified,
    outcome: outcome,
    ruleIds: winners.map((r) => r.id),
  );
}
