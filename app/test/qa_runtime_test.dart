// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/data/demo_setup_store.dart';
import 'package:gomimap/domain/calendar_date.dart';
import 'package:gomimap/domain/schedule_focus.dart';
import 'package:gomimap/main.dart';
import 'package:gomimap/qa/qa_runtime.dart';

import 'home_widget_flow_test.dart' show FakeWidgetBridge;
import 'support/dataset_fixture.dart';

void main() {
  String source() => File(fixturePath).readAsStringSync();
  Map<String, Object> state(
    DateTime date,
    int revision, [
    String scenario = 'tomorrow',
  ]) => {
    'package': qaPackage,
    'millis': date.millisecondsSinceEpoch,
    'revision': revision,
    'scenario': scenario,
  };

  test('normal Dart builds leave the QA entry disabled', () {
    expect(qaBuild, isFalse);
  });
  test('QA data refuses an unexpected source namespace or revision', () {
    for (final field in ['kind', 'version']) {
      final value = fixtureJson()..[field] = 'unexpected';
      expect(
        () => qaDataset(jsonEncode(value), 'normal'),
        throwsFormatException,
      );
    }
  });
  test('QA state accepts a backwards advance but not a stale callback', () {
    final runtime = QaRuntime(source());
    final late = DateTime.utc(2026, 10, 5, 0);
    final early = DateTime.utc(2026, 10, 4, 22, 59, 59);
    expect(runtime.accept(state(late, 2)), isTrue);
    expect(runtime.accept(state(early, 1)), isFalse);
    expect(runtime.now(), late);
    expect(runtime.accept(state(early, 3)), isTrue);
    expect(runtime.now(), early);
    expect(runtime.dataset.version, 'toshima-clock-qa-tomorrow-v1');
  });
  test(
    'wrong package and invalid clock/scenario cannot change the current state',
    () {
      final runtime = QaRuntime(source());
      final valid = state(DateTime.utc(2026, 10, 5), 1);
      runtime.accept(valid);
      for (final invalid in [
        {...valid, 'package': 'dev.gomimap.gomimap'},
        {...valid, 'millis': -1},
        {...valid, 'millis': qaMaxMillis + 1},
        {...valid, 'millis': 253402300800000},
        {...valid, 'revision': -1},
        {...valid, 'scenario': 'unknown'},
      ]) {
        expect(() => runtime.accept(invalid), throwsFormatException);
        expect(runtime.now(), DateTime.utc(2026, 10, 5));
      }
    },
  );
  test('isolated fixtures give tomorrow and distinct deadlines without changing the source', () {
    final text = source();
    final normal = qaDataset(text, 'normal');
    final tomorrow = qaDataset(text, 'tomorrow');
    final multi = qaDataset(text, 'multi');
    final date = CalendarDate(2026, 10, 5);
    final days = [
      for (var i = 0; i < 4; i++)
        demoCalendar(DemoArea.a, dataset: tomorrow).onDate(date.addDays(i)),
    ];
    expect(scheduleFocus(days, 479).day, date);
    expect(scheduleFocus(days, 480).day, date.addDays(1));
    final multiDay = demoCalendar(DemoArea.a, dataset: multi).onDate(date);
    expect(multiDay.collections.map((e) => e.deadline.toString()).toList(), [
      '08:00',
      '09:30',
    ]);
    expect(
      demoCalendar(
        DemoArea.a,
        dataset: normal,
      ).onDate(date.addDays(1)).collections,
      isEmpty,
    );
    expect(jsonDecode(text)['version'], 'toshima-demo-v1');
    expect(source(), text);
  });
  testWidgets(
    'clock advance refreshes current cards and projection while the saved district survives',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final preferences = await SharedPreferences.getInstance();
      final bridge = FakeWidgetBridge();
      final dataset = qaDataset(source(), 'tomorrow');
      var instant = DateTime.utc(2026, 10, 4, 22, 59, 59);
      Future<void> render() async {
        await tester.pumpWidget(
          GomimapApp(
            preferences: preferences,
            dataset: dataset,
            widgetBridge: bridge,
            clock: () => instant,
            clockFrozen: true,
          ),
        );
        await tester.pumpAndSettle();
      }

      Finder primaryText(String text) => find.descendant(
        of: find.byKey(const ValueKey('today-schedule')),
        matching: find.text(text),
      );
      await render();
      expect(primaryText('今日  10/5(月)'), findsOneWidget);
      instant = DateTime.utc(2026, 10, 4, 23);
      await render();
      expect(primaryText('明日  10/6(火)'), findsOneWidget);
      expect(primaryText('資源'), findsOneWidget);
      instant = DateTime.utc(2026, 10, 5, 15);
      await render();
      expect(primaryText('今日  10/6(火)'), findsOneWidget);
      final saved = jsonDecode(bridge.snapshots.last);
      expect(saved['start'], '2026-10-06');
      expect(saved['datasetVersion'], dataset.version);
      expect(
        preferences.getString(PreferencesDemoSetupStore.key),
        const DemoSetupSnapshot.saved(DemoArea.a).encode(),
      );
    },
  );
  testWidgets(
    'normal app timer re-evaluates the deadline and Japanese midnight',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'app.language': 'ja',
        PreferencesDemoSetupStore.key: const DemoSetupSnapshot.saved(DemoArea.a)
            .encode(),
      });
      final preferences = await SharedPreferences.getInstance();
      var instant = DateTime.utc(2026, 10, 4, 22, 59, 59);
      await tester.pumpWidget(
        GomimapApp(
          preferences: preferences,
          dataset: qaDataset(source(), 'tomorrow'),
          widgetBridge: FakeWidgetBridge(),
          clock: () => instant,
        ),
      );
      await tester.pumpAndSettle();
      final primary = find.byKey(const ValueKey('today-schedule'));
      expect(
        find.descendant(of: primary, matching: find.text('今日  10/5(月)')),
        findsOneWidget,
      );
      instant = DateTime.utc(2026, 10, 4, 23);
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.descendant(of: primary, matching: find.text('明日  10/6(火)')),
        findsOneWidget,
      );
      instant = DateTime.utc(2026, 10, 5, 15);
      await tester.pump(const Duration(hours: 16));
      expect(
        find.descendant(of: primary, matching: find.text('今日  10/6(火)')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
