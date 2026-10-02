import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:void_scriptor/features/collaboration/application/cloud_sync_service.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';
import 'package:void_scriptor/features/collaboration/infrastructure/http_cloud_sync_service.dart';

void main() {
  Uri endpoint() => Uri.parse('https://cloud.example.test/api');

  HttpCloudSyncService serviceWith(
    Future<http.Response> Function(http.Request request) handler, {
    Uri? overrideEndpoint,
    Duration? timeout,
  }) {
    return HttpCloudSyncService(
      endpoint: overrideEndpoint ?? endpoint(),
      tokenProvider: () => 'token-123',
      client: MockClient(handler),
      timeout: timeout ?? const Duration(seconds: 5),
    );
  }

  group('configuration is refused before any request leaves the device', () {
    test('a non-http scheme is named in the message', () {
      expect(
        () => HttpCloudSyncService(
          endpoint: Uri.parse('ftp://cloud.example.test'),
          tokenProvider: () => 'token',
        ),
        throwsA(
          isA<CloudSyncConfigurationException>().having(
            (e) => e.message,
            'message',
            contains('http or https'),
          ),
        ),
      );
    });

    test('a scheme without a host is refused', () {
      expect(
        () => HttpCloudSyncService(
          endpoint: Uri.parse('https:///api'),
          tokenProvider: () => 'token',
        ),
        throwsA(isA<CloudSyncConfigurationException>()),
      );
    });

    test('a blank api token is refused by the settings factory', () {
      expect(
        () => HttpCloudSyncService.fromSettings(
          baseUrl: 'https://cloud.example.test',
          apiToken: '   ',
          tokenRefresher: () => 'unused',
        ),
        throwsA(
          isA<CloudSyncConfigurationException>().having(
            (e) => e.message,
            'message',
            contains('apiToken is blank'),
          ),
        ),
      );
    });

    test('a provider that returns no token fails as configuration', () async {
      final service = HttpCloudSyncService(
        endpoint: endpoint(),
        tokenProvider: () => null,
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncConfigurationException>().having(
            (e) => e.message,
            'message',
            contains('no access token'),
          ),
        ),
      );
    });
  });

  group('a non-2xx answer never becomes an empty project', () {
    test('401 raises unauthorized, not an empty map', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({'message': 'token expired'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncUnauthorizedException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('token expired')),
        ),
      );
    });

    test('403 is also unauthorized', () async {
      final service = serviceWith(
        (_) async => http.Response('{"message":"no scope"}', 403),
      );
      await expectLater(
        service.pull('p1'),
        throwsA(isA<CloudSyncUnauthorizedException>()),
      );
    });

    test('404 raises not found so it is never read as "no changes"', () async {
      final service = serviceWith(
        (_) async => http.Response('{"message":"unknown project"}', 404),
      );
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncNotFoundException>().having(
            (e) => e.message,
            'message',
            contains('no snapshot'),
          ),
        ),
      );
    });

    test('409 raises conflict so a stale write is visible', () async {
      final service = serviceWith((_) async => http.Response('{}', 409));
      await expectLater(
        service.pushIfRevision(
          'p1',
          state: const {'a': 1},
          expectedRevision: 3,
        ),
        throwsA(
          isA<CloudSyncConflictException>().having(
            (e) => e.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });

    test('412 is treated as a conflict too', () async {
      final service = serviceWith((_) async => http.Response('{}', 412));
      await expectLater(
        service.pushIfRevision(
          'p1',
          state: const {'a': 1},
          expectedRevision: 3,
        ),
        throwsA(isA<CloudSyncConflictException>()),
      );
    });

    test('500 raises a server failure naming the status', () async {
      final service = serviceWith((_) async => http.Response('boom', 500));
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('boom')),
        ),
      );
    });

    test('a body that is not JSON falls back to the raw detail', () async {
      final service = serviceWith(
        (_) async => http.Response('<html>gateway</html>', 502),
      );
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncServerException>().having(
            (e) => e.message,
            'message',
            contains('gateway'),
          ),
        ),
      );
    });

    test('an empty error body still produces a readable message', () async {
      final service = serviceWith((_) async => http.Response('', 503));
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncServerException>().having(
            (e) => e.message,
            'message',
            contains('no detail'),
          ),
        ),
      );
    });
  });

  group('a malformed answer is refused instead of coerced', () {
    test('text that is not JSON raises malformed', () async {
      final service = serviceWith((_) async => http.Response('not json', 200));
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncMalformedException>().having(
            (e) => e.message,
            'message',
            contains('not JSON'),
          ),
        ),
      );
    });

    test('a JSON array at the top level raises malformed', () async {
      final service = serviceWith((_) async => http.Response('[1,2,3]', 200));
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncMalformedException>().having(
            (e) => e.message,
            'message',
            contains('not an object'),
          ),
        ),
      );
    });

    test('a non-object state member raises malformed', () async {
      final service = serviceWith(
        (_) async => http.Response('{"state":"broken"}', 200),
      );
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncMalformedException>().having(
            (e) => e.message,
            'message',
            contains('"state" member'),
          ),
        ),
      );
    });

    test('a missing revision blocks a conditional write', () async {
      final service = serviceWith(
        (_) async => http.Response('{"state":{"a":1}}', 200),
      );
      await expectLater(
        service.pullWithRevision('p1'),
        throwsA(
          isA<CloudSyncMalformedException>().having(
            (e) => e.message,
            'message',
            contains('without a revision'),
          ),
        ),
      );
    });
  });

  group('the wire shape is what the contract documents', () {
    test('pull reads GET v1/projects/<id> with a bearer token', () async {
      Uri? seen;
      String? auth;
      String? accept;
      final service = serviceWith((request) async {
        seen = request.url;
        auth = request.headers['Authorization'];
        accept = request.headers['Accept'];
        return http.Response('{"state":{"a":"1"}}', 200);
      });
      await service.pull('saga d53c8787');
      expect(
        seen.toString(),
        'https://cloud.example.test/api/v1/projects/saga%20d53c8787',
      );
      expect(auth, 'Bearer token-123');
      expect(accept, 'application/json');
    });

    test('a base URL without a trailing slash still builds one path', () async {
      Uri? seen;
      final service = serviceWith((request) async {
        seen = request.url;
        return http.Response('{"state":{}}', 200);
      }, overrideEndpoint: Uri.parse('https://cloud.example.test/api'));
      await service.pull('p1');
      expect(seen.toString(), 'https://cloud.example.test/api/v1/projects/p1');
    });

    test('a base URL with a trailing slash does not double up', () async {
      Uri? seen;
      final service = serviceWith((request) async {
        seen = request.url;
        return http.Response('{"state":{}}', 200);
      }, overrideEndpoint: Uri.parse('https://cloud.example.test/api/'));
      await service.pull('p1');
      expect(seen.toString(), 'https://cloud.example.test/api/v1/projects/p1');
    });

    test('push sends PUT with the state envelope', () async {
      String? method;
      Map<String, dynamic>? body;
      final service = serviceWith((request) async {
        method = request.method;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 204);
      });
      await service.push(projectId: 'p1', state: const {'a': 1});
      expect(method, 'PUT');
      expect(body, {
        'state': {'a': 1},
      });
    });

    test(
      'a conditional push carries both the body and the If-Match header',
      () async {
        String? ifMatch;
        Map<String, dynamic>? body;
        final service = serviceWith((request) async {
          ifMatch = request.headers['If-Match'];
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        });
        await service.pushIfRevision(
          'p1',
          state: const {'a': 1},
          expectedRevision: 7,
        );
        expect(ifMatch, 'W/"7"');
        expect(body, {
          'state': {'a': 1},
          'ifRevision': 7,
        });
      },
    );

    test('a project id is URL encoded, never spliced into the path', () async {
      Uri? seen;
      final service = serviceWith((request) async {
        seen = request.url;
        return http.Response('{"state":{}}', 200);
      });
      await service.pull('a/b?c=d#e');
      expect(seen.toString(), contains('a%2Fb%3Fc%3Dd%23e'));
    });
  });

  group('revision handling', () {
    test('an integer revision is read as an int', () async {
      final service = serviceWith(
        (_) async => http.Response('{"state":{"a":1},"revision":12}', 200),
      );
      final snapshot = await service.pullWithRevision('p1');
      expect(snapshot.revision, 12);
      expect(snapshot.state, {'a': 1});
    });

    test('a string revision is parsed', () async {
      final service = serviceWith(
        (_) async => http.Response('{"state":{},"revision":"12"}', 200),
      );
      expect((await service.pullWithRevision('p1')).revision, 12);
    });

    test('a double revision is narrowed to an int', () async {
      final service = serviceWith(
        (_) async => http.Response('{"state":{},"revision":12.0}', 200),
      );
      expect((await service.pullWithRevision('p1')).revision, 12);
    });
  });

  group('sync merges remote and local and reports honestly', () {
    test('a remote key local does not have survives the merge', () async {
      final store = <String, Object?>{'remote-only': 'kept'};
      final service = serviceWith((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'state': store}), 200);
        }
        store
          ..clear()
          ..addAll(
            (jsonDecode(request.body) as Map<String, dynamic>)['state']
                as Map<String, Object?>,
          );
        return http.Response('', 204);
      });
      final result = await service.sync(
        projectId: 'p1',
        local: const {'local-only': 'added'},
      );
      expect(result.state, SyncState.synced);
      expect(result.applied, 2);
      expect(result.complete, isTrue);
      expect(store, {'remote-only': 'kept', 'local-only': 'added'});
    });

    test('a pull failure aborts sync before anything is written', () async {
      var writes = 0;
      final service = serviceWith((request) async {
        if (request.method == 'GET') return http.Response('{}', 404);
        writes++;
        return http.Response('', 204);
      });
      await expectLater(
        service.sync(projectId: 'p1', local: const {'a': 1}),
        throwsA(isA<CloudSyncNotFoundException>()),
      );
      expect(writes, 0);
    });
  });

  group('timeouts and lifecycle', () {
    test('a slow backend is reported as a timeout, not a hang', () async {
      final service = serviceWith((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      }, timeout: const Duration(milliseconds: 20));
      await expectLater(
        service.pull('p1'),
        throwsA(
          isA<CloudSyncServerException>().having(
            (e) => e.message,
            'message',
            contains('within the timeout'),
          ),
        ),
      );
    });

    test('a service used after dispose fails loudly', () async {
      final service = serviceWith((_) async => http.Response('{}', 200));
      service.dispose();
      await expectLater(service.pull('p1'), throwsStateError);
    });

    test('dispose twice is a no-op', () async {
      final service = serviceWith((_) async => http.Response('{}', 200));
      service
        ..dispose()
        ..dispose();
    });

    test('an injected client is not closed by dispose', () async {
      var closed = false;
      final client = _ClosableMockClient(() => closed = true);
      final service = HttpCloudSyncService(
        endpoint: endpoint(),
        tokenProvider: () => 'token',
        client: client,
      );
      service.dispose();
      expect(closed, isFalse);
    });
  });

  group('end to end against a real local HTTP server', () {
    late HttpServer server;
    late Uri serverEndpoint;
    late Map<String, Object?> remoteState;
    late int revision;
    late List<String> requestLog;

    setUp(() async {
      remoteState = <String, Object?>{};
      revision = 1;
      requestLog = <String>[];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final segments = request.uri.pathSegments;
        requestLog.add('${request.method} ${request.uri.path}');
        // /api/v1/projects/<id>
        if (segments.length < 4 || segments[2] != 'projects') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final projectId = Uri.decodeComponent(segments[3]);
        if (projectId == 'forbidden') {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('{"message":"no access to $projectId"}');
          await request.response.close();
          return;
        }
        final ifMatch = request.headers.value(HttpHeaders.ifMatchHeader);
        if (request.method == 'PUT') {
          final decoded =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          final wantsRevision = decoded['ifRevision'];
          if (ifMatch != null || wantsRevision != null) {
            final expected = wantsRevision is int
                ? wantsRevision
                : int.tryParse(ifMatch!.replaceAll(RegExp(r'\D'), ''));
            if (expected != null && expected != revision) {
              request.response.statusCode = HttpStatus.conflict;
              request.response.write(
                '{"message":"revision moved to $revision"}',
              );
              await request.response.close();
              return;
            }
          }
          remoteState
            ..clear()
            ..addAll(decoded['state'] as Map<String, Object?>);
          revision++;
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          return;
        }
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'state': remoteState, 'revision': revision}));
        await request.response.close();
      });
      serverEndpoint = Uri.parse(
        'http://${server.address.address}:${server.port}/api',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('a first push then pull roundtrips real bytes over TCP', () async {
      final service = HttpCloudSyncService(
        endpoint: serverEndpoint,
        tokenProvider: () => 'token-live',
        timeout: const Duration(seconds: 10),
      );
      addTearDown(service.dispose);

      await service.push(
        projectId: 'saga-d53c8787',
        state: const {
          'character:reika': {'name': 'Reika Kokuen', 'age': 17},
          'chapter:1': {'title': 'Arc 02 Bab 1'},
        },
      );
      final pulled = await service.pull('saga-d53c8787');
      expect(pulled['character:reika'], {'name': 'Reika Kokuen', 'age': 17});
      expect(pulled['chapter:1'], {'title': 'Arc 02 Bab 1'});
      expect(requestLog, [
        'PUT /api/v1/projects/saga-d53c8787',
        'GET /api/v1/projects/saga-d53c8787',
      ]);
    });

    test(
      'a conditional write succeeds when the revision still matches',
      () async {
        final service = HttpCloudSyncService(
          endpoint: serverEndpoint,
          tokenProvider: () => 'token-live',
          timeout: const Duration(seconds: 10),
        );
        addTearDown(service.dispose);

        final snapshot = await service.pullWithRevision('saga');
        await service.pushIfRevision(
          'saga',
          state: {'a': 1},
          expectedRevision: snapshot.revision,
        );
        expect((await service.pull('saga')), {'a': 1});
      },
    );

    test(
      'a stale conditional write is refused and the remote survives',
      () async {
        final service = HttpCloudSyncService(
          endpoint: serverEndpoint,
          tokenProvider: () => 'token-live',
          timeout: const Duration(seconds: 10),
        );
        addTearDown(service.dispose);

        final stale = await service.pullWithRevision('saga');
        // Another writer moves the revision forward.
        await service.push(projectId: 'saga', state: {'other': 'writer'});

        await expectLater(
          service.pushIfRevision(
            'saga',
            state: {'mine': 'writer'},
            expectedRevision: stale.revision,
          ),
          throwsA(
            isA<CloudSyncConflictException>().having(
              (e) => e.message,
              'message',
              contains('revision moved'),
            ),
          ),
        );
        // The losing writer's data did not land and the winner's did.
        expect(await service.pull('saga'), {'other': 'writer'});
      },
    );

    test('sync over the real server merges both sides', () async {
      final service = HttpCloudSyncService(
        endpoint: serverEndpoint,
        tokenProvider: () => 'token-live',
        timeout: const Duration(seconds: 10),
      );
      addTearDown(service.dispose);

      await service.push(projectId: 'saga', state: {'remote': 1});
      final result = await service.sync(projectId: 'saga', local: {'local': 2});
      expect(result.state, SyncState.synced);
      expect(result.complete, isTrue);
      expect(await service.pull('saga'), {'remote': 1, 'local': 2});
    });

    test(
      'a 401 from the real server reaches the caller as unauthorized',
      () async {
        final service = HttpCloudSyncService(
          endpoint: serverEndpoint,
          tokenProvider: () => 'token-live',
          timeout: const Duration(seconds: 10),
        );
        addTearDown(service.dispose);
        await expectLater(
          service.pull('forbidden'),
          throwsA(
            isA<CloudSyncUnauthorizedException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.message, 'message', contains('no access')),
          ),
        );
      },
    );

    test('the token is re-read on every request, not captured once', () async {
      var calls = 0;
      final service = HttpCloudSyncService(
        endpoint: serverEndpoint,
        tokenProvider: () => 'token-${++calls}',
        timeout: const Duration(seconds: 10),
      );
      addTearDown(service.dispose);
      await service.pull('saga');
      await service.pull('saga');
      expect(calls, 2);
    });

    test(
      'the HTTP service satisfies the same contract as the local ones',
      () async {
        // Proves the new adapter is a drop-in for CloudSyncService, so the
        // authority guard and the folder adapter can wrap it unchanged.
        final service = HttpCloudSyncService(
          endpoint: serverEndpoint,
          tokenProvider: () => 'token-live',
          timeout: const Duration(seconds: 10),
        );
        addTearDown(service.dispose);
        expect(service, isA<CloudSyncService>());
        await service.push(projectId: 'contract', state: {'ok': true});
        final result = await service.sync(
          projectId: 'contract',
          local: {'second': true},
        );
        expect(result.state, SyncState.synced);
      },
    );
  });
}

class _ClosableMockClient extends http.BaseClient {
  _ClosableMockClient(this.onClose);

  final void Function() onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(const Stream<List<int>>.empty(), 200);
  }

  @override
  void close() {
    onClose();
    super.close();
  }
}
