// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/demo_data.dart';
import '../l10n/generated/app_localizations.dart';

class CollectionMap extends StatelessWidget {
  const CollectionMap({
    super.key,
    required this.points,
    required this.onSelected,
    this.tileSource = const MapTileSource.fromEnvironment(),
    this.tileProvider,
  });
  final MapTileSource tileSource;
  final TileProvider? tileProvider;
  final List<CollectionPoint> points;
  final ValueChanged<CollectionPoint> onSelected;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!tileSource.isConfigured) {
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
              l10n.mapTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(l10n.mapUnavailable, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return SizedBox(
      height: 360,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(35.726, 139.715),
            initialZoom: 14,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: tileSource.url,
              userAgentPackageName: 'dev.gomimap.gomimap',
              tileProvider: tileProvider,
            ),
            MarkerLayer(
              markers: points
                  .map(
                    (point) => Marker(
                      point: LatLng(point.latitude, point.longitude),
                      width: 48,
                      height: 48,
                      child: IconButton(
                        tooltip: l10n.samplePoint(point.id.toUpperCase()),
                        onPressed: () => onSelected(point),
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
                        Uri.parse(tileSource.attributionUrl),
                      );
                    } on PlatformException {
                      opened = false;
                    }
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.sourceOpenError(tileSource.attributionUrl),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(tileSource.attribution),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A provider must supply both HTTPS tiles and visible attribution.
/// No public tile service is silently enabled for production.
class MapTileSource {
  const MapTileSource({
    required this.url,
    required this.attribution,
    required this.attributionUrl,
  });

  const MapTileSource.fromEnvironment()
    : url = const String.fromEnvironment('MAP_TILE_URL'),
      attribution = const String.fromEnvironment('MAP_ATTRIBUTION'),
      attributionUrl = const String.fromEnvironment('MAP_ATTRIBUTION_URL');

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
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
