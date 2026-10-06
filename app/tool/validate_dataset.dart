// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:gomimap/domain/municipal_dataset.dart';
import 'package:gomimap/domain/publication_validation.dart';

void main(List<String> arguments) {
  final fixture = arguments.contains('--allow-fixtures');
  final paths = arguments
      .where((value) => value != '--allow-fixtures')
      .toList();
  if (paths.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/validate_dataset.dart [--allow-fixtures] dataset.json [source-registry.json]',
    );
    exitCode = 2;
    return;
  }
  try {
    if (paths.length > 2) throw FormatException('Too many arguments');
    final data = MunicipalDataset.decode(
      File(paths.first).readAsStringSync(),
      allowFixtures: fixture,
    );
    if (data.kind == DatasetKind.verified) {
      if (paths.length != 2) {
        throw FormatException('Verified data requires a source registry');
      }
      final registry =
          jsonDecode(File(paths[1]).readAsStringSync()) as Map<String, dynamic>;
      validateSourceRegistry(data, registry);
    }
    stdout.writeln(
      'Valid ${data.kind.name} dataset: ${data.municipality.id}/${data.version}',
    );
  } catch (error) {
    stderr.writeln('Invalid dataset: $error');
    exitCode = 1;
  }
}
