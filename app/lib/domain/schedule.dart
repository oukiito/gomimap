// SPDX-License-Identifier: GPL-3.0-or-later

import 'calendar_date.dart';
import 'municipal_dataset.dart';

enum ScheduleStatus { collection, none, needsConfirmation }

enum ScheduleReason {
  dataUnavailable,
  outsideCoverage,
  areaUnavailable,
  missingBaseline,
  evidenceUnconfirmed,
  unknownException,
  conflictingDeadline,
}

class ScheduledCollection {
  ScheduledCollection(this.category, this.deadline, Iterable<String> sourceIds)
    : sourceIds = Set.unmodifiable(sourceIds);
  final WasteCategory category;
  final LocalTime deadline;
  final Set<String> sourceIds;
}

/// The same versioned result for the app, notification planner and widgets.
/// date is UTC midnight representing civil fields, never the notification time.
class DaySchedule {
  DaySchedule({
    required this.day,
    required this.areaId,
    required this.status,
    this.municipalityId,
    this.datasetVersion,
    this.fixture = false,
    Iterable<ScheduledCollection> collections = const [],
    Iterable<ScheduleReason> reasons = const [],
    Map<String, String> sources = const {},
  }) : collections = List.unmodifiable(collections),
       reasons = Set.unmodifiable(reasons),
       sources = Map.unmodifiable(sources);
  final CalendarDate day;
  DateTime get date => day.value;
  final String? municipalityId;
  final String areaId;
  final String? datasetVersion;
  final bool fixture;
  final ScheduleStatus status;
  final List<ScheduledCollection> collections;
  final Set<ScheduleReason> reasons;
  final Map<String, String> sources;
  List<String> get labels =>
      List.unmodifiable(collections.map((value) => value.category.id));
  bool get canNotify =>
      !fixture &&
      status == ScheduleStatus.collection &&
      collections.isNotEmpty &&
      municipalityId != null &&
      datasetVersion != null &&
      reasons.isEmpty &&
      collections.every(
        (entry) =>
            entry.sourceIds.isNotEmpty &&
            entry.sourceIds.every(sources.containsKey),
      );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'date': day.toString(),
    'timezone': 'Asia/Tokyo',
    'municipalityId': municipalityId,
    'areaId': areaId,
    'datasetVersion': datasetVersion,
    'fixture': fixture,
    'status': status.name,
    'collections': collections
        .map(
          (value) => {
            'categoryId': value.category.id,
            'name': value.category.name,
            'displayKey': value.category.displayKey,
            'deadline': value.deadline.toString(),
            'sourceIds': value.sourceIds.toList(),
          },
        )
        .toList(),
    'reasons': reasons.map((value) => value.name).toList(),
    'sources': sources,
  };
}

class ScheduleCalendar {
  const ScheduleCalendar({required this.dataset, required this.areaId});
  final MunicipalDataset? dataset;
  final String areaId;
  DaySchedule on(DateTime dateFields) =>
      onDate(CalendarDate.fromFields(dateFields));
  DaySchedule onInstant(DateTime instant) =>
      onDate(CalendarDate.inJapan(instant));

  DaySchedule onDate(CalendarDate date) {
    final data = dataset;
    final evidence = <String>{};
    DaySchedule result(
      ScheduleStatus status, {
      Iterable<ScheduledCollection> collections = const [],
      Iterable<ScheduleReason> reasons = const [],
    }) => DaySchedule(
      day: date,
      municipalityId: data?.municipality.id,
      areaId: areaId,
      datasetVersion: data?.version,
      fixture: data?.kind == DatasetKind.fixture,
      status: status,
      collections: collections,
      reasons: reasons,
      sources: {
        for (final id in evidence)
          if (data?.sources[id] != null) id: data!.sources[id]!.url,
      },
    );
    DaySchedule unknown(ScheduleReason reason) =>
        result(ScheduleStatus.needsConfirmation, reasons: [reason]);
    if (data == null) return unknown(ScheduleReason.dataUnavailable);
    if (!data.period.contains(date)) {
      return unknown(ScheduleReason.outsideCoverage);
    }
    final area = data.areas[areaId];
    if (area == null || !area.period.contains(date)) {
      return unknown(ScheduleReason.areaUnavailable);
    }
    evidence.addAll(area.sourceIds);
    if (!data.evidenceSupports(area.sourceIds, date)) {
      return unknown(ScheduleReason.evidenceUnconfirmed);
    }
    final entries = <String, ScheduledCollection>{};
    for (final category in data.categories.values.where(
      (value) => value.scheduled,
    )) {
      final baseline = data.baselines
          .where(
            (value) =>
                value.areaId == areaId &&
                value.categoryId == category.id &&
                value.period.contains(date),
          )
          .firstOrNull;
      if (baseline == null) return unknown(ScheduleReason.missingBaseline);
      evidence.addAll(baseline.sourceIds);
      if (!data.evidenceSupports(baseline.sourceIds, date)) {
        return unknown(ScheduleReason.evidenceUnconfirmed);
      }
      final matches = baseline.recurrences
          .where((value) => value.matches(date))
          .toList();
      if (matches.isEmpty) continue;
      if (matches.any((value) => value.deadline != matches.first.deadline)) {
        return unknown(ScheduleReason.conflictingDeadline);
      }
      entries[category.id] = ScheduledCollection(
        category,
        matches.first.deadline,
        baseline.sourceIds,
      );
    }
    final exceptions = data.exceptions
        .where((value) => value.areaId == areaId && value.affects(date))
        .toList();
    // Explicit uncertainty wins even when a reviewed cancellation is present.
    for (final exception in exceptions) {
      evidence.addAll(exception.sourceIds);
      if (!data.evidenceSupports(exception.sourceIds, exception.date) ||
          (exception.targetDate != null &&
              !data.evidenceSupports(
                exception.sourceIds,
                exception.targetDate!,
              ))) {
        return unknown(ScheduleReason.evidenceUnconfirmed);
      }
      if (exception.action == ExceptionAction.needsConfirmation) {
        return unknown(ScheduleReason.unknownException);
      }
    }
    for (final exception in exceptions) {
      switch (exception.action) {
        case ExceptionAction.cancel:
          entries.remove(exception.categoryId);
        case ExceptionAction.add:
          entries[exception.categoryId!] = ScheduledCollection(
            data.categories[exception.categoryId]!,
            exception.deadline!,
            exception.sourceIds,
          );
        case ExceptionAction.move:
          if (date == exception.date) {
            entries.remove(exception.categoryId);
          } else {
            entries[exception.categoryId!] = ScheduledCollection(
              data.categories[exception.categoryId]!,
              exception.deadline!,
              exception.sourceIds,
            );
          }
        case ExceptionAction.needsConfirmation:
          return unknown(ScheduleReason.unknownException);
      }
    }
    final collections = data.categories.keys
        .where(entries.containsKey)
        .map((id) => entries[id]!)
        .toList();
    return result(
      collections.isEmpty ? ScheduleStatus.none : ScheduleStatus.collection,
      collections: collections,
    );
  }
}
