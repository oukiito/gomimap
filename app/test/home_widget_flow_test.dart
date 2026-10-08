// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/widgets/widget_bridge.dart';
import 'package:gomimap/widgets/widget_offer_store.dart';
import 'package:gomimap/widgets/widget_setup_store.dart';
import 'package:gomimap/ui/widget_offer.dart';
import 'package:gomimap/l10n/languages.dart';

import 'support/dataset_fixture.dart';

class FakeWidgetBridge implements HomeWidgetBridge {
  final snapshots = <String>[];
  bool supported = true, accepted = true, added = false, save = true;
  int requests = 0;
  VoidCallback? open;
  @override
  bool get available => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> publish(String projection) async {
    if (save) snapshots.add(projection);
    return save;
  }

  @override
  Future<bool> pinSupported() async => supported;
  @override
  Future<bool> requestPin() async {
    requests++;
    return accepted;
  }

  @override
  Future<bool> isAdded() async => added;
  @override
  Future<bool> consumeLaunch() async => false;
  @override
  void setOpenTodayHandler(VoidCallback callback) {
    open = callback;
  }
}

void main() {
  for (final code in languageNames.keys) {
    testWidgets('widget offer $code remains usable at 200% text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        WidgetOfferStore.key: false,
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
          widgetBridge: FakeWidgetBridge(),
          dataset: fixtureDataset(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WidgetOffer), findsOneWidget);
      final skip = find.byKey(const ValueKey('widget-offer-skip'));
      await tester.scrollUntilVisible(skip, 250, maxScrolls: 20);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'first saved district shows one offer; skip persists and normal restart goes to today',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        WidgetOfferStore.key: false,
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final bridge = FakeWidgetBridge();
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          widgetBridge: bridge,
          dataset: fixtureDataset(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WidgetOffer), findsOneWidget);
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(bridge.requests, 0);
      expect(prefs.getBool(WidgetOfferStore.key), true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          widgetBridge: bridge,
          dataset: fixtureDataset(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WidgetOffer), findsNothing);
    },
  );
  testWidgets(
    'request acceptance is not placement and settings supports later retry',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final bridge = FakeWidgetBridge();
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          widgetBridge: bridge,
          dataset: fixtureDataset(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(HomeShell),
        findsOneWidget,
      ); // legacy user gets no surprise offer
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ホーム画面ウィジェット'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('追加する'));
      await tester.pumpAndSettle();
      expect(bridge.requests, 1);
      expect(find.text('ホーム画面に追加されています'), findsNothing);
      expect(find.text('追加を要求しました。OSの確認で追加してください。'), findsOneWidget);
      expect(bridge.snapshots, isNotEmpty);
    },
  );
  testWidgets(
    'failed snapshot save sends no OS request and keeps the offer retryable',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        WidgetOfferStore.key: false,
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final bridge = FakeWidgetBridge()..save = false;
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          widgetBridge: bridge,
          dataset: fixtureDataset(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('追加する'));
      await tester.pumpAndSettle();
      expect(bridge.requests, 0);
      expect(prefs.getBool(WidgetOfferStore.key), false);
      expect(find.byType(WidgetOffer), findsOneWidget);
    },
  );
  test('pending marker is committed before the first district and resumes after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final offer = WidgetOfferStore(prefs, legacyDistrictSaved: false);
    final store = WidgetSetupStore(PreferencesDemoSetupStore(prefs), offer);
    expect(await store.save(const DemoSetupSnapshot.saved(DemoArea.a)), true);
    expect(prefs.getBool(WidgetOfferStore.key), false);
    expect(WidgetOfferStore(prefs, legacyDistrictSaved: true).answered, false);
    expect(await offer.answer(), true);
    expect(WidgetOfferStore(prefs, legacyDistrictSaved: true).answered, true);
  });
}
