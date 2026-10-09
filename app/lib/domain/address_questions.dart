// SPDX-License-Identifier: GPL-3.0-or-later
import 'calendar_date.dart';
import 'conditions.dart';
import 'municipal_dataset.dart';

class AddressQuestion {
  const AddressQuestion(this.field, this.prompt, this.choices, this.number);
  final String field, prompt;
  final List<Object> choices;
  final bool number;
}

/// Explicit source options only. Never derives districts from coordinates.
List<AddressQuestion> addressQuestions(
  MunicipalDataset data,
  CalendarDate date,
) {
  if (!data.period.contains(date)) return const [];
  final fields = <String, List<DataCondition>>{};
  for (final area in data.areas.values) {
    if (!area.period.contains(date) ||
        !data.evidenceSupports(area.sourceIds, date)) {
      continue;
    }
    for (final group in area.selectors) {
      for (final condition in group) {
        if (!condition.field.startsWith('address.')) continue;
        fields.putIfAbsent(condition.field, () => []).add(condition);
      }
    }
  }
  const order = [
    'address.town',
    'address.chome',
    'address.block',
    'address.streetSide',
  ];
  final keys = fields.keys.toList()
    ..sort((a, b) {
      final ai = order.indexOf(a), bi = order.indexOf(b);
      if (ai < 0 && bi < 0) return a.compareTo(b);
      return (ai < 0 ? order.length : ai).compareTo(bi < 0 ? order.length : bi);
    });
  return [
    for (final key in keys)
      AddressQuestion(
        key,
        fields[key]!.first.question,
        fields[key]!.expand((c) => c.values).toSet().toList(),
        fields[key]!.any((c) => c.operator == ConditionOperator.range),
      ),
  ];
}

/// A changed higher-level field invalidates all dependent answers.
Map<String, Object?> changeAddressAnswer(
  List<AddressQuestion> questions,
  Map<String, Object?> current,
  String field,
  Object? value,
) {
  final index = questions.indexWhere((q) => q.field == field);
  if (index < 0) throw ArgumentError('Unknown address field');
  return {
    for (final q in questions.take(index))
      if (current.containsKey(q.field)) q.field: current[q.field],
    field: ?value,
  };
}

int? addressInteger(String value) {
  const digits = ['０１２３４５６７８９', '०१२३४५६७८९', '٠١٢٣٤٥٦٧٨٩'];
  var text = value.trim();
  for (final alphabet in digits) {
    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(alphabet[i], '$i');
    }
  }
  return RegExp(r'^[0-9]{1,6}$').hasMatch(text) ? int.tryParse(text) : null;
}
