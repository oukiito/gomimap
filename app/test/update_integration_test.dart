// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/data/update_journal.dart';
import 'package:gomimap/data/update_coordinator.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_dataset_repository.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/notifications/notification_state.dart';
import 'package:gomimap/notifications/notification_controller.dart';

import 'support/dataset_fixture.dart';
import 'notification_flow_test.dart' show FakeNotifications;
import 'home_widget_flow_test.dart' show FakeWidgetBridge;
import 'demo_dataset_repository_test.dart'
    show MemoryDatasetCache, FixtureDownload, FixtureBundle, revision;
import 'update_coordinator_test.dart' show selection;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('notification save uses committed state before native reflect without queue deadlock', () async {
    SharedPreferences.setMockInitialValues({});
    final store = NotificationStateStore(
      await SharedPreferences.getInstance(),
      legacyDistrictSaved: true,
    );
    final bridge = FakeNotifications()..applyOk = false;
    final controller = NotificationController(
      store: store,
      bridge: bridge,
      plan: (s) => {'enabled': s.enabled, 'entries': []},
    );
    final journal = MemoryUpdateJournal();
    final updates = UpdateCoordinator(
      journal: journal,
      readState: () => {
        ...selection(),
        'notifications': store.settings.toJson(),
        'notificationAnswered': store.answered,
      },
      stop: controller.pause,
      reflect: controller.reflectNow,
    );
    controller.coordinator = updates;
    addTearDown(controller.dispose);
    addTearDown(updates.dispose);
    expect(
      await controller.save(
        const NotificationSettings(enabled: true),
        answer: true,
      ),
      isTrue,
    );
    expect(store.settings.enabled, isTrue);
    expect(controller.failed, isTrue);
    expect(bridge.plans.last['enabled'], isTrue);
    bridge.applyOk = true;
    await controller.refresh();
    expect(controller.failed, isFalse);
    expect(UpdateRecord.decode(journal.value).pending, isNull);
  });
  test('district cannot save when stop fails; successful retry reflects committed district', () async {
    SharedPreferences.setMockInitialValues({
      PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
          .encode(),
    });
    final prefs = await SharedPreferences.getInstance();
    final base = PreferencesDemoSetupStore(prefs);
    final bridge = FakeNotifications()..stop = false;
    final controller = NotificationController(
      store: NotificationStateStore(prefs, legacyDistrictSaved: true),
      bridge: bridge,
      plan: (_) => {'area': base.read().area!.name, 'entries': []},
    );
    final journal = MemoryUpdateJournal();
    final updates = UpdateCoordinator(
      journal: journal,
      readState: () => {...selection(), 'areaId': base.read().area!.name},
      stop: controller.pause,
      reflect: controller.reflectNow,
    );
    controller.coordinator = updates;
    addTearDown(controller.dispose);
    addTearDown(updates.dispose);
    final district = NotificationSetupStore(base, controller);
    expect(
      await district.save(const DemoSetupSnapshot.saved(DemoArea.b)),
      isFalse,
    );
    expect(base.read().area, DemoArea.a);
    bridge.stop = true;
    expect(
      await district.save(const DemoSetupSnapshot.saved(DemoArea.b)),
      isTrue,
    );
    expect(bridge.plans.last['area'], 'b');
    expect(UpdateRecord.decode(journal.value).pending, isNull);
  });
  test('downloaded version is installed before effects and failed native effects stay pending', () async {
    final cache = MemoryDatasetCache(),
        download = FixtureDownload(revision('v2'));
    final repository = DemoDatasetRepository(cache: cache, download: download);
    await repository.initialize(
      bundle: FixtureBundle(jsonEncode(fixtureJson())),
    );
    final journal = MemoryUpdateJournal();
    final versions = <String>[];
    var reflectOk = false;
    final updates = UpdateCoordinator(
      journal: journal,
      readState: () => {
        ...selection(),
        'datasetVersion': repository.current!.version,
      },
      stop: () async => true,
      reflect: () async {
        versions.add(repository.current!.version);
        return reflectOk;
      },
    );
    repository.coordinator = updates;
    addTearDown(repository.dispose);
    addTearDown(updates.dispose);
    expect(await repository.refresh(), DatasetRefreshResult.updated);
    expect(versions, ['v2']);
    expect(repository.current!.version, 'v2');
    expect(
      UpdateRecord.decode(journal.value).pending!.target['datasetVersion'],
      'v2',
    );
    reflectOk = true;
    expect(await updates.reconcile(), isTrue);
    expect(UpdateRecord.decode(journal.value).pending, isNull);
  });
  testWidgets(
    'an unconfirmed district never creates a plan from its candidate',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.confirm(
          DemoArea.a,
        ).encode(),
        NotificationStateStore.key: jsonEncode({
          'version': 1,
          'answered': true,
          'settings': const NotificationSettings(enabled: true).toJson(),
        }),
      });
      final notifications = FakeNotifications();
      await tester.pumpWidget(
        GomimapApp(
          preferences: await SharedPreferences.getInstance(),
          dataset: fixtureDataset(),
          updateJournal: MemoryUpdateJournal(),
          notificationsBridge: notifications,
          allowQaNotifications: true,
          clock: () => DateTime.utc(2026, 10, 4, 20),
        ),
      );
      await tester.pumpAndSettle();
      expect(notifications.plans, isNotEmpty);
      expect(
        notifications.plans.every((p) => (p['entries'] as List).isEmpty),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'startup replays pending language from committed preferences and offers retry only on failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'demo.area': 'a',
        'app.language': 'en',
      });
      final prefs = await SharedPreferences.getInstance();
      final data = fixtureDataset();
      final old = {...selection(), 'datasetVersion': data.version};
      final target = {...old, 'locale': 'en'};
      final journal = MemoryUpdateJournal()
        ..value = UpdateRecord(
          1,
          PendingUpdate(
            reason: 'language',
            previous: old,
            target: target,
            phase: 'stopped',
          ),
        ).encode();
      final bridge = FakeWidgetBridge()..save = false;
      final notifications = FakeNotifications();
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          dataset: data,
          updateJournal: journal,
          widgetBridge: bridge,
          notificationsBridge: notifications,
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Burnable waste'), findsOneWidget);
      expect(UpdateRecord.decode(journal.value).pending, isNotNull);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(
        find.text('Notifications or widgets could not be updated.'),
        findsOneWidget,
      );
      bridge.save = true;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(UpdateRecord.decode(journal.value).pending, isNull);
      expect(
        find.text('Notifications or widgets could not be updated.'),
        findsNothing,
      );
      expect(bridge.snapshots, isNotEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
