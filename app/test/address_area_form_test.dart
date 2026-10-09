// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/l10n/generated/app_localizations.dart';
import 'package:gomimap/l10n/languages.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/ui/address_area_form.dart';

import 'support/dataset_fixture.dart';

Future<void> choose(WidgetTester tester, Object value) async {
  final dropdown = find
      .byWidgetPredicate(
        (w) =>
            w is DropdownButton<Object> &&
            w.items!.any((i) => i.value == value) &&
            w.value != value,
      )
      .last;
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final option = find
      .byWidgetPredicate(
        (w) => w is DropdownMenuItem<Object> && w.value == value,
      )
      .last;
  final text = find.descendant(of: option, matching: find.byType(Text)).last;
  await tester.ensureVisible(text);
  await tester.tap(text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'address candidate still needs confirmation; cancel preserves the old district and no answers persist',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        GomimapApp(
          preferences: prefs,
          dataset: fixtureDataset(),
          displayDate: DateTime(2026, 10, 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('collection-area-context')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('住所から選ぶ'));
      await tester.tap(find.text('住所から選ぶ'));
      await tester.pumpAndSettle();
      await choose(tester, '架空町');
      await choose(tester, 1);
      await tester.enterText(find.byType(TextField), '12');
      await tester.pumpAndSettle();
      await choose(tester, 'along');
      await tester.ensureVisible(find.text('この地区を確認する'));
      await tester.tap(find.text('この地区を確認する'));
      await tester.pumpAndSettle();
      expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.a);
      expect(find.text('設定する地区：豊島区・サンプル地域B'), findsOneWidget);
      await tester.ensureVisible(find.text('キャンセル'));
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(PreferencesDemoSetupStore(prefs).read().area, DemoArea.a);
      expect(prefs.getKeys().any((key) => key.startsWith('address.')), isFalse);
    },
  );
  testWidgets(
    'unknown and unsupported answers cannot enable confirmation; correcting upper fields clears lower answers',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: AddressAreaForm(
            dataset: fixtureDataset(),
            date: CalendarDate(2026, 10, 5),
            onCandidate: (id) => selected = id,
            onLanguageChanged: (_) async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await choose(tester, '架空町');
      await choose(tester, 1);
      await tester.enterText(find.byType(TextField), '999');
      await tester.pumpAndSettle();
      expect(find.text('対応する収集地区が見つかりません'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '12');
      await tester.pumpAndSettle();
      await choose(tester, 'away');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      final first = find.byType(DropdownButton<Object>).first;
      await Scrollable.ensureVisible(tester.element(first), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('わからない').last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(selected, isNull);
    },
  );
  for (final code in languageNames.keys) {
    testWidgets(
      'address form $code remains usable at 200% text without preselecting',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: savedLocale(code),
            home: AddressAreaForm(
              dataset: fixtureDataset(),
              date: CalendarDate(2026, 10, 5),
              onCandidate: (_) {},
              onLanguageChanged: (_) async => true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButton<Object>>(
                find.byType(DropdownButton<Object>),
              )
              .value,
          isNull,
        );
        await tester.scrollUntilVisible(
          find.byType(FilledButton),
          200,
          maxScrolls: 20,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
