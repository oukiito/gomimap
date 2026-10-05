// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/l10n/languages.dart';
import 'package:gomimap/l10n/generated/app_localizations.dart';
import 'package:gomimap/l10n/presentation.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> launch(
  WidgetTester tester, {
  String? saved = 'ja',
  Locale device = const Locale('en', 'US'),
  double scale = 1,
}) async {
  SharedPreferences.setMockInitialValues({'app.language': ?saved});
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.localesTestValue = [device];
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(GomimapApp(preferences: preferences));
  await tester.pumpAndSettle();
  return preferences;
}

Future<void> chooseLanguage(WidgetTester tester, String language) async {
  await tester.tap(find.byIcon(Icons.language));
  await tester.pumpAndSettle();
  final option = find.widgetWithText(CheckedPopupMenuItem<String>, language);
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> selectTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('all translations cover the same messages and placeholder tokens', () {
    final ja = jsonDecode(
      File('lib/l10n/app_ja.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final keys = ja.keys.where((key) => !key.startsWith('@')).toSet();
    for (final file in Directory('lib/l10n').listSync().whereType<File>().where(
      (file) => file.path.endsWith('.arb'),
    )) {
      final translated =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(
        translated.keys.where((key) => !key.startsWith('@')).toSet(),
        keys,
        reason: file.path,
      );
      for (final key in keys) {
        expect(translated[key], isNotEmpty, reason: '${file.path}: $key');
        expect(
          translated['@$key'],
          ja['@$key'],
          reason: 'placeholder metadata for $key',
        );
        final tokens = RegExp(r'\{[a-zA-Z]+\}');
        expect(
          tokens
              .allMatches(translated[key] as String)
              .map((m) => m.group(0))
              .toSet(),
          tokens.allMatches(ja[key] as String).map((m) => m.group(0)).toSet(),
          reason: '${file.path}: $key',
        );
      }
    }
  });

  test('Chinese region and script resolution, Tagalog alias and fallback', () {
    for (final region in ['TW', 'HK', 'MO']) {
      expect(
        resolveAppLocale([Locale('zh', region)], appLocales).toLanguageTag(),
        'zh-Hant',
      );
    }
    expect(
      resolveAppLocale([const Locale('zh', 'CN')], appLocales).toLanguageTag(),
      'zh-Hans',
    );
    expect(
      resolveAppLocale([
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'TW',
        ),
      ], appLocales).toLanguageTag(),
      'zh-Hans',
    );
    expect(
      resolveAppLocale([
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'CN',
        ),
      ], appLocales).toLanguageTag(),
      'zh-Hant',
    );
    expect(
      resolveAppLocale([const Locale('tl', 'PH')], appLocales).languageCode,
      'fil',
    );
    expect(
      resolveAppLocale([
        const Locale('fr'),
        const Locale('vi'),
      ], appLocales).languageCode,
      'vi',
    );
    expect(
      resolveAppLocale([const Locale('fr')], appLocales).languageCode,
      'ja',
    );
    expect(savedLocale('zh_Hant')?.scriptCode, 'Hant');
  });

  for (final code in languageNames.keys) {
    testWidgets(
      '$code renders all screens at double text size and searches local item names',
      (tester) async {
        await launch(tester, saved: code, scale: 2);
        final context = tester.element(find.byType(HomeShell));
        final l10n = AppLocalizations.of(context);
        expect(Localizations.localeOf(context).toLanguageTag(), code);
        expect(find.text(l10n.burnable), findsOneWidget);
        expect(tester.takeException(), isNull);
        await selectTab(tester, l10n.searchTab);
        await tester.scrollUntilVisible(
          find.byType(TextField),
          180,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), l10n.pet);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ListTile, l10n.pet), findsOneWidget);
        expect(tester.takeException(), isNull);
        await selectTab(tester, l10n.placesTab);
        await tester.scrollUntilVisible(find.text(l10n.mapTitle), 200);
        expect(find.text(l10n.mapTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'local battery aliases remain searchable in any display language',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ja'));
      for (final query in [
        '电池',
        '電池',
        '건전지',
        'pin',
        'ब्याट्री',
        'pilha',
        'pila',
        'baterya',
      ]) {
        expect(
          sortingItems.where((item) => item.matches(query, l10n)),
          isNotEmpty,
          reason: query,
        );
      }
    },
  );

  testWidgets(
    'traditional Chinese selection persists after restarting the app',
    (tester) async {
      final preferences = await launch(tester);
      await chooseLanguage(tester, '繁體中文');
      expect(preferences.getString('app.language'), 'zh-Hant');
      expect(find.text('可燃垃圾'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(GomimapApp(preferences: preferences));
      await tester.pumpAndSettle();
      expect(
        Localizations.localeOf(tester.element(find.byType(HomeShell)))
            .scriptCode,
        'Hant',
      );
    },
  );

  testWidgets('last language in the scrollable menu can be selected', (
    tester,
  ) async {
    final preferences = await launch(tester, scale: 2);
    await chooseLanguage(tester, 'Filipino / Tagalog');
    expect(preferences.getString('app.language'), 'fil');
    expect(find.text('Nasusunog na basura'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'language icon switches all home content and persists across restart',
    (tester) async {
      final preferences = await launch(tester);
      expect(find.byTooltip('言語 / Language'), findsOneWidget);
      expect(find.text('資源回収場所'), findsOneWidget);
      await chooseLanguage(tester, 'English');
      expect(find.text('Burnable waste'), findsOneWidget);
      expect(find.text('Recycling locations'), findsOneWidget);
      expect(find.textContaining('October 5, 2026'), findsOneWidget);
      expect(find.textContaining('Toshima · Sample area A'), findsOneWidget);
      expect(preferences.getString('app.language'), 'en');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(GomimapApp(preferences: preferences));
      await tester.pumpAndSettle();
      expect(find.text('Burnable waste'), findsOneWidget);
      await chooseLanguage(tester, '日本語');
      expect(find.text('燃やすごみ'), findsOneWidget);
    },
  );

  testWidgets('first launch follows supported device language', (tester) async {
    await launch(tester, saved: null);
    expect(find.text('Burnable waste'), findsOneWidget);
  });

  testWidgets('unsupported saved and device languages fall back to Japanese', (
    tester,
  ) async {
    await launch(tester, saved: 'invalid', device: const Locale('fr'));
    expect(find.text('燃やすごみ'), findsOneWidget);
  });

  testWidgets('English and Japanese searches work with localized details', (
    tester,
  ) async {
    await launch(tester, saved: 'en');
    await selectTab(tester, 'Sorting');
    await tester.enterText(find.byType(TextField), 'battery');
    await tester.pumpAndSettle();
    expect(find.text('Dry-cell batteries'), findsOneWidget);
    expect(find.text('Rechargeable batteries'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ペット');
    await tester.pumpAndSettle();
    await tester.tap(find.text('PET bottles'));
    await tester.pumpAndSettle();
    expect(
      find.text('Official disposal instructions (Japanese)'),
      findsOneWidget,
    );
    expect(find.text('Find collection locations'), findsNothing);
  });

  testWidgets(
    'changing language preserves the selected tab and battery condition',
    (tester) async {
      await launch(tester);
      await selectTab(tester, '資源回収場所');
      await tester.tap(find.widgetWithText(ChoiceChip, '充電池'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'ある・わからない'));
      await tester.pumpAndSettle();
      await chooseLanguage(tester, 'English');
      await tester.scrollUntilVisible(find.text('Yes / Not sure'), 180);
      expect(find.text('Is it swollen or damaged?'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Yes / Not sure'),
            )
            .selected,
        isTrue,
      );
      expect(
        find.textContaining('Do not use a regular collection box.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('English at double text size has no overflow across screens', (
    tester,
  ) async {
    await launch(tester, saved: 'en', scale: 2);
    expect(tester.takeException(), isNull);
    await selectTab(tester, 'Sorting');
    expect(tester.takeException(), isNull);
    await selectTab(tester, 'Recycling locations');
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
