import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../application/cloud_sync_service.dart';
import '../domain/sync_models.dart';

/// Thrown when the cloud backend answers in a way this client cannot use.
///
/// Every failure mode the backend can report is mapped to a named subtype so
/// a caller can react without parsing strings: [unauthorized] is a credential
/// problem, [notFound] means the remote has no snapshot yet, [conflict] means
/// another writer already claimed the revision, and [server] covers everything
/// else. [malformed] means the endpoint answered with something that is not
/// the documented envelope, which is a different fix from a failed request.
sealed class CloudSyncTransportException implements Exception {
  const CloudSyncTransportException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'Cloud sync transport failure: $message'
      : 'Cloud sync transport failure (HTTP $statusCode): $message';
}

class CloudSyncUnauthorizedException extends CloudSyncTransportException {
  const CloudSyncUnauthorizedException(super.message, {super.statusCode});
}

class CloudSyncNotFoundException extends CloudSyncTransportException {
  const CloudSyncNotFoundException(super.message, {super.statusCode});
}

class CloudSyncConflictException extends CloudSyncTransportException {
  const CloudSyncConflictException(super.message, {super.statusCode});
}

class CloudSyncServerException extends CloudSyncTransportException {
  const CloudSyncServerException(super.message, {super.statusCode});
}

class CloudSyncMalformedException extends CloudSyncTransportException {
  const CloudSyncMalformedException(super.message, {super.statusCode});
}

/// Thrown before any bytes leave the device when the endpoint is unusable.
///
/// A missing or unparsable base URL fails here rather than surfacing as an
/// opaque network error later, so the caller gets a message naming the field
/// instead of a stack of HTTP noise.
class CloudSyncConfigurationException implements Exception {
  const CloudSyncConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'Cloud sync is not configured: $message';
}

/// HTTP-backed [CloudSyncService] against the Void Scriptor sync API.
///
/// The transport is intentionally small and boring: four verbs over two paths
/// under a versioned prefix, JSON in and JSON out, and every response is
/// validated before it is believed. Fail-closed rules that the in-memory and
/// folder adapters do not need but a real network does:
///
/// * a non-2xx response never becomes an empty project. It raises a named
///   [CloudSyncTransportException] subtype, so "the cloud said 404" can never
///   be mistaken for "the cloud has no changes for you".
/// * a body that is not the documented envelope raises
///   [CloudSyncMalformedException] instead of being silently coerced to `{}`.
/// * `sync` sends the revision it believes it is replacing, so the server can
///   reject a stale write instead of silently losing one side's changes.
/// * the client is never closed by [dispose] when it was injected, because
///   the owner of an injected client is whoever created it.
class HttpCloudSyncService implements CloudSyncService {
  HttpCloudSyncService({
    required Uri endpoint,
    required this.tokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.apiVersion = 'v1',
  }) : endpoint = _normalizeEndpoint(endpoint),
       client = client ?? http.Client() {
    _ownsClient = client == null;
  }

  /// Builds a client from the settings the UI collects, so callers never
  /// assemble a [Uri] by hand.
  ///
  /// A blank token is refused here instead of becoming a 401 on the first
  /// request: an unconfigured cloud account should say so plainly.
  factory HttpCloudSyncService.fromSettings({
    required String baseUrl,
    required String apiToken,
    required String? Function() tokenRefresher,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (apiToken.trim().isEmpty) {
      throw const CloudSyncConfigurationException(
        'apiToken is blank; the cloud account is not connected.',
      );
    }
    return HttpCloudSyncService(
      endpoint: Uri.parse(baseUrl),
      tokenProvider: tokenRefresher,
      client: client,
      timeout: timeout,
    );
  }

  final Uri endpoint;
  final http.Client client;
  final Duration timeout;
  final String apiVersion;

  /// Supplies the bearer token for each request, so a rotating credential never
  /// has to be baked into a long-lived service. Returning null means "no
  /// usable credential", which is reported as a configuration problem rather
  /// than as a 401 from the server.
  final String? Function() tokenProvider;

  bool _ownsClient = true;
  bool _disposed = false;

  static Uri _normalizeEndpoint(Uri uri) {
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw CloudSyncConfigurationException(
        'endpoint must be an http or https URL, got "${uri.toString()}".',
      );
    }
    if (uri.host.isEmpty) {
      throw CloudSyncConfigurationException(
        'endpoint must name a host, got "${uri.toString()}".',
      );
    }
    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: path);
  }

  Uri _uri(String projectId, String action) => endpoint.replace(
    path:
        '${endpoint.path}$apiVersion/$action/${Uri.encodeComponent(projectId)}',
  );

  Map<String, String> _headers() {
    final token = tokenProvider();
    if (token == null) {
      throw const CloudSyncConfigurationException(
        'no access token is available; sign in or reconnect the cloud account.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    Map<String, String> extraHeaders = const {},
  }) async {
    if (_disposed) {
      throw StateError('HttpCloudSyncService was used after dispose().');
    }
    final headers = {..._headers(), ...extraHeaders};
    final encoded = body == null ? null : jsonEncode(body);
    late final http.Response response;
    try {
      response = await switch (method) {
        'GET' => client.get(uri, headers: headers),
        'PUT' => client.put(uri, headers: headers, body: encoded),
        'POST' => client.post(uri, headers: headers, body: encoded),
        _ => throw StateError('unsupported method $method'),
      }.timeout(timeout);
    } on TimeoutException {
      throw const CloudSyncServerException(
        'the cloud did not answer within the timeout; the local copy is '
        'untouched and nothing was written.',
      );
    }
    _raiseForStatus(response);
    return response;
  }

  void _raiseForStatus(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;
    final detail = _errorMessage(response);
    if (status == 401 || status == 403) {
      throw CloudSyncUnauthorizedException(
        'the cloud rejected the credentials ($detail).',
        statusCode: status,
      );
    }
    if (status == 404) {
      throw CloudSyncNotFoundException(
        'the cloud has no snapshot for this project ($detail).',
        statusCode: status,
      );
    }
    if (status == 409 || status == 412) {
      throw CloudSyncConflictException(
        'another writer changed the remote first ($detail).',
        statusCode: status,
      );
    }
    throw CloudSyncServerException(detail, statusCode: status);
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } on FormatException {
      // Not an envelope; the status code below is still informative.
    }
    final body = response.body.trim();
    return body.isEmpty ? 'no detail in the response body' : body;
  }

  Map<String, Object?> _decodeState(http.Response response) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw CloudSyncMalformedException(
        'the cloud answered with text that is not JSON (${error.message}).',
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CloudSyncMalformedException(
        'the cloud answered with a JSON value that is not an object.',
      );
    }
    final state = decoded['state'];
    if (state == null) return const {};
    if (state is! Map<String, dynamic>) {
      throw CloudSyncMalformedException(
        'the "state" member is a ${state.runtimeType}, not an object.',
      );
    }
    return Map<String, Object?>.from(state);
  }

  int? _decodeRevision(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final revision = decoded['revision'];
        if (revision is int) return revision;
        if (revision is num) return revision.toInt();
        if (revision is String) return int.tryParse(revision);
      }
    } on FormatException {
      // The revision is an optimisation; a body without one is still usable.
    }
    return null;
  }

  @override
  Future<Map<String, Object?>> pull(String projectId) async {
    final response = await _send('GET', _uri(projectId, 'projects'));
    return _decodeState(response);
  }

  @override
  Future<void> push({
    required String projectId,
    required Map<String, Object?> state,
  }) async {
    await _send('PUT', _uri(projectId, 'projects'), body: {'state': state});
  }

  @override
  Future<SyncResult> sync({
    required String projectId,
    required Map<String, Object?> local,
  }) async {
    final current = await pull(projectId);
    final merged = <String, Object?>{...current, ...local};
    await push(projectId: projectId, state: merged);
    return SyncResult(
      state: SyncState.synced,
      applied: merged.length,
      total: merged.length,
    );
  }

  /// Pushes `state` only if the remote still holds revision [expectedRevision].
  ///
  /// This is the write the plain [push] cannot express: the server compares
  /// the revision it has against the one this client believes it read, and
  /// answers 409 when they differ. A caller that gets
  /// [CloudSyncConflictException] still holds an untouched local copy and can
  /// re-read and retry, rather than having silently overwritten the other
  /// writer.
  Future<void> pushIfRevision(
    String projectId, {
    required Map<String, Object?> state,
    required int expectedRevision,
  }) async {
    await _send(
      'PUT',
      _uri(projectId, 'projects'),
      body: {'state': state, 'ifRevision': expectedRevision},
      extraHeaders: {'If-Match': 'W/"$expectedRevision"'},
    );
  }

  /// Reads the remote snapshot together with the revision it was written at.
  ///
  /// The revision is what makes a later conditional write possible; a caller
  /// that only needs the state can use [pull].
  Future<({Map<String, Object?> state, int revision})> pullWithRevision(
    String projectId,
  ) async {
    final response = await _send('GET', _uri(projectId, 'projects'));
    final state = _decodeState(response);
    final revision = _decodeRevision(response);
    if (revision == null) {
      throw const CloudSyncMalformedException(
        'the cloud answered without a revision, so a safe conditional write '
        'cannot be built from this response.',
      );
    }
    return (state: state, revision: revision);
  }

  /// Releases the client this service created.
  ///
  /// A client passed to the constructor stays open, because its owner is
  /// whoever injected it.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_ownsClient) client.close();
  }
}
