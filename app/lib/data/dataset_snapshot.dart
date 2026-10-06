// SPDX-License-Identifier: GPL-3.0-or-later

import '../domain/municipal_dataset.dart';

/// Whole-candidate validation precedes replacement of the in-memory snapshot.
/// Disk persistence, HTTP, checksums and publication remain separate concerns.
class DatasetSnapshot {
  DatasetSnapshot({required this.municipalityId, this.allowFixtures = false});
  final String municipalityId;
  final bool allowFixtures;
  MunicipalDataset? _current;
  String? _content;
  MunicipalDataset? get current => _current;

  bool tryApply(String content, {required String expectedVersion}) {
    try {
      final candidate = MunicipalDataset.decode(
        content,
        allowFixtures: allowFixtures,
      );
      if (candidate.municipality.id != municipalityId ||
          candidate.version != expectedVersion) {
        return false;
      }
      if (candidate.version == _current?.version) return content == _content;
      // Explicit rollback support is later G11 work; never silently downgrade.
      if (_current != null &&
          candidate.publishedAt.isBefore(_current!.publishedAt)) {
        return false;
      }
      _current = candidate;
      _content = content;
      return true;
    } catch (_) {
      return false;
    }
  }
}
