// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/main.dart';

import 'support/dataset_fixture.dart';

void main() {
  for (final language in ['ja', 'en']) {
    testWidgets(
      'automation keeps $language readable date/category and menu action',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          SharedPreferences.setMockInitialValues({
            'app.language': language,
            PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(
              DemoArea.a,
            ).encode(),
          });
          final preferences = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            GomimapApp(
              preferences: preferences,
              dataset: fixtureDataset(),
              displayDate: DateTime(2026, 10, 5),
            ),
          );
          await tester.pumpAndSettle();
          Finder identifier(String id) => find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.identifier == id,
          );
          final dateNode = tester.getSemantics(
            identifier('schedule-primary-date'),
          );
          final descriptionNode = tester.getSemantics(
            identifier('schedule-primary-description'),
          );
          final date = dateNode.getSemanticsData();
          final description = descriptionNode.getSemanticsData();
          final menu = tester
              .getSemantics(identifier('language-menu'))
              .getSemanticsData();
          expect(date.label, contains(language == 'ja' ? '今日' : 'Today'));
          expect(
            description.label,
            language == 'ja' ? '燃やすごみ' : 'Burnable waste',
          );
          expect('${menu.label} ${menu.tooltip}', contains('Language'));
          expect(menu.hasAction(SemanticsAction.tap), true);
          expect(dateNode.id, isNot(descriptionNode.id));
        } finally {
          handle.dispose();
        }
      },
    );
  }
}
