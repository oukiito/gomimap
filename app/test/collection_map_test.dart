// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  test(
    'GSI live map is configured; credential-bearing tile URLs are rejected',
    () {
      expect(MapTileSource.gsi.isConfigured, isTrue);
      expect(
        const MapTileSource(
          url: 'https://secret@tiles.example.org/{z}/{x}/{y}.png',
          attribution: 'a',
          attributionUrl: 'https://example.org',
        ).isConfigured,
        isFalse,
      );
    },
  );
  testWidgets('panned viewport survives leaving and reopening the map', (
    tester,
  ) async {
    final view = CollectionMapView();
    Widget screen(bool show) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: show
            ? CollectionMap(
                points: const [],
                onSelected: (_) {},
                tileSource: MapTileSource.gsi,
                tileProvider: MemoryTiles(),
                view: view,
              )
            : const SizedBox(),
      ),
    );
    await tester.pumpWidget(screen(true));
    await tester.pumpAndSettle();
    final before = view.center;
    await tester.drag(find.byType(FlutterMap), const Offset(-120, 40));
    await tester.pumpAndSettle();
    expect(view.center, isNot(before));
    final panned = view.center;
    await tester.pumpWidget(screen(false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen(true));
    await tester.pumpAndSettle();
    final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
    expect(camera.center, panned);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'failed tiles offer retry and existing list without resetting the viewport',
    (tester) async {
      bool fail = true, openedList = false;
      final client = MockClient(
        (_) async => fail
            ? http.Response('', 503)
            : http.Response.bytes(TileProvider.transparentImage, 200),
      );
      addTearDown(client.close);
      final provider = NetworkTileProvider(
        httpClient: client,
        cachingProvider: const DisabledMapCachingProvider(),
        attemptDecodeOfHttpErrorResponses: false,
      );
      final view = CollectionMapView();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: CollectionMap(
              points: [demoPoints.last],
              onSelected: (_) {},
              tileSource: MapTileSource.gsi,
              tileProvider: provider,
              view: view,
              onShowList: () => openedList = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('地図を読み込めません'), findsOneWidget);
      await tester.tap(find.text('一覧を見る'));
      expect(openedList, isTrue);
      await tester.drag(find.byType(FlutterMap), const Offset(-60, 0));
      await tester.pumpAndSettle();
      final panned = view.center;
      fail = false;
      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();
      expect(find.text('地図を読み込めません'), findsNothing);
      expect(view.center, panned);
      expect(tester.takeException(), isNull);
    },
  );
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
