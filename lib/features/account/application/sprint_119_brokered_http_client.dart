import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

final class BrokeredHttpException implements Exception {
  const BrokeredHttpException(this.message);

  final String message;

  @override
  String toString() => 'BrokeredHttpException: $message';
}

final class BrokeredHttpResponse {
  const BrokeredHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

final class BrokeredHttpAudit {
  const BrokeredHttpAudit({
    required this.requestId,
    required this.uri,
    required this.headers,
    required this.statusCode,
  });

  final String requestId;
  final Uri uri;
  final Map<String, String> headers;
  final int statusCode;
}

final class BrokeredHttpClient {
  BrokeredHttpClient({
    required Set<String> allowedHosts,
    this.timeout = const Duration(seconds: 15),
    this.maxResponseBytes = 1024 * 1024,
    this.allowInsecureLocalhost = false,
  }) : _allowedHosts = Set.unmodifiable(allowedHosts);

  final Set<String> _allowedHosts;
  final Duration timeout;
  final int maxResponseBytes;
  final bool allowInsecureLocalhost;
  final HttpClient _httpClient = HttpClient()..maxConnectionsPerHost = 4;
  final Map<String, HttpClientRequest> _requests =
      <String, HttpClientRequest>{};
  final List<BrokeredHttpAudit> audit = <BrokeredHttpAudit>[];
  int _requestSequence = 0;

  static const requiredAcceptance = <String>[
    'allowlist',
    'tls',
    'redirect_policy',
    'header_redaction',
    'timeout',
    'cancel',
    'response_limit',
  ];
  static const manifestPath =
      'docs/planning/v1.3/sprint_119_brokered_http_client.json';

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != '119.9') {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }
    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      return <String>['acceptance_missing'];
    }
    for (final name in requiredAcceptance) {
      if (!acceptance.containsKey(name)) {
        diagnostics.add('acceptance_missing:$name');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }

  Future<BrokeredHttpResponse> get(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    String? requestId,
  }) async {
    _validateUri(uri);
    final id = requestId ?? 'request-${++_requestSequence}';
    HttpClientRequest? request;
    try {
      request = await _httpClient.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      request.headers.add('accept', 'application/json, text/plain, */*');
      headers.forEach(request.headers.set);
      _requests[id] = request;
      final response = await request.close().timeout(timeout);
      if (response.isRedirect) {
        throw const BrokeredHttpException('redirect_denied');
      }
      final bytes = await _readLimited(response).timeout(timeout);
      final responseHeaders = <String, String>{};
      headers.forEach((key, value) {
        responseHeaders[key.toLowerCase()] = _isSensitive(key)
            ? '[REDACTED]'
            : value;
      });
      audit.add(
        BrokeredHttpAudit(
          requestId: id,
          uri: uri,
          headers: responseHeaders,
          statusCode: response.statusCode,
        ),
      );
      return BrokeredHttpResponse(
        statusCode: response.statusCode,
        body: utf8.decode(bytes),
      );
    } on BrokeredHttpException {
      rethrow;
    } on TimeoutException {
      request?.abort();
      throw const BrokeredHttpException('timeout');
    } on Object catch (error) {
      throw BrokeredHttpException('request_failed:${error.runtimeType}');
    } finally {
      _requests.remove(id);
    }
  }

  Future<void> cancel(String requestId) async {
    final request = _requests[requestId];
    if (request == null) return;
    request.abort(const BrokeredHttpException('cancelled'));
  }

  void close() => _httpClient.close(force: true);

  void _validateUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final insecureLocalhost =
        allowInsecureLocalhost &&
        (host == '127.0.0.1' || host == 'localhost' || host == '::1');
    if (uri.scheme != 'https' && !insecureLocalhost) {
      throw const BrokeredHttpException('tls_required');
    }
    if (!_allowedHosts.contains(host)) {
      throw const BrokeredHttpException('host_not_allowlisted');
    }
  }

  Future<List<int>> _readLimited(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in response) {
      total += chunk.length;
      if (total > maxResponseBytes) {
        throw const BrokeredHttpException('response_limit_exceeded');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  static bool _isSensitive(String key) => RegExp(
    r'authorization|cookie|token|secret|password|api[-_]key',
    caseSensitive: false,
  ).hasMatch(key);
}
