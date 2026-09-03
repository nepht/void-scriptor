enum ApiMethod { get, post, put, patch, delete }

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.body,
  });

  final ApiMethod method;
  final String uri;
  final Map<String, String> headers;
  final String? body;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    this.headers = const {},
    this.body = '',
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

abstract interface class ApiTransport {
  Future<ApiResponse> send(ApiRequest request);
}

class ApiClient {
  const ApiClient(this.transport);

  final ApiTransport transport;

  Future<ApiResponse> send(ApiRequest request) async {
    if (request.uri.trim().isEmpty) {
      throw ArgumentError.value(request.uri, 'uri', 'URI must not be blank.');
    }
    return transport.send(request);
  }
}
