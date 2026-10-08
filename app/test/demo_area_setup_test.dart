// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';

import 'support/dataset_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/l10n/generated/app_localizations.dart';
import 'package:gomimap/l10n/languages.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/ui/demo_area_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ControlledSetupStore implements DemoSetupStore {
  ControlledSetupStore(this.snapshot);
  DemoSetupSnapshot snapshot;
  bool succeeds = true;
  int calls = 0;
  Completer<bool>? pending;
  @override
  DemoSetupSnapshot read() => snapshot;
  @override
  Future<bool> save(DemoSetupSnapshot next) async {
    calls++;
    final result = await (pending?.future ?? Future.value(succeeds));
    if (result) snapshot = next;
    return result;
  }
}

Future<SharedPreferences> launchSetup(
  WidgetTester tester, {
  String language = 'ja',
  double scale = 1,
  DemoSetupStore? store,
  Map<String, Object> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues({'app.language': language, ...saved});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    GomimapApp(
      displayDate: DateTime(2026, 10, 5),
      preferences: prefs,
      setupStore: store,
      dataset: fixtureDataset(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

Future<void> choose(WidgetTester tester, String area) async {
  final button = find.byKey(ValueKey('choose-area-$area'));
  await tester.scrollUntilVisible(button, 160);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('confirm-area-save'));
  await tester.scrollUntilVisible(button, 160);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'successful correction does not flash the picker during the outgoing animation',
    (tester) async {
      final store = ControlledSetupStore(
        const DemoSetupSnapshot.saved(DemoArea.a),
      );
      await launchSetup(tester, store: store);
      await tester.tap(find.byKey(const ValueKey('collection-area-context')));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      await tester.tap(find.byKey(const ValueKey('confirm-area-save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('サンプル地区を設定'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('収集地区：豊島区・サンプル地域B'), findsOneWidget);
      expect(store.calls, 1);
    },
  );
  testWidgets('first launch requires explicit district confirmation', (
    tester,
  ) async {
    final prefs = await launchSetup(tester);
    expect(find.text('サンプル地区を設定'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
    expect(PreferencesDemoSetupStore(prefs).read().area, isNull);
    await choose(tester, 'b');
    expect(find.text('この地区でよいですか？'), findsOneWidget);
    expect(
      PreferencesDemoSetupStore(prefs).read().phase,
      DemoSetupPhase.confirm,
    );
    expect(find.byType(HomeShell), findsNothing);
    await save(tester);
    expect(find.text('収集地区：豊島区・サンプル地域B'), findsOneWidget);
    expect(
      PreferencesDemoSetupStore(prefs).read().phase,
      DemoSetupPhase.districtSaved,
    );
  });

  testWidgets(
    'restart resumes an unanswered confirmation, then opens Today after save',
    (tester) async {
      final prefs = await launchSetup(tester);
      await choose(tester, 'b');
      await tester.pumpWidget(const SizedBox());
      await prefs.reload();
      await tester.pumpWidget(
        GomimapApp(
          displayDate: DateTime(2026, 10, 5),
          preferences: prefs,
          dataset: fixtureDataset(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('設定する地区：豊島区・サンプル地域B'), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      await save(tester);
      await tester.pumpWidget(const SizedBox());
      await prefs.reload();
      await tester.pumpWidget(
        GomimapApp(
          displayDate: DateTime(2026, 10, 5),
          preferences: prefs,
          dataset: fixtureDataset(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(DemoAreaSetup), findsNothing);
    },
  );

  testWidgets('first-time Back and choosing again do not confirm a candidate', (
    tester,
  ) async {
    final prefs = await launchSetup(tester);
    await choose(tester, 'a');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('サンプル地区を設定'), findsOneWidget);
    expect(PreferencesDemoSetupStore(prefs).read().area, isNull);
    await choose(tester, 'b');
    await tester.tap(find.text('選び直す'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsNothing);
    await choose(tester, 'a');
    await save(tester);
    expect(find.text('収集地区：豊島区・サンプル地域A'), findsOneWidget);
  });

  testWidgets(
    'cancel an edited candidate without changing the saved district',
    (tester) async {
      final store = ControlledSetupStore(
        const DemoSetupSnapshot.saved(DemoArea.a),
      );
      await launchSetup(tester, store: store);
      await tester.tap(find.byKey(const ValueKey('collection-area-context')));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      expect(find.text('現在の設定：豊島区・サンプル地域A'), findsOneWidget);
      expect(store.calls, 0);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(store.read().area, DemoArea.a);
      expect(find.text('収集地区：豊島区・サンプル地域A'), findsOneWidget);
    },
  );

  testWidgets(
    'failed initial candidate write stays on selection and can retry',
    (tester) async {
      final store = ControlledSetupStore(const DemoSetupSnapshot.choose())
        ..succeeds = false;
      await launchSetup(tester, store: store);
      await choose(tester, 'b');
      expect(find.text('サンプル地区を設定'), findsOneWidget);
      expect(find.textContaining('保存できませんでした'), findsOneWidget);
      expect(store.read().area, isNull);
      store.succeeds = true;
      await choose(tester, 'b');
      await save(tester);
      expect(find.text('収集地区：豊島区・サンプル地域B'), findsOneWidget);
    },
  );

  testWidgets(
    'failed correction stays recoverable and only success changes Today',
    (tester) async {
      final store = ControlledSetupStore(
        const DemoSetupSnapshot.saved(DemoArea.a),
      )..succeeds = false;
      await launchSetup(tester, store: store);
      await tester.tap(find.byKey(const ValueKey('collection-area-context')));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      await save(tester);
      expect(find.textContaining('保存できませんでした'), findsOneWidget);
      expect(store.read().area, DemoArea.a);
      expect(find.text('この地区でよいですか？'), findsOneWidget);
      store.succeeds = true;
      await save(tester);
      expect(store.read().area, DemoArea.b);
      expect(find.text('収集地区：豊島区・サンプル地域B'), findsOneWidget);
    },
  );

  testWidgets('pending save disables duplicate requests and navigation', (
    tester,
  ) async {
    final store = ControlledSetupStore(
      const DemoSetupSnapshot.confirm(DemoArea.b),
    )..pending = Completer<bool>();
    await launchSetup(tester, store: store);
    final button = find.byKey(const ValueKey('confirm-area-save'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(store.calls, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.text('保存しています…'), findsOneWidget);
    expect(store.read().phase, DemoSetupPhase.confirm);
    store.pending!.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('language can be changed before choosing a district', (
    tester,
  ) async {
    final prefs = await launchSetup(tester);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'English'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set a demo district'), findsOneWidget);
    expect(prefs.getString('app.language'), 'en');
    await choose(tester, 'b');
    expect(find.text('Use this district?'), findsOneWidget);
  });

  testWidgets(
    'failed save remains visible at double text size and keeps the current district fixed',
    (tester) async {
      final store = ControlledSetupStore(
        const DemoSetupSnapshot.saved(DemoArea.a),
      )..succeeds = false;
      await launchSetup(tester, store: store, scale: 2);
      await tester.tap(find.byKey(const ValueKey('collection-area-context')));
      await tester.pumpAndSettle();
      final current = find.byKey(const ValueKey('setup-current-area'));
      final position = tester.getTopLeft(current);
      await choose(tester, 'b');
      await save(tester);
      expect(tester.getTopLeft(current), position);
      final error = find.byKey(const ValueKey('setup-save-status'));
      expect(tester.getRect(error).bottom, lessThanOrEqualTo(844));
      expect(tester.getRect(error).top, greaterThan(0));
      expect(store.read().area, DemoArea.a);
      expect(tester.takeException(), isNull);
      final cancel = find.text('キャンセル');
      await tester.scrollUntilVisible(cancel, 160);
      await tester.pumpAndSettle();
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.text('収集地区：豊島区・サンプル地域A'), findsOneWidget);
    },
  );

  testWidgets('corrupt settings explain recovery without choosing a default', (
    tester,
  ) async {
    await launchSetup(
      tester,
      saved: {PreferencesDemoSetupStore.key: 'bad-json', 'demo.area': 'a'},
    );
    expect(find.textContaining('地区の設定を読み込めませんでした'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
  });

  for (final language in languageNames.keys) {
    testWidgets('$language first-time screens remain operable at 200% text', (
      tester,
    ) async {
      await launchSetup(tester, language: language, scale: 2);
      await choose(tester, 'b');
      expect(tester.takeException(), isNull);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DemoAreaSetup)),
      );
      final again = find.text(l10n.chooseAgain);
      await tester.scrollUntilVisible(again, 160);
      await tester.pumpAndSettle();
      await tester.tap(again);
      await tester.pumpAndSettle();
      await choose(tester, 'a');
      await save(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
