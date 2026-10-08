// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/widgets/widget_offer_store.dart';
import 'package:gomimap/widgets/widget_setup_store.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/data/demo_data.dart';

class FailedOfferPreferences implements SharedPreferences {
  Object? persisted, optimistic;
  int reloads = 0;
  bool reloadFails = false;
  @override
  Object? get(String key) => optimistic ?? persisted;
  @override
  bool containsKey(String key) => get(key) != null;
  @override
  Future<bool> setBool(String key, bool value) async {
    optimistic = value;
    return false;
  }

  @override
  Future<void> reload() async {
    if (reloadFails) throw StateError('host storage unavailable');
    optimistic = persisted;
    reloads++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CountingSetupStore implements DemoSetupStore {
  int writes = 0;
  @override
  DemoSetupSnapshot read() => const DemoSetupSnapshot.choose();
  @override
  Future<bool> save(DemoSetupSnapshot snapshot) async {
    writes++;
    return true;
  }
}

void main() {
  test('failed reload cannot turn optimistic pending cache into a committed marker', () async {
    final prefs = FailedOfferPreferences()..reloadFails = true;
    final delegate = CountingSetupStore();
    final setup = WidgetSetupStore(
      delegate,
      WidgetOfferStore(prefs, legacyDistrictSaved: false),
    );
    for (var i = 0; i < 2; i++) {
      expect(
        await setup.save(const DemoSetupSnapshot.saved(DemoArea.a)),
        false,
      );
    }
    expect(prefs.containsKey(WidgetOfferStore.key), true);
    expect(delegate.writes, 0);
  });
  test('failed answer reloads optimistic preferences and does not suppress a pending offer', () {
    final prefs = FailedOfferPreferences()..persisted = false;
    final offer = WidgetOfferStore(prefs, legacyDistrictSaved: true);
    return offer.answer().then((success) {
      expect(success, false);
      expect(offer.answered, false);
      expect(prefs.reloads, 1);
      expect(
        WidgetOfferStore(prefs, legacyDistrictSaved: true).answered,
        false,
      );
    });
  });
  test('failed pending marker prevents district commit, including a repeated attempt', () async {
    final prefs = FailedOfferPreferences();
    final delegate = CountingSetupStore();
    final offer = WidgetOfferStore(prefs, legacyDistrictSaved: false);
    final setup = WidgetSetupStore(delegate, offer);
    for (var i = 0; i < 2; i++) {
      expect(
        await setup.save(const DemoSetupSnapshot.saved(DemoArea.a)),
        false,
      );
    }
    expect(delegate.writes, 0);
    expect(prefs.reloads, 2);
    expect(prefs.containsKey(WidgetOfferStore.key), false);
  });
}
