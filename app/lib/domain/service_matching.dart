// SPDX-License-Identifier: GPL-3.0-or-later

import 'calendar_date.dart';
import 'conditions.dart';
import 'municipal_dataset.dart';

enum ServiceBlock {
  outsideCoverage,
  paused,
  unconfirmed,
  evidenceUnconfirmed,
  coordinatesUnknown,
  hoursUnknown,
}

enum OpeningStatus { open, closed, unknown }

class ServiceMatch {
  ServiceMatch({
    required this.facility,
    required this.service,
    required this.acceptance,
    required this.datasetVersion,
    required this.municipalityId,
    Iterable<ServiceBlock> blocks = const [],
  }) : blocks = Set.unmodifiable(blocks);
  final CollectionFacility facility;
  final CollectionService service;
  final ConditionResult acceptance;
  final String municipalityId;
  final String datasetVersion;
  final Set<ServiceBlock> blocks;
  bool get canRecommend =>
      acceptance.status == ConditionStatus.accepted && blocks.isEmpty;
}

/// Returns related PUBLIC special-item services with exclusion reasons.
/// A map must use canRecommend for suggested pins; openingAt is separate.
List<ServiceMatch> matchServices(
  MunicipalDataset dataset,
  String itemId,
  CalendarDate date,
  Map<String, Object?> facts,
) {
  if (dataset.items[itemId]?.mapEligible != true) return const [];
  final matches = <ServiceMatch>[];
  for (final service in dataset.services.values) {
    final rules = dataset.acceptanceRules
        .where(
          (value) => value.serviceId == service.id && value.itemId == itemId,
        )
        .toList();
    final facility = dataset.facilities[service.facilityId]!;
    if (rules.isEmpty || facility.access != FacilityAccess.publicDropOff) {
      continue;
    }
    final blocks = <ServiceBlock>{};
    if (!dataset.period.contains(date) || !service.period.contains(date)) {
      blocks.add(ServiceBlock.outsideCoverage);
    }
    if (service.state == ServiceState.paused) blocks.add(ServiceBlock.paused);
    if (service.state == ServiceState.unconfirmed) {
      blocks.add(ServiceBlock.unconfirmed);
    }
    if (!dataset.evidenceSupports(service.sourceIds, date) ||
        !dataset.evidenceSupports(facility.sourceIds, date)) {
      blocks.add(ServiceBlock.evidenceUnconfirmed);
    }
    if (facility.coordinates == null ||
        !dataset.evidenceSupports(facility.coordinates!.sourceIds, date)) {
      blocks.add(ServiceBlock.coordinatesUnknown);
    }
    if (service.hours.isEmpty ||
        service.hours.any(
          (value) => !dataset.evidenceSupports(value.sourceIds, date),
        )) {
      blocks.add(ServiceBlock.hoursUnknown);
    }
    final results = rules
        .map(
          (rule) =>
              !rule.period.contains(date) ||
                  !dataset.evidenceSupports(rule.sourceIds, date)
              ? ConditionResult(ConditionStatus.unknown)
              : allConditions(rule.conditions, facts),
        )
        .toList();
    final accepted = results.any(
      (value) => value.status == ConditionStatus.accepted,
    );
    final unknown = results
        .where((value) => value.status == ConditionStatus.unknown)
        .toList();
    final decision = accepted
        ? ConditionResult(ConditionStatus.accepted)
        : unknown.isNotEmpty
        ? ConditionResult(
            ConditionStatus.unknown,
            unknown.expand((value) => value.missingFields),
          )
        : ConditionResult(ConditionStatus.rejected);
    matches.add(
      ServiceMatch(
        facility: facility,
        service: service,
        acceptance: decision,
        blocks: blocks,
        datasetVersion: dataset.version,
        municipalityId: dataset.municipality.id,
      ),
    );
  }
  return List.unmodifiable(matches);
}

OpeningStatus openingAt(
  MunicipalDataset dataset,
  CollectionService service,
  DateTime instant,
) {
  final local = instant.toUtc().add(const Duration(hours: 9));
  final date = CalendarDate.fromFields(local);
  if (!dataset.period.contains(date) ||
      !service.period.contains(date) ||
      !dataset.evidenceSupports(service.sourceIds, date) ||
      service.state == ServiceState.unconfirmed ||
      service.hours.isEmpty ||
      service.hours.any(
        (value) => !dataset.evidenceSupports(value.sourceIds, date),
      )) {
    return OpeningStatus.unknown;
  }
  if (service.state == ServiceState.paused) return OpeningStatus.closed;
  final time = LocalTime(local.hour, local.minute);
  return service.hours.any(
        (value) =>
            value.weekdays.contains(date.weekday) &&
            value.opens.compareTo(time) <= 0 &&
            time.compareTo(value.closes) < 0,
      )
      ? OpeningStatus.open
      : OpeningStatus.closed;
}
