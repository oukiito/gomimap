// SPDX-License-Identifier: GPL-3.0-or-later

/// Opaque, complete validated records. Candidates are never exposed as active.
/// One repository owns writes; multi-process writers are not supported.
abstract interface class DatasetCache {
  Future<List<String>> read();
  Future<bool> save(String record, {String? previous});
}

const maxCacheBytes = 4 * 1024 * 1024;
