// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/dataset_cache_native.dart';
import 'package:gomimap/data/dataset_download.dart';
import 'package:gomimap/data/demo_dataset_repository.dart';

// Explicit network check, separate from hermetic CI. No credentials required.
class LiveHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'live public fixture validates, saves to files and reloads without HTTP',
    () => HttpOverrides.runWithHttpOverrides(() async {
      final directory = await Directory.systemTemp.createTemp(
        'gomimap-live-dataset-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = DemoDatasetRepository(
        cache: FileDatasetCache(directory),
        download: HttpDatasetDownload(),
      );
      addTearDown(repository.dispose);
      await repository.initialize();
      expect(await repository.refresh(), DatasetRefreshResult.unchanged);
      expect((await FileDatasetCache(directory).read()).length, 1);
      final restarted = DemoDatasetRepository(
        cache: FileDatasetCache(directory),
        download: HttpDatasetDownload(),
      );
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.current!.version, 'toshima-demo-v1');
      expect(await restarted.refresh(), DatasetRefreshResult.skipped);
    }, LiveHttpOverrides()),
    skip: !const bool.fromEnvironment('GOMIMAP_VERIFY_LIVE_DATA'),
  );
}
