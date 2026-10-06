// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Matches the legacy plugin's optimistic cache, with controllable host errors.
class FaultyPreferences implements SharedPreferences {
  FaultyPreferences(this.persisted);
  String? persisted;
  String? cached;
  bool throws = false;
  int reloads = 0;
  Completer<bool>? write;

  @override
  bool containsKey(String key) => key == PreferencesDemoSetupStore.key;
  @override
  Object? get(String key) => cached ?? persisted;
  @override
  Future<bool> setString(String key, String value) async {
    cached = value;
    if (throws) throw StateError('storage unavailable');
    final success = await (write?.future ?? Future.value(false));
    if (success) persisted = value;
    return success;
  }

  @override
  Future<void> reload() async {
    reloads++;
    cached = persisted;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first-time settings have no default district', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferencesDemoSetupStore(
      await SharedPreferences.getInstance(),
    );
    expect(store.read().phase, DemoSetupPhase.choose);
    expect(store.read().area, isNull);
  });

  test('only recognized legacy settings bypass first-time selection', () async {
    for (final legacy in ['a', 'b', 'invalid', 42]) {
      SharedPreferences.setMockInitialValues({'demo.area': legacy});
      final snapshot = PreferencesDemoSetupStore(
        await SharedPreferences.getInstance(),
      ).read();
      if (legacy == 'a' || legacy == 'b') {
        expect(snapshot.phase, DemoSetupPhase.districtSaved);
        expect(snapshot.area!.name, legacy);
      } else {
        expect(snapshot.phase, DemoSetupPhase.choose);
        expect(snapshot.recovered, isTrue);
      }
    }
  });

  test('saved candidate resumes confirmation, never the calendar', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = PreferencesDemoSetupStore(prefs);
    expect(
      await store.save(const DemoSetupSnapshot.confirm(DemoArea.b)),
      isTrue,
    );
    await prefs.reload();
    final restarted = PreferencesDemoSetupStore(prefs).read();
    expect(restarted.phase, DemoSetupPhase.confirm);
    expect(restarted.area, DemoArea.b);
    expect(prefs.get('demo.area'), isNull);
  });

  test(
    'invalid new records never fall back to a stale legacy district',
    () async {
      for (final value in [
        'not-json',
        '[]',
        '{"version":2,"phase":"districtSaved","area":"b"}',
        '{"version":1,"phase":"districtSaved"}',
        '{"version":1,"phase":"confirm","area":"unknown"}',
        '{"version":1,"phase":"choose","area":"a"}',
        '{"version":1,"phase":"unsupported","area":"b"}',
        42,
      ]) {
        SharedPreferences.setMockInitialValues({
          PreferencesDemoSetupStore.key: value,
          'demo.area': 'a',
        });
        final snapshot = PreferencesDemoSetupStore(
          await SharedPreferences.getInstance(),
        ).read();
        expect(snapshot.phase, DemoSetupPhase.choose, reason: '$value');
        expect(snapshot.area, isNull);
        expect(snapshot.recovered, isTrue);
      }
    },
  );

  for (final throws in [false, true]) {
    test(
      'failed write ($throws) refreshes the optimistic cache and keeps the previous district',
      () async {
        final prefs = FaultyPreferences(
          const DemoSetupSnapshot.saved(DemoArea.a).encode(),
        )..throws = throws;
        final store = PreferencesDemoSetupStore(prefs);
        expect(
          await store.save(const DemoSetupSnapshot.saved(DemoArea.b)),
          isFalse,
        );
        expect(store.read().area, DemoArea.a);
        expect(prefs.reloads, 1);
        expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.a);
      },
    );
  }

  test(
    'pending write is not exposed as confirmed, success commits one record',
    () async {
      final prefs = FaultyPreferences(
        const DemoSetupSnapshot.saved(DemoArea.a).encode(),
      )..write = Completer<bool>();
      final store = PreferencesDemoSetupStore(prefs);
      final saving = store.save(const DemoSetupSnapshot.saved(DemoArea.b));
      expect(store.read().area, DemoArea.a);
      prefs.write!.complete(true);
      expect(await saving, isTrue);
      expect(store.read().area, DemoArea.b);
      expect(
        DemoSetupSnapshot.decode(prefs.persisted!).phase,
        DemoSetupPhase.districtSaved,
      );
      expect(prefs.reloads, 0);
    },
  );
}
