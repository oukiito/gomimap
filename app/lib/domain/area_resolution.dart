// SPDX-License-Identifier: GPL-3.0-or-later

import 'calendar_date.dart';
import 'conditions.dart';
import 'municipal_dataset.dart';

enum AreaResolutionStatus {
  matched,
  needsInformation,
  needsConfirmation,
  ambiguous,
  unsupported,
}

class AreaCandidate {
  const AreaCandidate(this.area, this.condition);
  final CollectionArea area;
  final ConditionResult condition;
}

class AreaResolution {
  AreaResolution(
    this.municipalityId,
    this.datasetVersion,
    this.status,
    Iterable<AreaCandidate> candidates,
  ) : candidates = List.unmodifiable(candidates);
  final String municipalityId;
  final String datasetVersion;
  final AreaResolutionStatus status;
  final List<AreaCandidate> candidates;
  Set<String> get missingFields => Set.unmodifiable(
    candidates.expand((value) => value.condition.missingFields),
  );
  String? get matchedAreaId =>
      status == AreaResolutionStatus.matched ? candidates.single.area.id : null;
}

/// Use explicit address answers; never map GPS to a fixture or a nearby area.
AreaResolution resolveArea(
  MunicipalDataset dataset,
  CalendarDate date,
  Map<String, Object?> facts,
) {
  final candidates = <AreaCandidate>[];
  if (!dataset.period.contains(date)) {
    return AreaResolution(
      dataset.municipality.id,
      dataset.version,
      AreaResolutionStatus.needsConfirmation,
      candidates,
    );
  }
  if (dataset.period.contains(date)) {
    for (final area in dataset.areas.values) {
      final trusted =
          area.period.contains(date) &&
          dataset.evidenceSupports(area.sourceIds, date);
      final condition = trusted
          ? anyConditionGroup(area.selectors, facts)
          : ConditionResult(ConditionStatus.unknown);
      if (condition.status == ConditionStatus.rejected) continue;
      candidates.add(AreaCandidate(area, condition));
    }
  }
  final accepted = candidates
      .where((value) => value.condition.status == ConditionStatus.accepted)
      .length;
  final status = candidates.isEmpty
      ? AreaResolutionStatus.unsupported
      : accepted > 1
      ? AreaResolutionStatus.ambiguous
      : accepted == 1 && candidates.length == 1
      ? AreaResolutionStatus.matched
      : candidates.every((value) => value.condition.missingFields.isEmpty)
      ? AreaResolutionStatus.needsConfirmation
      : AreaResolutionStatus.needsInformation;
  return AreaResolution(
    dataset.municipality.id,
    dataset.version,
    status,
    candidates,
  );
}
