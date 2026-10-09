// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/notifications/notification_bridge.dart';
import 'package:gomimap/notifications/notification_controller.dart';
import 'package:gomimap/notifications/notification_state.dart';
import 'package:gomimap/widgets/widget_offer_store.dart';
import 'package:gomimap/ui/notification_settings.dart';
import 'package:gomimap/l10n/languages.dart';

import 'support/dataset_fixture.dart';
import 'home_widget_flow_test.dart' show FakeWidgetBridge;

class FakeNotifications implements NotificationsBridge {
  bool stop = true, applyOk = true;
  String permission = 'denied';
  int requests = 0, pauses = 0;
  int nextDue = 0;
  final plans = <Map<String, Object?>>[];
  void Function(Map<String, dynamic>)? open;
  @override
  bool get available => true;
  @override
  Future<Map<String, dynamic>> status() async => {
    'permission': permission,
    'count': permission == 'allowed' && plans.isNotEmpty
        ? (plans.last['entries'] as List).length
        : 0,
    'preview': false,
    'planCount': 0,
    'nextDue': nextDue,
  };
  @override
  Future<String> requestPermission() async {
    requests++;
    return permission;
  }

  @override
  Future<bool> pause() async {
    pauses++;
    return stop;
  }

  @override
  Future<bool> apply(Map<String, Object?> plan) async {
    plans.add(plan);
    return applyOk;
  }

  @override
  Future<bool> test() async => false;
  @override
  Future<void> openSettings() async {}
  @override
  Future<Map<String, dynamic>?> consumeLaunch() async => null;
  @override
  void onOpen(void Function(Map<String, dynamic>) handler) {
    open = handler;
  }
}

class RejectNotificationStore extends NotificationStateStore {
  RejectNotificationStore(super.preferences) : super(legacyDistrictSaved: true);
  @override
  Future<bool> save(
    NotificationSettings desired, {
    required bool answer,
  }) async => false;
}

void main() {
  test(
    'unsupported notification platforms do not call the launch channel',
    () async {
      final bridge = AndroidNotificationsBridge();
      bridge.onOpen((_) => fail('Unavailable bridge emitted a launch'));
      expect(bridge.available, isFalse);
      expect(await bridge.consumeLaunch(), isNull);
    },
  );
  for (final code in languageNames.keys) {
    testWidgets('notification settings $code stay usable at 200% text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'app.language': code,
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          dataset: fixtureDataset(),
          notificationsBridge: FakeNotifications(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      final button = find.byIcon(Icons.notifications_outlined);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationSettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      final save = find.byType(FilledButton);
      await tester.scrollUntilVisible(save, 200, maxScrolls: 20);
      expect(save, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
  test('failed cancellation prevents a settings commit; failed write restores the old plan', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bridge = FakeNotifications()..stop = false;
    final store = NotificationStateStore(prefs, legacyDistrictSaved: true);
    Map<String, Object?> build(NotificationSettings s) => {
      'enabled': s.enabled,
      'entries': [],
    };
    final controller = NotificationController(
      store: store,
      bridge: bridge,
      plan: build,
    );
    expect(
      await controller.save(
        const NotificationSettings(enabled: true),
        answer: true,
      ),
      isFalse,
    );
    expect(store.settings.enabled, isFalse);
    expect(bridge.plans, isEmpty);
    bridge.stop = true;
    final rejected = NotificationController(
      store: RejectNotificationStore(prefs),
      bridge: bridge,
      plan: build,
    );
    expect(
      await rejected.save(
        const NotificationSettings(enabled: true),
        answer: true,
      ),
      isFalse,
    );
    expect(bridge.plans.last['enabled'], isFalse);
    expect(rejected.failed, isTrue);
    controller.dispose();
    rejected.dispose();
  });
  test('a committed setting is retained if OS application fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bridge = FakeNotifications()..applyOk = false;
    final store = NotificationStateStore(prefs, legacyDistrictSaved: true);
    final c = NotificationController(
      store: store,
      bridge: bridge,
      plan: (s) => {'entries': []},
    );
    expect(
      await c.save(const NotificationSettings(enabled: true), answer: true),
      isTrue,
    );
    expect(store.settings.enabled, isTrue);
    expect(c.failed, isTrue);
    c.dispose();
  });
  test('a district cannot commit if old notifications cannot stop', () async {
    SharedPreferences.setMockInitialValues({
      PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
          .encode(),
    });
    final prefs = await SharedPreferences.getInstance();
    final bridge = FakeNotifications()..stop = false;
    final c = NotificationController(
      store: NotificationStateStore(prefs, legacyDistrictSaved: true),
      bridge: bridge,
      plan: (s) => {'entries': []},
    );
    final store = NotificationSetupStore(PreferencesDemoSetupStore(prefs), c);
    expect(
      await store.save(const DemoSetupSnapshot.saved(DemoArea.b)),
      isFalse,
    );
    expect(store.read().area, DemoArea.a);
    c.dispose();
  });
  testWidgets(
    'first notification offer can be skipped without OS permission and never repeats',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
        WidgetOfferStore.key: true,
        NotificationStateStore.key: '{"version":1,"answered":false,"settings":{"enabled":false,"morningMinute":360,"eveningEnabled":false,"eveningMinute":1200}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifications = FakeNotifications();
      Widget app() => GomimapApp(
        preferences: prefs,
        dataset: fixtureDataset(),
        widgetBridge: FakeWidgetBridge(),
        notificationsBridge: notifications,
        displayDate: DateTime(2026, 10, 5),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('ごみの日を通知'), findsWidgets);
      await tester.tap(find.text('あとで'));
      await tester.pumpAndSettle();
      expect(notifications.requests, 0);
      expect(find.byType(HomeShell), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('あとで'), findsNothing);
    },
  );
  testWidgets(
    'legacy settings preserve desired on while permission denied; cancel does not save a draft',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final bridge = FakeNotifications()
        ..nextDue = DateTime.utc(2026, 10, 6, 21).millisecondsSinceEpoch;
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          dataset: fixtureDataset(),
          notificationsBridge: bridge,
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ごみの日の通知'));
      await tester.tap(find.text('ごみの日の通知'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(
        NotificationStateStore(
          prefs,
          legacyDistrictSaved: true,
        ).settings.enabled,
        isTrue,
      );
      expect(find.text('端末で通知が許可されていません'), findsOneWidget);
      expect(find.textContaining('次の予定：'), findsNothing);
      expect(bridge.requests, 1);
      expect(bridge.plans.last['entries'], isEmpty);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(
        NotificationStateStore(
          prefs,
          legacyDistrictSaved: true,
        ).settings.enabled,
        isTrue,
      );
    },
  );
}
