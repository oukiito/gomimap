// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/demo_data.dart';
import 'package:gomimap/l10n/generated/app_localizations.dart';
import 'package:gomimap/ui/collection_map.dart';

class MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
  const source = MapTileSource(
    url: 'https://tiles.example.org/{z}/{x}/{y}.png',
    attribution: 'Test map attribution',
    attributionUrl: 'https://example.org/copyright',
  );

  test('tiles require HTTPS, XYZ coordinates, and attribution', () {
    expect(source.isConfigured, isTrue);
    for (final invalid in [
      const MapTileSource(url: '', attribution: '', attributionUrl: ''),
      MapTileSource(
        url: source.url.replaceFirst('https', 'http'),
        attribution: source.attribution,
        attributionUrl: source.attributionUrl,
      ),
      MapTileSource(
        url: 'https://example.org/map.png',
        attribution: source.attribution,
        attributionUrl: source.attributionUrl,
      ),
      MapTileSource(
        url: source.url,
        attribution: '',
        attributionUrl: source.attributionUrl,
      ),
      MapTileSource(
        url: source.url,
        attribution: source.attribution,
        attributionUrl: '',
      ),
    ]) {
      expect(invalid.isConfigured, isFalse);
    }
  });

  testWidgets('map exposes attribution and selects only provided points', (
    tester,
  ) async {
    CollectionPoint? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: CollectionMap(
            points: [demoPoints.last],
            tileSource: source,
            tileProvider: MemoryTiles(),
            onSelected: (point) => selected = point,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text(source.attribution), findsOneWidget);
    final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(markers.markers, hasLength(1));
    await tester.tap(find.byIcon(Icons.location_on));
    expect(selected, same(demoPoints.last));
    expect(tester.takeException(), isNull);
  });
}
