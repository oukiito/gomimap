// SPDX-License-Identifier: GPL-3.0-or-later

import 'schedule.dart';

/// Select what the resident can prepare for next. Never skip uncertainty or
/// infer that a truck has collected waste from the disposal deadline.
DaySchedule scheduleFocus(List<DaySchedule> days, int minute) {
  assert(days.isNotEmpty && minute >= 0 && minute < 1440);
  final today = days.first;
  if (today.status == ScheduleStatus.needsConfirmation) return today;
  final remaining = today.collections.where(
    (entry) => entry.deadline.hour * 60 + entry.deadline.minute > minute,
  );
  if (today.status == ScheduleStatus.collection && remaining.isNotEmpty) {
    return DaySchedule(
      day: today.day,
      areaId: today.areaId,
      municipalityId: today.municipalityId,
      datasetVersion: today.datasetVersion,
      fixture: today.fixture,
      status: today.status,
      collections: remaining,
      reasons: today.reasons,
      sources: today.sources,
    );
  }
  for (final day in days.skip(1)) {
    if (day.status != ScheduleStatus.none) return day;
  }
  return DaySchedule(
    day: today.day,
    areaId: today.areaId,
    municipalityId: today.municipalityId,
    datasetVersion: today.datasetVersion,
    fixture: today.fixture,
    status: ScheduleStatus.needsConfirmation,
    reasons: [ScheduleReason.outsideCoverage],
  );
}

/// Segment boundaries are shared with the offline widget projection.
List<int> focusBoundaries(DaySchedule today) => ({
  0,
  for (final entry in today.collections)
    entry.deadline.hour * 60 + entry.deadline.minute,
}.toList()..sort());
