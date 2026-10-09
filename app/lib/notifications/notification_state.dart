// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.morningMinute = 360,
    this.eveningEnabled = false,
    this.eveningMinute = 1200,
  });
  final bool enabled, eveningEnabled;
  final int morningMinute, eveningMinute;
  Map<String, Object> toJson() => {
    'enabled': enabled,
    'morningMinute': morningMinute,
    'eveningEnabled': eveningEnabled,
    'eveningMinute': eveningMinute,
  };
  static NotificationSettings decode(Map value) {
    if (value['enabled'] is! bool ||
        value['eveningEnabled'] is! bool ||
        value['morningMinute'] is! int ||
        value['eveningMinute'] is! int ||
        !(value['morningMinute'] as int >= 0 &&
            value['morningMinute'] as int < 1440) ||
        !(value['eveningMinute'] as int >= 0 &&
            value['eveningMinute'] as int < 1440)) {
      throw const FormatException('Invalid notification settings');
    }
    return NotificationSettings(
      enabled: value['enabled'],
      morningMinute: value['morningMinute'],
      eveningEnabled: value['eveningEnabled'],
      eveningMinute: value['eveningMinute'],
    );
  }
}

/// Desired configuration and the one-time offer answer share one committed
/// value. A cache modified optimistically by the preferences plugin is reloaded.
class NotificationStateStore {
  NotificationStateStore(
    this.preferences, {
    required bool legacyDistrictSaved,
  }) {
    answered = legacyDistrictSaved;
    final raw = preferences.get(key);
    if (raw != null) {
      try {
        final data = jsonDecode(raw as String);
        if (data['version'] != 1 || data['answered'] is! bool) {
          throw const FormatException();
        }
        settings = NotificationSettings.decode(data['settings'] as Map);
        answered = data['answered'];
      } catch (_) {
        settings = const NotificationSettings();
        answered = true;
        recovered = true;
      }
    }
  }
  static const key = 'notification.state.v1';
  final SharedPreferences preferences;
  NotificationSettings settings = const NotificationSettings();
  late bool answered;
  bool recovered = false;
  Future<bool> save(
    NotificationSettings desired, {
    required bool answer,
  }) async {
    try {
      if (await preferences.setString(
        key,
        jsonEncode({
          'version': 1,
          'answered': answer,
          'settings': desired.toJson(),
        }),
      )) {
        settings = desired;
        answered = answer;
        recovered = false;
        return true;
      }
    } catch (_) {
      /* Keep committed state. */
    }
    try {
      await preferences.reload();
    } catch (_) {
      /* Keep in-memory state. */
    }
    return false;
  }

  Future<bool> ensurePending() =>
      answered ? Future.value(true) : save(settings, answer: false);
}
