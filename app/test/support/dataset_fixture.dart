// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:gomimap/domain/municipal_dataset.dart';

const fixturePath = '../data/datasets/fixtures/toshima-demo-v1.json';

Map<String, dynamic> fixtureJson() =>
    jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
MunicipalDataset fixtureDataset([void Function(Map<String, dynamic>)? change]) {
  final json = fixtureJson();
  change?.call(json);
  return MunicipalDataset.decode(jsonEncode(json), allowFixtures: true);
}
