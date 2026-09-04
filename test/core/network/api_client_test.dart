import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/network/api_client.dart';

void main() {
  test('api client delegates a request to the injected transport', () async {
    final transport = _FakeTransport(
      const ApiResponse(
        statusCode: 201,
        headers: {'content-type': 'application/json'},
        body: '{"id":"p1"}',
      ),
    );
    final client = ApiClient(transport);

    final response = await client.send(
      const ApiRequest(
        method: ApiMethod.post,
        uri: 'https://example.invalid/projects',
        headers: {'accept': 'application/json'},
        body: '{"name":"Void"}',
      ),
    );

    expect(transport.lastRequest?.method, ApiMethod.post);
    expect(transport.lastRequest?.uri, 'https://example.invalid/projects');
    expect(transport.lastRequest?.body, '{"name":"Void"}');
    expect(response.statusCode, 201);
    expect(response.body, '{"id":"p1"}');
  });

  test('api client rejects blank request URIs before transport I/O', () async {
    final transport = _FakeTransport(const ApiResponse(statusCode: 200));
    final client = ApiClient(transport);

    await expectLater(
      client.send(const ApiRequest(method: ApiMethod.get, uri: '  ')),
      throwsArgumentError,
    );
    expect(transport.lastRequest, isNull);
  });
}

class _FakeTransport implements ApiTransport {
  _FakeTransport(this.response);

  final ApiResponse response;
  ApiRequest? lastRequest;

  @override
  Future<ApiResponse> send(ApiRequest request) async {
    lastRequest = request;
    return response;
  }
}
