// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import '../notifications/notification_state.dart';

abstract interface class UpdateJournal {
  Future<String?> read();
  Future<bool> write(String value);
}

class MemoryUpdateJournal implements UpdateJournal {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<bool> write(String value) async {
    this.value = value;
    return true;
  }
}

void validateSelection(Map<String, Object?> state) {
  const keys = {
    'municipalityId',
    'areaId',
    'datasetVersion',
    'locale',
    'notifications',
    'notificationAnswered',
  };
  if (state.keys.toSet().difference(keys).isNotEmpty ||
      !keys.every(state.containsKey) ||
      state['notificationAnswered'] is! bool) {
    throw const FormatException('Invalid selection fields');
  }
  for (final field in ['municipalityId', 'areaId', 'datasetVersion']) {
    final value = state[field];
    if (value != null &&
        (value is! String ||
            !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$').hasMatch(value))) {
      throw const FormatException('Invalid identity');
    }
  }
  if (state['locale'] is! String ||
      !RegExp(r'^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$')
          .hasMatch(state['locale'] as String)) {
    throw const FormatException('Invalid locale');
  }
  final settings = state['notifications'];
  if (settings is! Map ||
      settings.keys.toSet().difference({
        'enabled',
        'eveningEnabled',
        'morningMinute',
        'eveningMinute',
      }).isNotEmpty) {
    throw const FormatException('Invalid notification fields');
  }
  NotificationSettings.decode(settings);
}

Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}

bool sameSelection(Map<String, Object?> a, Map<String, Object?> b) =>
    jsonEncode(canonical(a)) == jsonEncode(canonical(b));

class PendingUpdate {
  PendingUpdate({
    required this.reason,
    required this.previous,
    required this.target,
    required this.phase,
  });
  final String reason;
  final Map<String, Object?> previous, target;
  String phase;
  Map<String, Object?> toJson() => {
    'reason': reason,
    'previous': previous,
    'target': target,
    'phase': phase,
  };
}

class UpdateRecord {
  UpdateRecord(this.sequence, this.pending);
  final int sequence;
  final PendingUpdate? pending;
  String encode() => jsonEncode({
    'version': 1,
    'sequence': sequence,
    'pending': pending?.toJson(),
  });
  static UpdateRecord decode(String? text) {
    if (text == null) return UpdateRecord(0, null);
    if (utf8.encode(text).length > 16384) {
      throw const FormatException('Journal too large');
    }
    final value = jsonDecode(text);
    if (value is! Map ||
        value.keys.toSet().difference({
          'version',
          'sequence',
          'pending',
        }).isNotEmpty ||
        !{'version', 'sequence', 'pending'}.every(value.containsKey) ||
        value['version'] != 1 ||
        value['sequence'] is! int ||
        value['sequence'] < 0 ||
        value['sequence'] > 9007199254740991) {
      throw const FormatException('Unknown journal');
    }
    final raw = value['pending'];
    if (raw == null) return UpdateRecord(value['sequence'], null);
    if (raw is! Map ||
        raw.keys.toSet().difference({
          'reason',
          'previous',
          'target',
          'phase',
        }).isNotEmpty ||
        !{'reason', 'previous', 'target', 'phase'}.every(raw.containsKey) ||
        !{
          'district',
          'language',
          'dataset',
          'notifications',
        }.contains(raw['reason']) ||
        !{
          'prepared',
          'stopped',
          'committed',
          'needsRetry',
        }.contains(raw['phase'])) {
      throw const FormatException('Unknown pending update');
    }
    final previous = Map<String, Object?>.from(raw['previous'] as Map),
        target = Map<String, Object?>.from(raw['target'] as Map);
    validateSelection(previous);
    validateSelection(target);
    return UpdateRecord(
      value['sequence'],
      PendingUpdate(
        reason: raw['reason'],
        previous: previous,
        target: target,
        phase: raw['phase'],
      ),
    );
  }
}
