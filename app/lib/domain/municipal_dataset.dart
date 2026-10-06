// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'calendar_date.dart';
import 'conditions.dart';

enum DatasetKind { fixture, verified }

enum ReviewState { reviewed, pending }

enum ReuseState { allowed, needsReview, disallowed }

enum ExceptionAction { cancel, add, move, needsConfirmation }

enum FacilityAccess { publicDropOff, householdCollection }

enum ServiceState { active, paused, unconfirmed }

class Municipality {
  Municipality._(JsonObject json)
    : id = json.id('id'),
      name = json.text('name'),
      officialUrl = json.https('officialUrl'),
      timezone = json.text('timezone'),
      codeSystem = json.optionalText('codeSystem'),
      code = json.optionalText('code') {
    json.only({'id', 'name', 'officialUrl', 'timezone', 'codeSystem', 'code'});
    if (timezone != 'Asia/Tokyo') {
      json.fail('Only Asia/Tokyo is supported in schema 1');
    }
    if ((code == null) != (codeSystem == null)) {
      json.fail('code and codeSystem must be paired');
    }
  }
  final String id;
  final String name;
  final String officialUrl;
  final String timezone;
  final String? codeSystem;
  final String? code;
}

class SourceEvidence {
  SourceEvidence._(JsonObject json)
    : id = json.id('id'),
      url = json.https('url'),
      publisher = json.text('publisher'),
      locator = json.text('locator'),
      registryId = json.optionalText('registryId'),
      license = json.text('license'),
      review = json.enumValue('review', ReviewState.values),
      reuse = json.enumValue('reuse', ReuseState.values),
      fixture = json.boolean('fixture'),
      reviewer = json.text('reviewer'),
      retrievedAt = json.timestamp('retrievedAt'),
      reviewedAt = json.timestamp('reviewedAt'),
      period = json.period('validPeriod') {
    json.only({
      'id',
      'url',
      'publisher',
      'locator',
      'registryId',
      'license',
      'review',
      'reuse',
      'fixture',
      'reviewer',
      'retrievedAt',
      'reviewedAt',
      'validPeriod',
    });
    if (reviewedAt.isBefore(retrievedAt)) {
      json.fail('Review predates retrieval');
    }
  }
  final String id;
  final String url;
  final String publisher;
  final String locator;
  final String? registryId;
  final String license;
  final ReviewState review;
  final ReuseState reuse;
  final bool fixture;
  final String reviewer;
  final DateTime retrievedAt;
  final DateTime reviewedAt;
  final DatePeriod period;
  bool supports(CalendarDate date) =>
      review == ReviewState.reviewed &&
      reuse == ReuseState.allowed &&
      period.contains(date);
}

class CollectionArea {
  CollectionArea._(JsonObject json)
    : id = json.id('id'),
      name = json.text('name'),
      period = json.period('validPeriod'),
      sourceIds = json.ids('sourceIds'),
      selectors = List.unmodifiable(
        json
            .list('addressSelectors')
            .map(
              (value) => List<DataCondition>.unmodifiable(
                JsonObject.asList(value, '${json.path}.addressSelectors').map(
                  (entry) => parseCondition(
                    JsonObject(entry, '${json.path}.condition'),
                  ),
                ),
              ),
            ),
      ) {
    json.only({'id', 'name', 'validPeriod', 'sourceIds', 'addressSelectors'});
    if (selectors.isEmpty || selectors.any((group) => group.isEmpty)) {
      json.fail('Address selectors must be explicit');
    }
  }
  final String id;
  final String name;
  final DatePeriod period;
  final List<String> sourceIds;
  final List<List<DataCondition>> selectors;
}

class WasteCategory {
  WasteCategory._(JsonObject json)
    : id = json.id('id'),
      name = json.text('name'),
      displayKey = json.optionalText('displayKey'),
      scheduled = json.boolean('scheduled') {
    json.only({'id', 'name', 'displayKey', 'scheduled'});
    if (displayKey != null &&
        !{'burnable', 'recyclables', 'metals'}.contains(displayKey)) {
      json.fail('Unsupported displayKey; omit it to preserve the source name');
    }
  }
  final String id;
  final String name;
  final String? displayKey;
  final bool scheduled;
}

class WasteItem {
  WasteItem._(JsonObject json)
    : id = json.id('id'),
      name = json.text('name'),
      mapEligible = json.boolean('mapEligible') {
    json.only({'id', 'name', 'mapEligible'});
  }
  final String id;
  final String name;
  final bool mapEligible;
}

class Recurrence {
  Recurrence._(JsonObject json)
    : weekdays = json.intSet('weekdays', 1, 7),
      monthOccurrences = json.intSet(
        'monthOccurrences',
        1,
        5,
        allowEmpty: true,
      ),
      deadline = LocalTime.parse(json.text('deadline')) {
    json.only({'weekdays', 'monthOccurrences', 'deadline'});
  }
  final Set<int> weekdays;
  final Set<int> monthOccurrences;
  final LocalTime deadline;
  bool matches(CalendarDate date) =>
      weekdays.contains(date.weekday) &&
      (monthOccurrences.isEmpty ||
          monthOccurrences.contains(date.monthOccurrence));
}

/// One reviewed baseline per area/category/period. Empty recurrences explicitly
/// declare no regular collection; a missing baseline never makes that claim.
class CollectionBaseline {
  CollectionBaseline._(JsonObject json)
    : id = json.id('id'),
      areaId = json.id('areaId'),
      categoryId = json.id('categoryId'),
      period = json.period('validPeriod'),
      sourceIds = json.ids('sourceIds'),
      recurrences = List.unmodifiable(
        json.objects('recurrences').map(Recurrence._),
      ) {
    json.only({
      'id',
      'areaId',
      'categoryId',
      'validPeriod',
      'sourceIds',
      'recurrences',
    });
  }
  final String id;
  final String areaId;
  final String categoryId;
  final DatePeriod period;
  final List<String> sourceIds;
  final List<Recurrence> recurrences;
}

class CalendarException {
  CalendarException._(JsonObject json)
    : id = json.id('id'),
      areaId = json.id('areaId'),
      categoryId = json.optionalId('categoryId'),
      date = CalendarDate.parse(json.text('date')),
      action = json.enumValue('action', ExceptionAction.values),
      targetDate = json.optionalText('targetDate') == null
          ? null
          : CalendarDate.parse(json.text('targetDate')),
      deadline = json.optionalText('deadline') == null
          ? null
          : LocalTime.parse(json.text('deadline')),
      sourceIds = json.ids('sourceIds') {
    json.only({
      'id',
      'areaId',
      'categoryId',
      'date',
      'action',
      'targetDate',
      'deadline',
      'sourceIds',
    });
    if (action != ExceptionAction.needsConfirmation && categoryId == null) {
      json.fail('categoryId is required');
    }
    if ((action == ExceptionAction.move) != (targetDate != null)) {
      json.fail('targetDate is only for move');
    }
    if (targetDate == date) json.fail('Move must have a different target date');
    if ((action == ExceptionAction.add || action == ExceptionAction.move) !=
        (deadline != null)) {
      json.fail('add and move require a deadline; other actions must omit it');
    }
  }
  final String id;
  final String areaId;
  final String? categoryId;
  final CalendarDate date;
  final ExceptionAction action;
  final CalendarDate? targetDate;
  final LocalTime? deadline;
  final List<String> sourceIds;
  bool affects(CalendarDate day) => date == day || targetDate == day;
}

class FacilityCoordinates {
  FacilityCoordinates._(JsonObject json)
    : latitude = json.number('latitude').toDouble(),
      longitude = json.number('longitude').toDouble(),
      accuracyMeters = json.number('accuracyMeters').toDouble(),
      sourceIds = json.ids('sourceIds') {
    json.only({'latitude', 'longitude', 'accuracyMeters', 'sourceIds'});
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        accuracyMeters <= 0) {
      json.fail('Invalid coordinates or accuracy');
    }
  }
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final List<String> sourceIds;
}

class CollectionFacility {
  CollectionFacility._(JsonObject json)
    : id = json.id('id'),
      name = json.text('name'),
      address = json.text('address'),
      access = json.enumValue('access', FacilityAccess.values),
      sourceIds = json.ids('sourceIds'),
      coordinates = json.value['coordinates'] == null
          ? null
          : FacilityCoordinates._(json.object('coordinates')) {
    json.only({'id', 'name', 'address', 'access', 'sourceIds', 'coordinates'});
  }
  final String id;
  final String name;
  final String address;
  final FacilityAccess access;
  final List<String> sourceIds;
  final FacilityCoordinates? coordinates;
}

class ServiceHours {
  ServiceHours._(JsonObject json)
    : weekdays = json.intSet('weekdays', 1, 7),
      opens = LocalTime.parse(json.text('opens')),
      closes = LocalTime.parse(json.text('closes')),
      sourceIds = json.ids('sourceIds') {
    json.only({'weekdays', 'opens', 'closes', 'sourceIds'});
    if (opens.compareTo(closes) >= 0) {
      json.fail('Opening window must end after its start');
    }
  }
  final Set<int> weekdays;
  final LocalTime opens;
  final LocalTime closes;
  final List<String> sourceIds;
}

class CollectionService {
  CollectionService._(JsonObject json)
    : id = json.id('id'),
      facilityId = json.id('facilityId'),
      location = json.text('location'),
      period = json.period('validPeriod'),
      state = json.enumValue('state', ServiceState.values),
      sourceIds = json.ids('sourceIds'),
      hours = List.unmodifiable(json.objects('hours').map(ServiceHours._)) {
    json.only({
      'id',
      'facilityId',
      'location',
      'validPeriod',
      'state',
      'sourceIds',
      'hours',
    });
  }
  final String id;
  final String facilityId;
  final String location;
  final DatePeriod period;
  final ServiceState state;
  final List<String> sourceIds;
  final List<ServiceHours> hours;
}

class AcceptanceRule {
  AcceptanceRule._(JsonObject json)
    : id = json.id('id'),
      serviceId = json.id('serviceId'),
      itemId = json.id('itemId'),
      period = json.period('validPeriod'),
      sourceIds = json.ids('sourceIds'),
      conditions = List.unmodifiable(
        json.objects('conditions').map(parseCondition),
      ) {
    json.only({
      'id',
      'serviceId',
      'itemId',
      'validPeriod',
      'sourceIds',
      'conditions',
    });
  }
  final String id;
  final String serviceId;
  final String itemId;
  final DatePeriod period;
  final List<String> sourceIds;
  final List<DataCondition> conditions;
}

class MunicipalDataset {
  MunicipalDataset._(JsonObject json, {required bool allowFixtures})
    : schemaVersion = json.integer('schemaVersion'),
      version = json.id('version'),
      kind = json.enumValue('kind', DatasetKind.values),
      publishedAt = json.timestamp('publishedAt'),
      period = json.period('validPeriod'),
      municipality = Municipality._(json.object('municipality')),
      sources = indexed(
        json.objects('sources').map(SourceEvidence._),
        (value) => value.id,
        'sources',
      ),
      areas = indexed(
        json.objects('areas').map(CollectionArea._),
        (value) => value.id,
        'areas',
      ),
      categories = indexed(
        json.objects('categories').map(WasteCategory._),
        (value) => value.id,
        'categories',
      ),
      items = indexed(
        json.objects('items').map(WasteItem._),
        (value) => value.id,
        'items',
      ),
      baselines = List.unmodifiable(
        json.objects('baselines').map(CollectionBaseline._),
      ),
      exceptions = List.unmodifiable(
        json.objects('exceptions').map(CalendarException._),
      ),
      facilities = indexed(
        json.objects('facilities').map(CollectionFacility._),
        (value) => value.id,
        'facilities',
      ),
      services = indexed(
        json.objects('services').map(CollectionService._),
        (value) => value.id,
        'services',
      ),
      acceptanceRules = List.unmodifiable(
        json.objects('acceptanceRules').map(AcceptanceRule._),
      ) {
    json.only({
      'schemaVersion',
      'version',
      'kind',
      'publishedAt',
      'validPeriod',
      'municipality',
      'sources',
      'areas',
      'categories',
      'items',
      'baselines',
      'exceptions',
      'facilities',
      'services',
      'acceptanceRules',
    });
    if (schemaVersion != 1) json.fail('Unsupported schema version');
    if (kind == DatasetKind.fixture && !allowFixtures) {
      json.fail('Fixture data is not allowed here');
    }
    if (areas.isEmpty || categories.isEmpty || sources.isEmpty) {
      json.fail('Missing schedule entities');
    }
    if (sources.values.any(
      (source) => source.reviewedAt.isAfter(publishedAt),
    )) {
      json.fail('Publication predates review');
    }
    if (kind == DatasetKind.verified &&
        sources.values.any(
          (source) =>
              source.fixture ||
              source.review != ReviewState.reviewed ||
              source.reuse != ReuseState.allowed ||
              source.registryId == null,
        )) {
      json.fail(
        'Verified data requires reviewed, reusable, registered non-fixture sources',
      );
    }
    validateReferences();
  }
  factory MunicipalDataset.decode(String text, {bool allowFixtures = false}) {
    if (utf8.encode(text).length > 2 * 1024 * 1024) {
      throw FormatException('Dataset exceeds 2 MiB');
    }
    final json = JsonObject(jsonDecode(text), r'$');
    if (json.integer('schemaVersion') != 1) {
      json.fail('Unsupported schema version');
    }
    return MunicipalDataset._(json, allowFixtures: allowFixtures);
  }
  final int schemaVersion;
  final String version;
  final DatasetKind kind;
  final DateTime publishedAt;
  final DatePeriod period;
  final Municipality municipality;
  final Map<String, SourceEvidence> sources;
  final Map<String, CollectionArea> areas;
  final Map<String, WasteCategory> categories;
  final Map<String, WasteItem> items;
  final List<CollectionBaseline> baselines;
  final List<CalendarException> exceptions;
  final Map<String, CollectionFacility> facilities;
  final Map<String, CollectionService> services;
  final List<AcceptanceRule> acceptanceRules;

  bool evidenceSupports(Iterable<String> ids, CalendarDate date) =>
      ids.isNotEmpty && ids.every((id) => sources[id]?.supports(date) == true);

  void validateReferences() {
    void sourcesExist(Iterable<String> ids) {
      if (ids.any((id) => !sources.containsKey(id))) {
        throw FormatException('Unknown source reference');
      }
    }

    void requireId(Map<String, Object> table, String id, String type) {
      if (!table.containsKey(id)) {
        throw FormatException('Unknown $type reference: $id');
      }
    }

    indexed(baselines, (value) => value.id, 'baselines');
    indexed(exceptions, (value) => value.id, 'exceptions');
    indexed(acceptanceRules, (value) => value.id, 'acceptanceRules');
    for (final area in areas.values) {
      sourcesExist(area.sourceIds);
    }
    for (final baseline in baselines) {
      requireId(areas, baseline.areaId, 'area');
      requireId(categories, baseline.categoryId, 'category');
      sourcesExist(baseline.sourceIds);
    }
    final baselineGroups = <String, List<CollectionBaseline>>{};
    for (final baseline in baselines) {
      if (!categories[baseline.categoryId]!.scheduled) {
        throw FormatException('Baseline refers to a non-scheduled category');
      }
      baselineGroups
          .putIfAbsent('${baseline.areaId}/${baseline.categoryId}', () => [])
          .add(baseline);
    }
    for (final group in baselineGroups.values) {
      group.sort((a, b) => a.period.start.compareTo(b.period.start));
      for (var i = 1; i < group.length; i++) {
        if (group[i - 1].period.overlaps(group[i].period)) {
          throw FormatException('Overlapping baselines');
        }
      }
    }
    final changes = <String>{};
    for (final exception in exceptions) {
      requireId(areas, exception.areaId, 'area');
      if (exception.categoryId != null) {
        requireId(categories, exception.categoryId!, 'category');
      }
      if (exception.categoryId != null &&
          !categories[exception.categoryId]!.scheduled) {
        throw FormatException('Exception refers to a non-scheduled category');
      }
      sourcesExist(exception.sourceIds);
      if (!period.contains(exception.date) ||
          (exception.targetDate != null &&
              !period.contains(exception.targetDate!))) {
        throw FormatException('Exception outside dataset coverage');
      }
      if (exception.action != ExceptionAction.needsConfirmation) {
        for (final date in [
          exception.date,
          if (exception.targetDate != null) exception.targetDate!,
        ]) {
          if (!changes.add(
            '${exception.areaId}/${exception.categoryId}/$date',
          )) {
            throw FormatException('Conflicting calendar exceptions');
          }
        }
      }
    }
    for (final facility in facilities.values) {
      sourcesExist(facility.sourceIds);
      if (facility.coordinates != null) {
        sourcesExist(facility.coordinates!.sourceIds);
      }
    }
    for (final service in services.values) {
      requireId(facilities, service.facilityId, 'facility');
      sourcesExist(service.sourceIds);
      for (final hours in service.hours) {
        sourcesExist(hours.sourceIds);
      }
    }
    for (final rule in acceptanceRules) {
      requireId(services, rule.serviceId, 'service');
      requireId(items, rule.itemId, 'item');
      sourcesExist(rule.sourceIds);
    }
  }
}

Map<String, T> indexed<T>(
  Iterable<T> values,
  String Function(T) key,
  String type,
) {
  final result = <String, T>{};
  for (final value in values) {
    if (result.containsKey(key(value))) {
      throw FormatException('Duplicate $type id');
    }
    result[key(value)] = value;
  }
  return Map.unmodifiable(result);
}

DataCondition parseCondition(JsonObject json) {
  json.only({'field', 'question', 'operator', 'values', 'minimum', 'maximum'});
  final operator = json.enumValue('operator', ConditionOperator.values);
  final values = json.value.containsKey('values')
      ? json.list('values')
      : <Object?>[];
  num? minimum;
  num? maximum;
  if (operator == ConditionOperator.range) {
    minimum = json.number('minimum');
    maximum = json.number('maximum');
    if (minimum > maximum || values.isNotEmpty) {
      json.fail('Invalid range condition');
    }
  } else {
    if (values.isEmpty ||
        (operator == ConditionOperator.isValue && values.length != 1) ||
        json.value.containsKey('minimum') ||
        json.value.containsKey('maximum')) {
      json.fail('Invalid value condition');
    }
    bool scalar(Object? value) =>
        value is String && value.isNotEmpty ||
        value is bool ||
        value is num && value.isFinite;
    final first = values.first;
    bool sameType(Object? value) => first is String
        ? value is String
        : first is bool
        ? value is bool
        : value is num;
    if (!values.every(scalar) ||
        !values.every(sameType) ||
        values.toSet().length != values.length) {
      json.fail('Invalid condition values');
    }
  }
  return DataCondition(
    field: json.id('field'),
    question: json.text('question'),
    operator: operator,
    values: values.cast<Object>(),
    minimum: minimum,
    maximum: maximum,
  );
}

/// Strict schema reader: rejects unsupported shapes rather than guessing.
class JsonObject {
  JsonObject(Object? data, this.path)
    : value = data is Map<String, dynamic>
          ? data
          : throw FormatException('$path must be an object');
  final Map<String, dynamic> value;
  final String path;
  Never fail(String message) => throw FormatException('$path: $message');
  void only(Set<String> keys) {
    if (value.keys.any((key) => !keys.contains(key))) fail('Unsupported field');
  }

  String text(String key) {
    final data = value[key];
    if (data is! String || data.trim().isEmpty) {
      fail('$key must be a non-empty string');
    }
    return data;
  }

  String? optionalText(String key) => value[key] == null ? null : text(key);
  String id(String key) {
    final data = text(key);
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$').hasMatch(data)) {
      fail('Invalid $key identifier');
    }
    return data;
  }

  String? optionalId(String key) => value[key] == null ? null : id(key);
  String https(String key) {
    final data = text(key);
    final uri = Uri.tryParse(data);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      fail('$key must be public HTTPS');
    }
    return data;
  }

  int integer(String key) {
    final data = value[key];
    if (data is! int) fail('$key must be an integer');
    return data;
  }

  num number(String key) {
    final data = value[key];
    if (data is! num || !data.isFinite) fail('$key must be finite');
    return data;
  }

  bool boolean(String key) {
    final data = value[key];
    if (data is! bool) fail('$key must be boolean');
    return data;
  }

  List<Object?> list(String key) => asList(value[key], '$path.$key');
  static List<Object?> asList(Object? value, String path) {
    if (value is! List || value.length > 10000) {
      throw FormatException('$path must be a bounded list');
    }
    return value;
  }

  Iterable<JsonObject> objects(String key) =>
      list(key).indexed
          .map((entry) => JsonObject(entry.$2, '$path.$key[${entry.$1}]'));
  JsonObject object(String key) => JsonObject(value[key], '$path.$key');
  List<String> ids(String key) {
    final data = list(key);
    if (data.isEmpty ||
        data.any(
          (id) =>
              id is! String ||
              !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$').hasMatch(id),
        ) ||
        data.toSet().length != data.length) {
      fail('Invalid $key references');
    }
    return List<String>.unmodifiable(data.cast<String>());
  }

  Set<int> intSet(String key, int min, int max, {bool allowEmpty = false}) {
    final data = list(key);
    if ((!allowEmpty && data.isEmpty) ||
        data.any((value) => value is! int || value < min || value > max) ||
        data.toSet().length != data.length) {
      fail('Invalid $key values');
    }
    return Set<int>.unmodifiable(data.cast<int>());
  }

  T enumValue<T extends Enum>(String key, List<T> values) {
    final data = text(key);
    return values.where((value) => value.name == data).firstOrNull ??
        fail('Invalid $key');
  }

  DateTime timestamp(String key) {
    final data = text(key);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$').hasMatch(data)) {
      fail('$key must be a UTC timestamp');
    }
    CalendarDate.parse(data.substring(0, 10));
    LocalTime.parse(data.substring(11, 16));
    if (int.parse(data.substring(17, 19)) > 59) fail('Invalid seconds');
    return DateTime.parse(data);
  }

  DatePeriod period(String key) {
    final json = object(key);
    json.only({'start', 'end'});
    return DatePeriod(
      CalendarDate.parse(json.text('start')),
      CalendarDate.parse(json.text('end')),
    );
  }
}
