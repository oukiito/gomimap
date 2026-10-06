// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';

/// This state belongs to the fictional demo, never to a real home address.
enum DemoSetupPhase { choose, confirm, districtSaved }

class DemoSetupSnapshot {
  const DemoSetupSnapshot.choose({this.recovered = false})
    : phase = DemoSetupPhase.choose,
      area = null;
  const DemoSetupSnapshot.confirm(DemoArea candidate)
    : phase = DemoSetupPhase.confirm,
      area = candidate,
      recovered = false;
  const DemoSetupSnapshot.saved(DemoArea confirmed)
    : phase = DemoSetupPhase.districtSaved,
      area = confirmed,
      recovered = false;

  final DemoSetupPhase phase;
  final DemoArea? area;
  final bool recovered;

  String encode() => jsonEncode({
    'version': 1,
    'phase': phase.name,
    if (area != null) 'area': area!.name,
  });

  static DemoSetupSnapshot decode(String encoded) {
    try {
      final value = jsonDecode(encoded);
      if (value is! Map || value['version'] != 1) {
        return const DemoSetupSnapshot.choose(recovered: true);
      }
      final area = switch (value['area']) {
        'a' => DemoArea.a,
        'b' => DemoArea.b,
        _ => null,
      };
      if (value['phase'] == 'choose' && !value.containsKey('area')) {
        return const DemoSetupSnapshot.choose();
      }
      if (area != null) {
        if (value['phase'] == 'confirm') return DemoSetupSnapshot.confirm(area);
        if (value['phase'] == 'districtSaved') {
          return DemoSetupSnapshot.saved(area);
        }
      }
    } catch (_) {
      // A damaged or newer setting must not silently select a demo district.
    }
    return const DemoSetupSnapshot.choose(recovered: true);
  }
}

abstract interface class DemoSetupStore {
  DemoSetupSnapshot read();
  Future<bool> save(DemoSetupSnapshot snapshot);
}

class PreferencesDemoSetupStore implements DemoSetupStore {
  PreferencesDemoSetupStore(this.preferences);
  static const key = 'demo.setup.v1';
  final SharedPreferences preferences;
  DemoSetupSnapshot? _committed;

  @override
  DemoSetupSnapshot read() => _committed ??= _load();

  DemoSetupSnapshot _load() {
    // Once the new key exists, a corrupt value must not revive a stale legacy
    // area. Recognized old settings alone can bypass first-time demo selection.
    if (preferences.containsKey(key)) {
      final value = preferences.get(key);
      return value is String
          ? DemoSetupSnapshot.decode(value)
          : const DemoSetupSnapshot.choose(recovered: true);
    }
    return switch (preferences.get('demo.area')) {
      'a' => const DemoSetupSnapshot.saved(DemoArea.a),
      'b' => const DemoSetupSnapshot.saved(DemoArea.b),
      null => const DemoSetupSnapshot.choose(),
      _ => const DemoSetupSnapshot.choose(recovered: true),
    };
  }

  @override
  Future<bool> save(DemoSetupSnapshot snapshot) async {
    read();
    try {
      // Phase and district share one value, avoiding a half-saved transition.
      if (await preferences.setString(key, snapshot.encode())) {
        _committed = snapshot;
        return true;
      }
    } catch (_) {
      // Keep the last confirmed in-memory state on storage errors.
    }
    // The legacy plugin updates its cache before completing the write. Reload
    // on false/exception so reconstructing a repository cannot accept that
    // optimistic value as a confirmed district. No rollback write is issued.
    try {
      await preferences.reload();
    } catch (_) {
      // read() still returns this repository's previous committed snapshot.
    }
    return false;
  }
}
