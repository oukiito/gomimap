// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/services.dart';

import '../domain/municipal_dataset.dart';
import 'dataset_snapshot.dart';

const demoDatasetAsset = 'assets/generated/toshima-demo-v1.json';

/// Fixture permission is explicit. Production loaders must leave it disabled.
Future<MunicipalDataset?> loadBundledDemoDataset({AssetBundle? bundle}) async {
  try {
    final text = await (bundle ?? rootBundle).loadString(demoDatasetAsset);
    final snapshot = DatasetSnapshot(
      municipalityId: 'demo-toshima',
      allowFixtures: true,
    );
    if (!snapshot.tryApply(text, expectedVersion: 'toshima-demo-v1') ||
        snapshot.current?.kind != DatasetKind.fixture) {
      return null;
    }
    return snapshot.current;
  } catch (_) {
    // The calendar represents absence/invalid data as needsConfirmation.
    return null;
  }
}
