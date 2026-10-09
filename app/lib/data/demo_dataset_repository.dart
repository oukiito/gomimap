// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/municipal_dataset.dart';
import 'bundled_dataset.dart';
import 'dataset_cache.dart';
import 'dataset_cache_web.dart'
    if (dart.library.io) 'dataset_cache_native.dart'
    as platform;
import 'dataset_download.dart';
import 'dataset_snapshot.dart';
import 'update_coordinator.dart';

const demoDataOrigin = 'https://gomimap-data-dev.ouki-ito.workers.dev';
const maxDatasetBytes = 2 * 1024 * 1024;
const maxManifestBytes = 64 * 1024;

/// Development-only descriptor. Production data needs its own publication gate.
class DemoDatasetEntry {
  DemoDatasetEntry(this.json) {
    final value = JsonObject(json, 'manifest.dataset');
    value.only({
      'municipalityId',
      'version',
      'schemaVersion',
      'kind',
      'path',
      'sizeBytes',
      'sha256',
      'validPeriod',
    });
    if (value.id('municipalityId') != 'demo-toshima' ||
        value.integer('schemaVersion') != 1 ||
        value.text('kind') != 'fixture') {
      throw const FormatException('Wrong demo dataset');
    }
    version = value.id('version');
    digest = value.text('sha256');
    size = value.integer('sizeBytes');
    path = value.text('path');
    value.period('validPeriod');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
        size < 1 ||
        size > maxDatasetBytes ||
        path != '/datasets/demo-toshima/$version.$digest.json') {
      throw const FormatException('Invalid dataset descriptor');
    }
  }
  final Map<String, dynamic> json;
  late final String version, digest, path;
  late final int size;

  static DemoDatasetEntry fromManifest(Uint8List bytes) {
    if (bytes.length > maxManifestBytes) {
      throw const FormatException('Manifest too large');
    }
    final value = JsonObject(jsonDecode(utf8.decode(bytes)), 'manifest');
    value.only({
      'manifestVersion',
      'channel',
      'kind',
      'sourceRepository',
      'sourceCommit',
      'license',
      'licensePath',
      'datasets',
    });
    if (value.integer('manifestVersion') != 1 ||
        value.text('channel') != 'development' ||
        value.text('kind') != 'fixture' ||
        value.text('sourceRepository') !=
            'https://github.com/oukiito/gomimap' ||
        !RegExp(r'^[a-f0-9]{40}$').hasMatch(value.text('sourceCommit')) ||
        value.text('license') != 'GPL-3.0-or-later' ||
        value.text('licensePath') != '/LICENSE.txt') {
      throw const FormatException('Unsupported manifest');
    }
    final entries = value.list('datasets');
    // Initial publisher only serves this municipality. No ambiguous selection.
    if (entries.length != 1 || entries.single is! Map<String, dynamic>) {
      throw const FormatException('Expected one demo dataset');
    }
    return DemoDatasetEntry(entries.single as Map<String, dynamic>);
  }

  String validate(Uint8List bytes) {
    if (bytes.length != size || sha256.convert(bytes).toString() != digest) {
      throw const FormatException('Dataset checksum or size mismatch');
    }
    final content = utf8.decode(bytes);
    final data = MunicipalDataset.decode(content, allowFixtures: true);
    if (data.kind != DatasetKind.fixture ||
        data.municipality.id != 'demo-toshima' ||
        data.version != version ||
        data.period.start.toString() != (json['validPeriod'] as Map)['start'] ||
        data.period.end.toString() != (json['validPeriod'] as Map)['end'] ||
        !data.areas.keys.toSet().containsAll({'a', 'b'})) {
      throw const FormatException('Dataset metadata mismatch');
    }
    return content;
  }
}

class _Record {
  _Record(this.entry, this.bytes, this.checkedAt);
  final DemoDatasetEntry entry;
  final Uint8List bytes;
  final DateTime checkedAt;
  String encode() => jsonEncode({
    'cacheVersion': 1,
    'entry': entry.json,
    'bytes': base64Encode(bytes),
    'checkedAt': checkedAt.toUtc().toIso8601String().replaceFirst(
      RegExp(r'\.\d+Z$'),
      'Z',
    ),
  });
  static _Record decode(String text) {
    if (utf8.encode(text).length > maxCacheBytes) {
      throw const FormatException('Cache too large');
    }
    final value = JsonObject(jsonDecode(text), 'cache');
    value.only({'cacheVersion', 'entry', 'bytes', 'checkedAt'});
    if (value.integer('cacheVersion') != 1) {
      throw const FormatException('Unknown cache version');
    }
    final entry = DemoDatasetEntry(value.object('entry').value);
    final bytes = base64Decode(value.text('bytes'));
    entry.validate(bytes);
    return _Record(entry, bytes, value.timestamp('checkedAt'));
  }
}

enum DatasetRefreshResult { updated, unchanged, skipped, failed }

/// One demo municipality, one writer, no download on the first-frame path.
class DemoDatasetRepository extends ChangeNotifier {
  DemoDatasetRepository({
    required this.cache,
    required this.download,
    Uri? origin,
    DateTime Function()? clock,
  }) : origin = origin ?? Uri.parse(demoDataOrigin),
       clock = clock ?? DateTime.now {
    if (this.origin.scheme != 'https' ||
        this.origin.userInfo.isNotEmpty ||
        this.origin.hasQuery ||
        this.origin.hasFragment ||
        (this.origin.path.isNotEmpty && this.origin.path != '/')) {
      throw const FormatException('Expected HTTPS origin');
    }
  }
  UpdateCoordinator? coordinator;
  final DatasetCache cache;
  final DatasetDownload download;
  final Uri origin;
  final DateTime Function() clock;
  MunicipalDataset? _current;
  String? _content;
  _Record? _record;
  DateTime? _attemptAt;
  Future<DatasetRefreshResult>? _inFlight;
  bool _disposed = false;
  MunicipalDataset? get current => _current;

  Future<void> initialize({AssetBundle? bundle}) async {
    try {
      final text = await (bundle ?? rootBundle).loadString(demoDatasetAsset);
      final data = MunicipalDataset.decode(text, allowFixtures: true);
      if (data.kind == DatasetKind.fixture &&
          data.municipality.id == 'demo-toshima' &&
          data.version == 'toshima-demo-v1') {
        _current = data;
        _content = text;
      }
    } catch (_) {
      // A missing bundle leaves confirmation-needed until a valid cache loads.
    }
    try {
      for (final text in await cache.read()) {
        try {
          final record = _Record.decode(text);
          final content = record.entry.validate(record.bytes);
          final candidate = _candidate(content, record.entry.version);
          if (candidate == null) continue;
          _current = candidate;
          _content = content;
          _record = record;
          break;
        } catch (_) {
          // Corrupt active file: try previous; never read .pending files.
        }
      }
    } catch (_) {
      // Storage denied/unavailable: retain the validated bundled data.
    }
  }

  MunicipalDataset? _candidate(String content, String version) {
    final snapshot = DatasetSnapshot(
      municipalityId: 'demo-toshima',
      allowFixtures: true,
    );
    if (_content != null) {
      snapshot.tryApply(_content!, expectedVersion: _current!.version);
    }
    if (!snapshot.tryApply(content, expectedVersion: version) ||
        snapshot.current?.kind != DatasetKind.fixture) {
      return null;
    }
    return snapshot.current;
  }

  Future<DatasetRefreshResult> refresh() {
    if (_disposed) return Future.value(DatasetRefreshResult.skipped);
    if (_inFlight != null) return _inFlight!;
    final now = clock().toUtc();
    bool recent(DateTime? time, Duration interval) =>
        time != null && !now.isBefore(time) && now.difference(time) < interval;
    if (recent(_record?.checkedAt, const Duration(hours: 24)) ||
        recent(_attemptAt, const Duration(hours: 1))) {
      return Future.value(DatasetRefreshResult.skipped);
    }
    _attemptAt = now;
    final future = _refresh(now);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<DatasetRefreshResult> _refresh(DateTime now) async {
    try {
      final entry = DemoDatasetEntry.fromManifest(
        await download.get(
          origin.resolve('/manifest.json'),
          maxBytes: maxManifestBytes,
        ),
      );
      final bytes = _record?.entry.digest == entry.digest
          ? _record!.bytes
          : await download.get(
              origin.resolve(entry.path),
              maxBytes: entry.size,
            );
      final content = entry.validate(bytes);
      final candidate = _candidate(content, entry.version);
      if (candidate == null || _disposed) return DatasetRefreshResult.failed;
      final record = _Record(entry, bytes, now);
      final changed = _content != content;
      Future<bool> commit() async {
        if (!await cache.save(
          record.encode(),
          previous: changed ? _record?.encode() : null,
        )) {
          return false;
        }
        _record = record;
        _content = content;
        _current = candidate;
        if (changed && !_disposed) notifyListeners();
        return true;
      }

      final updates = coordinator;
      final committed = changed && updates != null
          ? await updates.change('dataset', {
              'datasetVersion': candidate.version,
              'municipalityId': candidate.municipality.id,
            }, commit)
          : await commit();
      if (!committed) return DatasetRefreshResult.failed;
      return changed
          ? DatasetRefreshResult.updated
          : DatasetRefreshResult.unchanged;
    } catch (_) {
      // Errors never replace the old snapshot and never log private/raw content.
      return DatasetRefreshResult.failed;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _UnavailableCache implements DatasetCache {
  @override
  Future<List<String>> read() async => [];
  @override
  Future<bool> save(String record, {String? previous}) async => false;
}

Future<DemoDatasetRepository> loadDemoDatasetRepository() async {
  DatasetCache cache;
  try {
    cache = await platform.createDatasetCache();
  } catch (_) {
    cache = _UnavailableCache();
  }
  final repository = DemoDatasetRepository(
    cache: cache,
    download: HttpDatasetDownload(),
  );
  await repository.initialize();
  return repository;
}
