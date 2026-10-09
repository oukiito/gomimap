// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/demo_data.dart';
import '../l10n/generated/app_localizations.dart';

class CollectionMapView {
  LatLng center = const LatLng(35.726, 139.715);
  double zoom = 14;
}

class CollectionMap extends StatefulWidget {
  const CollectionMap({
    super.key,
    required this.points,
    required this.onSelected,
    this.tileSource = const MapTileSource.fromEnvironment(),
    this.tileProvider,
    this.view,
    this.onShowList,
  });
  final MapTileSource tileSource;
  final List<CollectionPoint> points;
  final ValueChanged<CollectionPoint> onSelected;
  final TileProvider? tileProvider;
  final CollectionMapView? view;
  final VoidCallback? onShowList;
  @override
  State<CollectionMap> createState() => _CollectionMapState();
}

class _CollectionMapState extends State<CollectionMap> {
  late final CollectionMapView view = widget.view ?? CollectionMapView();
  bool failed = false;
  int attempt = 0;
  late TileProvider provider = makeProvider();
  TileProvider makeProvider() =>
      widget.tileProvider ??
      NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: 32 * 1024 * 1024,
        ),
      );
  void failedTile() {
    if (failed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !failed) setState(() => failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!widget.tileSource.isConfigured) {
      return Container(
        constraints: const BoxConstraints(minHeight: 290),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE7EEEA),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: Color(0xFF456958)),
            const SizedBox(height: 16),
            Text(
              l10n.mapLoadError,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (widget.onShowList != null)
              TextButton(
                onPressed: widget.onShowList,
                child: Text(l10n.mapShowList),
              ),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (failed)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(l10n.mapLoadError),
              TextButton(
                onPressed: () => setState(() {
                  failed = false;
                  attempt++;
                  provider = makeProvider();
                }),
                child: Text(l10n.mapRetry),
              ),
              if (widget.onShowList != null)
                TextButton(
                  onPressed: widget.onShowList,
                  child: Text(l10n.mapShowList),
                ),
            ],
          ),
        Semantics(
          identifier: 'collection-map-canvas',
          child: SizedBox(
            height: (MediaQuery.sizeOf(context).height * .36).clamp(240, 360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FlutterMap(
                key: ValueKey(attempt),
                options: MapOptions(
                  initialCenter: view.center,
                  initialZoom: view.zoom,
                  keepAlive: true,
                  onPositionChanged: (camera, _) {
                    view.center = camera.center;
                    view.zoom = camera.zoom;
                  },
                  minZoom: 10,
                  maxZoom: 18,
                  cameraConstraint: CameraConstraint.containCenter(
                    bounds: LatLngBounds(
                      const LatLng(20, 122),
                      const LatLng(46.5, 154),
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: widget.tileSource.url,
                    userAgentPackageName: 'dev.gomimap.gomimap',
                    tileProvider: provider,
                    errorTileCallback: (_, _, _) => failedTile(),
                  ),
                  MarkerLayer(
                    markers: widget.points
                        .map(
                          (point) => Marker(
                            point: LatLng(point.latitude, point.longitude),
                            width: 48,
                            height: 48,
                            child: IconButton(
                              tooltip: l10n.samplePoint(point.id.toUpperCase()),
                              onPressed: () => widget.onSelected(point),
                              icon: const Icon(Icons.location_on, size: 40),
                              color: const Color(0xFF246B53),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Material(
                      color: Colors.white,
                      child: TextButton(
                        onPressed: () async {
                          var opened = false;
                          try {
                            opened = await launchUrl(
                              Uri.parse(widget.tileSource.attributionUrl),
                            );
                          } on PlatformException {
                            opened = false;
                          }
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.sourceOpenError(
                                    widget.tileSource.attributionUrl,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(widget.tileSource.attribution),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A provider must supply both HTTPS tiles and visible attribution.
/// Runtime selects the audited GSI source; tests stay disconnected by default.
class MapTileSource {
  static const disabled = MapTileSource(
    url: '',
    attribution: '',
    attributionUrl: '',
  );
  const MapTileSource({
    required this.url,
    required this.attribution,
    required this.attributionUrl,
  });

  const MapTileSource.fromEnvironment()
    : url = const String.fromEnvironment('MAP_TILE_URL'),
      attribution = const String.fromEnvironment('MAP_ATTRIBUTION'),
      attributionUrl = const String.fromEnvironment('MAP_ATTRIBUTION_URL');

  static const gsi = MapTileSource(
    url: 'https://cyberjapandata.gsi.go.jp/xyz/pale/{z}/{x}/{y}.png',
    attribution: '国土地理院 / GSI',
    attributionUrl: 'https://maps.gsi.go.jp/development/ichiran.html',
  );
  static MapTileSource forApp() {
    if (const bool.fromEnvironment('MAP_DISABLED')) {
      return disabled;
    }
    const explicit = MapTileSource.fromEnvironment();
    if ([
      explicit.url,
      explicit.attribution,
      explicit.attributionUrl,
    ].every((v) => v.isEmpty)) {
      return gsi;
    }
    return explicit; // Partial/invalid configuration must not silently fall back.
  }

  final String url;
  final String attribution;
  final String attributionUrl;

  bool get isConfigured =>
      _isHttps(url) &&
      ['{z}', '{x}', '{y}'].every(url.contains) &&
      attribution.trim().isNotEmpty &&
      _isHttps(attributionUrl);

  static bool _isHttps(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }
}
