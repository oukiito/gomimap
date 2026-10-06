// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/ui/collection_map.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';

Future<SharedPreferences> start(WidgetTester tester, {double scale = 1}) async {
  SharedPreferences.setMockInitialValues({
    'app.language': 'ja',
    PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
        .encode(),
  });
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(GomimapApp(preferences: prefs));
  await tester.pumpAndSettle();
  return prefs;
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(of: find.byType(NavigationBar), matching: find.text(label))
        .last,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('collection area stays visible while scrolling every main tab', (
    tester,
  ) async {
    await start(tester);
    final area = find.byKey(const ValueKey('collection-area-context'));
    for (final label in ['今日', '分別を調べる', '資源回収場所']) {
      await tab(tester, label);
      final position = tester.getTopLeft(area);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(area.hitTestable(), findsOneWidget);
      expect(tester.getTopLeft(area), position);
      expect(find.text('収集地区：豊島区・サンプル地域A'), findsOneWidget);
    }
  });
  testWidgets('area can be corrected from search without losing the query', (
    tester,
  ) async {
    final prefs = await start(tester);
    await tab(tester, '分別を調べる');
    await tester.enterText(find.byType(TextField), 'ペット');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-area-context')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('豊島区・サンプル地域B'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-area-save')));
    await tester.pumpAndSettle();
    expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.b);
    expect(find.text('収集地区：豊島区・サンプル地域B'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ペット',
    );
    await tester.tap(find.text('ペットボトル'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('収集地区：豊島区・サンプル地域B'),
      ),
      findsOneWidget,
    );
  });
  testWidgets(
    'settings allows correction and cancellation keeps the old area',
    (tester) async {
      final prefs = await start(tester);
      await tester.tap(find.byTooltip('この試作について'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '地域を選ぶ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('豊島区・サンプル地域B'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-area-save')));
      await tester.pumpAndSettle();
      expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.b);
      await tester.tap(find.byKey(const ValueKey('collection-area-context')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.b);
      expect(find.text('収集地区：豊島区・サンプル地域B'), findsOneWidget);
    },
  );
  testWidgets('home labels sample data and retains selected area on restart', (
    tester,
  ) async {
    final prefs = await start(tester);
    expect(find.textContaining('実際のごみ出しには使えません'), findsOneWidget);
    expect(find.text('燃やすごみ'), findsOneWidget);
    await tester.tap(find.textContaining('サンプル地域A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('豊島区・サンプル地域B'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-area-save')));
    await tester.pumpAndSettle();
    expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.b);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(GomimapApp(preferences: prefs));
    await tester.pumpAndSettle();
    expect(find.textContaining('サンプル地域B'), findsOneWidget);
  });
  testWidgets('unknown day offers official information', (tester) async {
    await start(tester);
    await tester.scrollUntilVisible(find.text('収集予定の確認が必要'), 220);
    expect(find.text('公式情報を確認'), findsOneWidget);
  });
  testWidgets('ordinary recyclables have no map link', (tester) async {
    await start(tester);
    await tab(tester, '分別を調べる');
    await tester.enterText(find.byType(TextField), 'ペット');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ペットボトル'));
    await tester.pumpAndSettle();
    expect(find.text('公式の出し方を確認'), findsOneWidget);
    expect(find.text('専用の回収場所を探す'), findsNothing);
  });
  testWidgets('search leads to special-item map and filters locations', (
    tester,
  ) async {
    await start(tester);
    await tab(tester, '分別を調べる');
    await tester.enterText(find.byType(TextField), 'けいこうとう');
    await tester.pumpAndSettle();
    await tester.tap(find.text('蛍光灯'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('専用の回収場所を探す'));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionMap), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'ペットボトル'), findsNothing);
    final map = tester.widget<CollectionMap>(find.byType(CollectionMap));
    expect(map.points.map((point) => point.id), ['b']);
    expect(find.textContaining('地図はまだ接続していません'), findsOneWidget);
  });
  testWidgets(
    'unknown or damaged batteries never show ordinary box locations',
    (tester) async {
      await start(tester);
      await tab(tester, '資源回収場所');
      await tester.tap(find.widgetWithText(ChoiceChip, '充電池'));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionMap), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'ある・わからない'));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionMap), findsNothing);
      expect(find.textContaining('通常の回収箱へは案内しません'), findsOneWidget);
    },
  );
  testWidgets(
    'narrow screen with double text size remains usable across tabs',
    (tester) async {
      await start(tester, scale: 2);
      expect(tester.takeException(), isNull);
      await tab(tester, '分別を調べる');
      expect(tester.takeException(), isNull);
      await tab(tester, '資源回収場所');
      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
