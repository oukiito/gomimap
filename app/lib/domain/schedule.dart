// SPDX-License-Identifier: GPL-3.0-or-later

/// Evaluate municipality-local calendar dates, not UTC timestamps.
DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

enum ScheduleStatus { collection, none, needsConfirmation }

class CollectionRule {
  const CollectionRule(this.label, this.weekdays, {this.monthWeeks = const {}});
  final String label;
  final Set<int> weekdays;
  final Set<int> monthWeeks;
  bool matches(DateTime date) =>
      weekdays.contains(date.weekday) &&
      (monthWeeks.isEmpty || monthWeeks.contains((date.day - 1) ~/ 7 + 1));
}

class DaySchedule {
  const DaySchedule(this.date, this.status, this.labels);
  final DateTime date;
  final ScheduleStatus status;
  final List<String> labels;
}

class ScheduleCalendar {
  ScheduleCalendar({
    required this.validFrom,
    required this.validUntil,
    required this.rules,
    this.exceptions = const {},
    this.uncertainDates = const {},
  });
  final DateTime validFrom;
  final DateTime validUntil;
  final List<CollectionRule> rules;

  /// Reviewed replacement; an empty list explicitly means no collection.
  final Map<DateTime, List<String>> exceptions;
  final Set<DateTime> uncertainDates;
  DaySchedule on(DateTime value) {
    final date = calendarDate(value);
    if (date.isBefore(calendarDate(validFrom)) ||
        date.isAfter(calendarDate(validUntil)) ||
        uncertainDates.contains(date)) {
      return DaySchedule(date, ScheduleStatus.needsConfirmation, const []);
    }
    final labels =
        exceptions[date] ??
        rules
            .where((rule) => rule.matches(date))
            .map((rule) => rule.label)
            .toSet()
            .toList();
    return DaySchedule(
      date,
      labels.isEmpty ? ScheduleStatus.none : ScheduleStatus.collection,
      List.unmodifiable(labels),
    );
  }
}
