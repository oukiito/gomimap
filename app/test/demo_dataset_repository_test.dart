// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/dataset_cache.dart';
import 'package:gomimap/data/dataset_download.dart';
import 'package:gomimap/data/demo_dataset_repository.dart';
import 'package:gomimap/domain/schedule.dart';
import 'package:gomimap/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/dataset_fixture.dart';

class FixtureBundle extends CachingAssetBundle {
  FixtureBundle(this.content);
  final String content;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
}

class MemoryDatasetCache implements DatasetCache {
  List<String> records = [];
  bool fail = false;
  int writes = 0;
  @override
  Future<List<String>> read() async => records;
  @override
  Future<bool> save(String record, {String? previous}) async {
    writes++;
    if (fail) return false;
    records = [record, ?previous ?? (records.length > 1 ? records[1] : null)];
    return true;
  }
}

class FixtureDownload implements DatasetDownload {
  FixtureDownload(this.content);
  Uint8List content;
  bool offline = false;
  int calls = 0;
  Completer<void>? gate;
  void Function(Map<String, dynamic>)? changeManifest;
  Uint8List? wrongBytes;

  @override
  Future<Uint8List> get(Uri uri, {required int maxBytes}) async {
    calls++;
    await gate?.future;
    if (offline) throw StateError('Offline');
    if (uri.path == '/manifest.json') {
      final json = jsonDecode(utf8.decode(content)) as Map<String, dynamic>;
      final digest = sha256.convert(content).toString();
      final manifest = <String, dynamic>{
        'manifestVersion': 1,
        'channel': 'development',
        'kind': 'fixture',
        'sourceRepository': 'https://github.com/oukiito/gomimap',
        'sourceCommit': '04abf0a2a0b1f24b903b831f48ef8bdae8c50a03',
        'license': 'GPL-3.0-or-later',
        'licensePath': '/LICENSE.txt',
        'datasets': [
          {
            'municipalityId': 'demo-toshima',
            'version': json['version'],
            'schemaVersion': 1,
            'kind': 'fixture',
            'path': '/datasets/demo-toshima/${json['version']}.$digest.json',
            'sizeBytes': content.length,
            'sha256': digest,
            'validPeriod': json['validPeriod'],
          },
        ],
      };
      changeManifest?.call(manifest);
      return Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
    }
    expect(uri.host, 'gomimap-data-dev.ouki-ito.workers.dev');
    expect(uri.hasQuery, isFalse);
    return wrongBytes ?? content;
  }
}

Uint8List revision(String version, {int weekday = 2}) {
  final json = fixtureJson();
  json['version'] = version;
  json['publishedAt'] = '2026-10-08T00:00:00Z';
  json['baselines'][0]['recurrences'][0]['weekdays'] = [weekday];
  return Uint8List.fromList(utf8.encode(jsonEncode(json)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryDatasetCache cache;
  late FixtureDownload download;
  late DemoDatasetRepository repository;
  late DateTime now;
  Future<void> initialize() =>
      repository.initialize(bundle: FixtureBundle(jsonEncode(fixtureJson())));

  setUp(() {
    cache = MemoryDatasetCache();
    download = FixtureDownload(revision('v2'));
    now = DateTime.utc(2026, 10, 8);
    repository = DemoDatasetRepository(
      cache: cache,
      download: download,
      clock: () => now,
    );
  });
  tearDown(() => repository.dispose());

  test('initialization never downloads; validated saved revision survives restart offline', () async {
    await initialize();
    expect(download.calls, 0);
    expect(repository.current!.version, 'toshima-demo-v1');
    expect(await repository.refresh(), DatasetRefreshResult.updated);
    expect(cache.writes, 1);
    final restarted = DemoDatasetRepository(
      cache: cache,
      download: download,
      clock: () => now,
    );
    addTearDown(restarted.dispose);
    download.offline = true;
    await restarted.initialize(
      bundle: FixtureBundle(jsonEncode(fixtureJson())),
    );
    expect(restarted.current!.version, 'v2');
    expect(await restarted.refresh(), DatasetRefreshResult.skipped);
    expect(download.calls, 2);
    expect(
      ScheduleCalendar(
        dataset: restarted.current,
        areaId: 'a',
      ).on(DateTime(2026, 10, 6)).labels,
      ['burnable'],
    );
    now = now.add(const Duration(days: 1));
    expect(await restarted.refresh(), DatasetRefreshResult.failed);
    expect(restarted.current!.version, 'v2');
  });

  test('one in-flight update and 24-hour success interval; unchanged checksum skips dataset download', () async {
    await initialize();
    download.gate = Completer<void>();
    final first = repository.refresh();
    final second = repository.refresh();
    expect(download.calls, 1);
    download.gate!.complete();
    expect(await first, DatasetRefreshResult.updated);
    expect(await second, DatasetRefreshResult.updated);
    expect(download.calls, 2);
    expect(await repository.refresh(), DatasetRefreshResult.skipped);
    now = now.add(const Duration(hours: 24));
    expect(await repository.refresh(), DatasetRefreshResult.unchanged);
    expect(download.calls, 3);
  });

  test('failed save does not publish a candidate or change the calendar; retry succeeds after one hour', () async {
    await initialize();
    final previous = repository.current;
    var notifications = 0;
    repository.addListener(() => notifications++);
    cache.fail = true;
    expect(await repository.refresh(), DatasetRefreshResult.failed);
    expect(identical(repository.current, previous), isTrue);
    expect(notifications, 0);
    expect(await repository.refresh(), DatasetRefreshResult.skipped);
    now = now.add(const Duration(hours: 1));
    cache.fail = false;
    expect(await repository.refresh(), DatasetRefreshResult.updated);
    expect(notifications, 1);
  });

  test('corrupt active record recovers the previous verified record; corrupt both use bundle', () async {
    await initialize();
    await repository.refresh();
    now = now.add(const Duration(days: 1));
    download.content = revision('v3', weekday: 4);
    await repository.refresh();
    expect(cache.records.length, 2);
    now = now.add(const Duration(days: 1));
    final oldBackup = cache.records[1];
    expect(await repository.refresh(), DatasetRefreshResult.unchanged);
    expect(cache.records[1], oldBackup);
    cache.records[0] = 'broken';
    final recovered = DemoDatasetRepository(cache: cache, download: download);
    addTearDown(recovered.dispose);
    await recovered.initialize(
      bundle: FixtureBundle(jsonEncode(fixtureJson())),
    );
    expect(recovered.current!.version, 'v2');
    cache.records = ['broken', 'broken'];
    final fallback = DemoDatasetRepository(cache: cache, download: download);
    addTearDown(fallback.dispose);
    await fallback.initialize(bundle: FixtureBundle(jsonEncode(fixtureJson())));
    expect(fallback.current!.version, 'toshima-demo-v1');
  });

  test('same-version mutation, older revision and invalid references never overwrite cache', () async {
    await initialize();
    await repository.refresh();
    final previous = repository.current;
    final saved = List<String>.of(cache.records);
    final broken =
        jsonDecode(utf8.decode(revision('v4'))) as Map<String, dynamic>;
    broken['baselines'][0]['sourceIds'] = ['missing'];
    for (final bytes in [
      revision('v2', weekday: 4),
      Uint8List.fromList(utf8.encode(jsonEncode(fixtureJson()))),
      Uint8List.fromList(utf8.encode(jsonEncode(broken))),
    ]) {
      now = now.add(const Duration(days: 1));
      download.content = bytes;
      expect(await repository.refresh(), DatasetRefreshResult.failed);
      expect(identical(repository.current, previous), isTrue);
      expect(cache.records, saved);
    }
  });

  for (final fault in [
    'checksum',
    'size',
    'municipality',
    'schema',
    'period',
    'path',
    'kind',
    'duplicate',
    'manifestVersion',
    'unrecognized',
  ]) {
    test('rejects $fault mismatch and retains bundled schedule', () async {
      await initialize();
      final previous = repository.current;
      download.changeManifest = (manifest) {
        final entry = manifest['datasets'][0] as Map<String, dynamic>;
        switch (fault) {
          case 'checksum':
            download.wrongBytes = Uint8List.fromList([1, 2, 3]);
          case 'size':
            entry['sizeBytes'] = maxDatasetBytes + 1;
          case 'municipality':
            entry['municipalityId'] = 'other-city';
          case 'schema':
            entry['schemaVersion'] = 2;
          case 'period':
            entry['validPeriod']['end'] = '2027-03-01';
          case 'path':
            entry['path'] = 'https://another-host.invalid/a.json';
          case 'kind':
            entry['kind'] = 'verified';
          case 'duplicate':
            manifest['datasets'].add(Map<String, dynamic>.from(entry));
          case 'manifestVersion':
            manifest['manifestVersion'] = 2;
          case 'unrecognized':
            manifest['extra'] = true;
        }
      };
      expect(await repository.refresh(), DatasetRefreshResult.failed);
      expect(identical(repository.current, previous), isTrue);
      expect(cache.writes, 0);
    });
  }

  test(
    'expired saved data is confirmation-needed, never no-collection',
    () async {
      await initialize();
      await repository.refresh();
      expect(
        ScheduleCalendar(
          dataset: repository.current,
          areaId: 'a',
        ).on(DateTime(2027, 2, 1)).status,
        ScheduleStatus.needsConfirmation,
      );
    },
  );

  test(
    'missing bundle and cache leave unknown; valid download can recover',
    () async {
      await repository.initialize(bundle: FixtureBundle('bad-json'));
      expect(repository.current, isNull);
      expect(await repository.refresh(), DatasetRefreshResult.updated);
      expect(repository.current!.version, 'v2');
    },
  );

  testWidgets(
    'first frame does not wait for HTTP and update keeps search/tab/district/language',
    (tester) async {
      await initialize();
      SharedPreferences.setMockInitialValues({
        'demo.area': 'a',
        'app.language': 'en',
      });
      download.gate = Completer<void>();
      await tester.pumpWidget(
        GomimapApp(
          preferences: await SharedPreferences.getInstance(),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Burnable waste'), findsOneWidget);
      expect(download.calls, 1);
      await tester.tap(find.byIcon(Icons.search).last);
      await tester.pumpAndSettle();
      final search = find.byType(TextField);
      await tester.enterText(search, 'battery');
      await tester.pumpAndSettle();
      download.gate!.complete();
      await tester.runAsync(() async {
        await repository.refresh();
      });
      await tester.pumpAndSettle();
      expect(repository.current!.version, 'v2');
      expect(tester.widget<TextField>(search).controller!.text, 'battery');
      expect(
        find.byKey(const ValueKey('collection-area-context')),
        findsOneWidget,
      );
      expect(find.text('Dry-cell batteries'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
