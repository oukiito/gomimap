// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomimap/data/dataset_download.dart';
import 'package:http/http.dart' as http;

class StreamingClient extends http.BaseClient {
  StreamingClient(this.reply);
  final Future<http.StreamedResponse> Function(http.BaseRequest) reply;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      reply(request);
  @override
  void close() => closed = true;
}

void main() {
  final uri = Uri.parse('https://example.invalid/manifest.json');
  test(
    'request has no secret/query/redirect; consumes only bounded JSON bytes',
    () async {
      final client = StreamingClient((request) async {
        expect(request.followRedirects, isFalse);
        expect(request.headers, {'Accept': 'application/json'});
        expect(request.url, uri);
        return http.StreamedResponse(
          Stream.value(utf8.encode('{}')),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final download = HttpDatasetDownload(clientFactory: () => client);
      expect(await download.get(uri, maxBytes: 2), utf8.encode('{}'));
      expect(client.closed, isTrue);
    },
  );
  for (final fault in ['status', 'redirect', 'type', 'length', 'stream']) {
    test('rejects $fault, closes client and does not retry', () async {
      var calls = 0;
      final client = StreamingClient((request) async {
        calls++;
        return http.StreamedResponse(
          Stream.fromIterable([
            utf8.encode('{}'),
            if (fault == 'stream') utf8.encode('!'),
          ]),
          fault == 'status'
              ? 500
              : fault == 'redirect'
              ? 302
              : 200,
          headers: {
            'content-type': fault == 'type' ? 'text/html' : 'application/json',
          },
          contentLength: fault == 'length' ? 10 : null,
        );
      });
      expect(
        () =>
            HttpDatasetDownload(clientFactory: () => client)
                .get(uri, maxBytes: 2),
        throwsFormatException,
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.closed, isTrue);
      expect(calls, 1);
    });
  }
  test(
    'whole-response timeout includes a stalled body and closes transport',
    () async {
      final client = StreamingClient(
        (request) async => http.StreamedResponse(
          const Stream<List<int>>.empty().asyncExpand((_) => Stream.value([])),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final body = StreamController<List<int>>();
      final stalled = StreamingClient(
        (request) async => http.StreamedResponse(
          body.stream,
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      expect(
        () => HttpDatasetDownload(
          clientFactory: () => stalled,
          timeout: const Duration(milliseconds: 10),
        ).get(uri, maxBytes: 100),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(stalled.closed, isTrue);
      await body.close();
      client.close();
    },
  );
  test('invalid public URL is refused before request', () async {
    final client = StreamingClient(
      (_) async => throw StateError('must not send'),
    );
    for (final url in [
      'http://example.invalid/a',
      'https://user@example.invalid/a',
      'https://example.invalid/a?q=home',
      'https://example.invalid/a#home',
    ]) {
      await expectLater(
        () =>
            HttpDatasetDownload(clientFactory: () => client)
                .get(Uri.parse(url), maxBytes: 2),
        throwsFormatException,
      );
    }
  });
}
