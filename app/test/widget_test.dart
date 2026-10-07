// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'support/dataset_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/ui/collection_map.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/domain/municipal_dataset.dart';

Future<SharedPreferences> start(
  WidgetTester tester, {
  double scale = 1,
  bool missingData = false,
  MunicipalDataset? dataset,
}) async {
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
  await tester.pumpWidget(
    GomimapApp(
      preferences: prefs,
      dataset: missingData ? null : dataset ?? fixtureDataset(),
    ),
  );
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
  testWidgets('today shows the JSON deadline directly', (tester) async {
    await start(tester);
    final today = find.byKey(const ValueKey('today-schedule'));
    expect(
      find.descendant(of: today, matching: find.text('出す時間：08:00まで')),
      findsOneWidget,
    );
  });
  testWidgets(
    'different category deadlines remain distinct and common deadlines are shown once',
    (tester) async {
      final data = fixtureDataset((json) {
        json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
        json['baselines'][1]['recurrences'][0]['deadline'] = '09:30';
      });
      await start(tester, dataset: data);
      expect(find.text('燃やすごみ：08:00まで'), findsOneWidget);
      expect(find.text('資源：09:30まで'), findsOneWidget);
      final common = fixtureDataset((json) {
        json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(GomimapApp(preferences: prefs, dataset: common));
      await tester.pumpAndSettle();
      expect(find.text('出す時間：08:00まで'), findsOneWidget);
      expect(find.text('燃やすごみ：08:00まで'), findsNothing);
    },
  );
  testWidgets(
    'direct locations require an explicit item and retain it across tabs',
    (tester) async {
      await start(tester);
      await tab(tester, '資源回収場所');
      expect(find.text('持ち込む品物の種類を選んでください。'), findsOneWidget);
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .every((chip) => !chip.selected),
        isTrue,
      );
      expect(find.byType(CollectionMap), findsNothing);
      expect(find.byKey(const ValueKey('return-to-item')), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '乾電池'));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionMap), findsOneWidget);
      await tab(tester, '今日');
      await tab(tester, '資源回収場所');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '乾電池'))
            .selected,
        isTrue,
      );
      expect(find.byKey(const ValueKey('return-to-item')), findsNothing);
    },
  );
  testWidgets('item, point and settings have a visible close operation', (
    tester,
  ) async {
    await start(tester);
    await tab(tester, '分別を調べる');
    await tester.enterText(find.byType(TextField), 'ペット');
    await tester.tap(find.text('ペットボトル'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ペット',
    );
    await tab(tester, '資源回収場所');
    await tester.tap(find.widgetWithText(ChoiceChip, '乾電池'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('サンプル回収拠点A'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('サンプル回収拠点A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byTooltip('この試作について'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
  testWidgets(
    'map returns to the original item and restores its answer after another filter',
    (tester) async {
      await start(tester);
      await tab(tester, '分別を調べる');
      await tester.enterText(find.byType(TextField), '充電池');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ListTile, '充電池'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '充電池'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('専用の回収場所を探す'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'ある・わからない'));
      await tester.pumpAndSettle();
      expect(find.text('回収場所の一覧（サンプル 0件）'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '蛍光灯'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('return-to-item')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('充電池'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '充電池',
      );
      await tester.tap(find.text('専用の回収場所を探す'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '充電池'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'ある・わからない'))
            .selected,
        isTrue,
      );
      expect(find.byType(CollectionMap), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('充電池'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pumpAndSettle();
      await tab(tester, '資源回収場所');
      expect(find.byKey(const ValueKey('return-to-item')), findsNothing);
    },
  );
  testWidgets('new controls remain usable at double text size', (tester) async {
    await start(tester, scale: 2);
    await tab(tester, '分別を調べる');
    await tester.scrollUntilVisible(
      find.byType(TextField),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '蛍光灯');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, '蛍光灯'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '蛍光灯'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('専用の回収場所を探す'),
      150,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('専用の回収場所を探す'));
    await tester.pumpAndSettle();
    final back = find.byKey(const ValueKey('return-to-item'));
    await tester.scrollUntilVisible(back, -150);
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final close = find.byKey(const ValueKey('sheet-close'));
    await tester.scrollUntilVisible(
      close,
      -150,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
  testWidgets(
    'category without a verified common translation preserves its source name',
    (tester) async {
      final data = fixtureDataset((json) {
        json['categories'][0].remove('displayKey');
        json['categories'][0]['name'] = '試験用の独自区分';
      });
      await start(tester, dataset: data);
      final today = find.byKey(const ValueKey('today-schedule'));
      expect(
        find.descendant(of: today, matching: find.text('試験用の独自区分')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: today, matching: find.text('燃やすごみ')),
        findsNothing,
      );
    },
  );
  testWidgets(
    'missing dataset displays confirmation instead of a default schedule',
    (tester) async {
      await start(tester, missingData: true);
      final today = find.byKey(const ValueKey('today-schedule'));
      expect(
        find.descendant(of: today, matching: find.text('収集予定の確認が必要')),
        findsOneWidget,
      );
      expect(find.text('燃やすごみ'), findsNothing);
      expect(find.text('収集はありません'), findsNothing);
      expect(
        find.descendant(of: today, matching: find.text('公式情報を確認')),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'home uses the validated JSON schedule rather than the former hardcoded weekdays',
    (tester) async {
      final data = fixtureDataset((json) {
        json['baselines'][0]['recurrences'][0]['weekdays'] = [2, 5];
        json['baselines'][1]['recurrences'][0]['weekdays'] = [1];
      });
      await start(tester, dataset: data);
      final today = find.byKey(const ValueKey('today-schedule'));
      expect(
        find.descendant(of: today, matching: find.text('資源')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: today, matching: find.text('燃やすごみ')),
        findsNothing,
      );
    },
  );
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
    await tester.pumpWidget(
      GomimapApp(preferences: prefs, dataset: fixtureDataset()),
    );
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
