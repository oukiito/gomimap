// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/bundled_dataset.dart';
import '../domain/municipal_dataset.dart';

const qaBuild = bool.fromEnvironment('GOMIMAP_QA');
const qaPackage = 'dev.gomimap.gomimap.qa';
const qaMaxMillis = 4102444799999; // UTC 2099-12-31; keeps the 35-day horizon in four-digit years.

/// Owned, separate QA data. Never downloaded or published as a normal revision.
MunicipalDataset qaDataset(String source, String scenario) {
  if (!{'normal', 'tomorrow', 'multi'}.contains(scenario)) {
    throw const FormatException('Unknown QA scenario');
  }
  final json = jsonDecode(source) as Map<String, dynamic>;
  if (json['kind'] != 'fixture' ||
      json['version'] != 'toshima-demo-v1' ||
      json['municipality']['id'] != 'demo-toshima') {
    throw const FormatException('QA scenarios require the owned demo fixture');
  }
  json['version'] = 'toshima-clock-qa-$scenario-v1';
  final resource = json['baselines'][1]['recurrences'][0];
  if (scenario == 'tomorrow') resource['weekdays'] = [2];
  if (scenario == 'multi') {
    resource['weekdays'] = [1, 2];
    resource['deadline'] = '09:30';
  }
  return MunicipalDataset.decode(jsonEncode(json), allowFixtures: true);
}

/// A frozen app clock, shared with Kotlin. A revision prevents stale callbacks
/// from undoing a more recent explicit advance (time may move backwards in QA).
class QaRuntime extends ChangeNotifier {
  QaRuntime(String source)
    : datasets = {
        for (final scenario in ['normal', 'tomorrow', 'multi'])
          scenario: qaDataset(source, scenario),
      };
  static const channel = MethodChannel('dev.gomimap.gomimap/qa_clock');
  final Map<String, MunicipalDataset> datasets;
  int _revision = -1;
  DateTime _instant = DateTime.utc(2026, 10, 4, 22, 59, 59);
  String _scenario = 'normal';
  bool _frozen = true;
  bool get frozen => _frozen;
  DateTime now() => _frozen ? _instant : DateTime.now().toUtc();
  MunicipalDataset get dataset => datasets[_scenario]!;
  String get scenario => _scenario;

  bool accept(Object? value) {
    if (value is! Map || value['package'] != qaPackage) {
      throw const FormatException('The QA clock requires its isolated package');
    }
    final millis = value['millis'];
    final revision = value['revision'];
    final scenario = value['scenario'];
    if (millis is! int ||
        millis < 0 ||
        millis > qaMaxMillis ||
        revision is! int ||
        revision < 0 ||
        !datasets.containsKey(scenario)) {
      throw const FormatException('Invalid QA clock state');
    }
    if (revision <= _revision) return false;
    _revision = revision;
    _instant = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    _scenario = scenario as String;
    _frozen = value['frozen'] != false;
    notifyListeners();
    return true;
  }

  static Future<QaRuntime> connect() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('The QA clock is an Android-only test target');
    }
    final runtime = QaRuntime(await rootBundle.loadString(demoDatasetAsset));
    channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') runtime.accept(call.arguments);
    });
    runtime.accept(await channel.invokeMethod<Object?>('getState'));
    return runtime;
  }
}
