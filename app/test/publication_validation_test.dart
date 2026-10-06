// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/domain/municipal_dataset.dart';
import 'package:gomimap/domain/publication_validation.dart';

import 'support/dataset_fixture.dart';

void main() {
  test('publication gate cross-checks declared registry URL, licence and reuse status', () {
    final json = fixtureJson()..['kind'] = 'verified';
    final entries = <Map<String, dynamic>>[];
    for (final source in json['sources'] as List) {
      source['fixture'] = false;
      source['registryId'] = 'registered-${source['id']}';
      entries.add({
        'id': source['registryId'],
        'url': source['url'],
        'rights': {'redistribution': 'allowed', 'license': source['license']},
      });
    }
    final data = MunicipalDataset.decode(jsonEncode(json));
    final registry = {
      'schema_version': 1,
      'municipality_id': 'demo-toshima',
      'sources': entries,
    };
    expect(() => validateSourceRegistry(data, registry), returnsNormally);
    entries.first['rights']['redistribution'] = 'needs_review';
    expect(() => validateSourceRegistry(data, registry), throwsFormatException);
    entries.first['rights']['redistribution'] = 'allowed';
    entries.first['url'] = 'https://example.com/other';
    expect(() => validateSourceRegistry(data, registry), throwsFormatException);
    entries.first['url'] = json['sources'][0]['url'];
    entries.first['rights']['license'] = 'different';
    expect(() => validateSourceRegistry(data, registry), throwsFormatException);
  });
  test('fixture and wrong/duplicate source registries cannot pass the production gate', () {
    expect(
      () => validateSourceRegistry(fixtureDataset(), {
        'schema_version': 1,
        'municipality_id': 'another-city',
        'sources': [],
      }),
      throwsFormatException,
    );
    final json = fixtureJson()..['kind'] = 'verified';
    for (final source in json['sources'] as List) {
      source['fixture'] = false;
      source['registryId'] = 'registered';
    }
    final data = MunicipalDataset.decode(jsonEncode(json));
    final entry = {
      'id': 'registered',
      'url': json['sources'][0]['url'],
      'rights': {'redistribution': 'allowed', 'license': 'GPL-3.0-or-later'},
    };
    expect(
      () => validateSourceRegistry(data, {
        'schema_version': 1,
        'municipality_id': 'demo-toshima',
        'sources': [entry, entry],
      }),
      throwsFormatException,
    );
  });
}
