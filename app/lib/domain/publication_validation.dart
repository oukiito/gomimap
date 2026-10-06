// SPDX-License-Identifier: GPL-3.0-or-later

import 'municipal_dataset.dart';

/// Cross-check dataset evidence against the separately validated source registry.
/// This checks declarations, not the truth of municipal rules or legal consent.
void validateSourceRegistry(MunicipalDataset data, Object? registry) {
  final json = JsonObject(registry, 'source registry');
  if (json.integer('schema_version') != 1 ||
      json.text('municipality_id') != data.municipality.id) {
    throw FormatException('Wrong source-registry schema or municipality');
  }
  final entries = indexed(
    json.objects('sources'),
    (entry) => entry.id('id'),
    'registered source',
  );
  if (data.kind != DatasetKind.verified) {
    throw FormatException(
      'Only verified datasets use the publication registry gate',
    );
  }
  for (final source in data.sources.values) {
    final entry = entries[source.registryId];
    if (entry == null ||
        entry.https('url') != source.url ||
        entry.object('rights').text('redistribution') != 'allowed' ||
        entry.object('rights').optionalText('license') != source.license) {
      throw FormatException(
        'Source is not cleared by the registry: ${source.id}',
      );
    }
  }
}
