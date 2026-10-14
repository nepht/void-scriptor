import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_brokered_http_client.dart';

void main() {
  group('119.9 Brokered HTTP Client', () {
    late HttpServer server;
    late Uri baseUri;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUri = Uri(scheme: 'http', host: '127.0.0.1', port: server.port);
      server.listen((request) async {
        switch (request.uri.path) {
          case '/slow':
            await Future<void>.delayed(const Duration(seconds: 2));
          case '/redirect':
            request.response.statusCode = HttpStatus.found;
            await request.response.close();
            return;
        }
        request.response.headers.contentType = ContentType.text;
        request.response.write(
          request.uri.path == '/large' ? '123456789' : 'ok',
        );
        await request.response.close();
      });
    });

    tearDown(() async => server.close(force: true));

    BrokeredHttpClient buildClient({
      Duration timeout = const Duration(seconds: 5),
      int maxResponseBytes = 1024 * 1024,
    }) {
      return BrokeredHttpClient(
        allowedHosts: <String>{'127.0.0.1'},
        allowInsecureLocalhost: true,
        timeout: timeout,
        maxResponseBytes: maxResponseBytes,
      );
    }

    test('enforces TLS and the declared host allowlist', () async {
      final client = BrokeredHttpClient(allowedHosts: <String>{'127.0.0.1'});

      await expectLater(
        client.get(baseUri),
        throwsA(
          isA<BrokeredHttpException>().having(
            (error) => error.message,
            'message',
            'tls_required',
          ),
        ),
      );
      await expectLater(
        client.get(Uri.parse('https://not-allowed.invalid/')),
        throwsA(
          isA<BrokeredHttpException>().having(
            (error) => error.message,
            'message',
            'host_not_allowlisted',
          ),
        ),
      );
    });

    test('redacts sensitive request headers in the audit trail', () async {
      final client = buildClient();

      final response = await client.get(
        baseUri,
        headers: <String, String>{'Authorization': 'Bearer secret-value'},
      );

      expect(response.body, 'ok');
      expect(client.audit.single.headers['authorization'], '[REDACTED]');
      expect(client.audit.single.statusCode, 200);
    });

    test('refuses redirects instead of following them', () async {
      final client = buildClient();

      await expectLater(
        client.get(Uri.parse('$baseUri/redirect')),
        throwsA(
          isA<BrokeredHttpException>().having(
            (error) => error.message,
            'message',
            'redirect_denied',
          ),
        ),
      );
    });

    test('rejects a response larger than the configured limit', () async {
      final client = buildClient(maxResponseBytes: 4);

      await expectLater(
        client.get(Uri.parse('$baseUri/large')),
        throwsA(
          isA<BrokeredHttpException>().having(
            (error) => error.message,
            'message',
            'response_limit_exceeded',
          ),
        ),
      );
    });

    test('times out a slow request with a typed error', () async {
      final client = buildClient(timeout: const Duration(milliseconds: 50));

      await expectLater(
        client.get(Uri.parse('$baseUri/slow')),
        throwsA(
          isA<BrokeredHttpException>().having(
            (error) => error.message,
            'message',
            'timeout',
          ),
        ),
      );
    });

    test('cancels an in-flight request by id', () async {
      final client = buildClient();
      final pending = client.get(
        Uri.parse('$baseUri/slow'),
        requestId: 'cancel-me',
      );
      final expectation = expectLater(
        pending,
        throwsA(isA<BrokeredHttpException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await client.cancel('cancel-me');

      await expectation;
    });

    test('validates the canonical manifest contract', () {
      expect(BrokeredHttpClient.validateCanonicalManifest(), isEmpty);
      final missing = <String, dynamic>{
        'canonical_step': '119.9',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{},
      };
      expect(
        BrokeredHttpClient.validateManifest(missing),
        containsAll(<String>[
          'acceptance_missing:allowlist',
          'acceptance_missing:response_limit',
        ]),
      );
    });
  });
}
