// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

abstract interface class DatasetDownload {
  Future<Uint8List> get(Uri uri, {required int maxBytes});
}

class HttpDatasetDownload implements DatasetDownload {
  HttpDatasetDownload({
    http.Client Function()? clientFactory,
    this.timeout = const Duration(seconds: 15),
  }) : clientFactory = clientFactory ?? http.Client.new;
  final http.Client Function() clientFactory;
  final Duration timeout;

  @override
  Future<Uint8List> get(Uri uri, {required int maxBytes}) async {
    final client = clientFactory();
    try {
      return await _read(client, uri, maxBytes).timeout(timeout);
    } finally {
      // Also cancels transport activity after timeout. No automatic retries.
      client.close();
    }
  }

  Future<Uint8List> _read(http.Client client, Uri uri, int maxBytes) async {
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Expected public HTTPS URL');
    }
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    // No API key, user address, Authorization or application cookies.
    final response = await client.send(request);
    if (response.statusCode != 200 ||
        response.headers['content-type']
                ?.split(';')
                .first
                .trim()
                .toLowerCase() !=
            'application/json' ||
        (response.contentLength != null &&
            response.contentLength! > maxBytes)) {
      throw const FormatException('Invalid dataset response');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Dataset response too large');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }
}
