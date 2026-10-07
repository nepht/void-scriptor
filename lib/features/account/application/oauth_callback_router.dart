import 'dart:async';

/// Validated callback envelope delivered by the desktop protocol handler.
///
/// The authorization code and state remain in memory only; callers must pass
/// them directly to the active OAuth flow and must not log this object.
final class OAuthCallbackEnvelope {
  const OAuthCallbackEnvelope({
    required this.uri,
    required this.code,
    required this.state,
    this.error,
    this.errorDescription,
  });

  final Uri uri;
  final String? code;
  final String? state;
  final String? error;
  final String? errorDescription;

  bool get isAuthorizationSuccess =>
      error == null && code != null && state != null;
}

/// Parses only the registered `vscriptor://oauth/callback` callback route.
///
/// This class deliberately does not complete OAuth itself. Completion requires
/// the active in-memory request, which is owned by [AccountOAuthFlow].
final class OAuthCallbackRouter {
  const OAuthCallbackRouter._();

  static OAuthCallbackEnvelope? parse(Uri uri) {
    if (uri.scheme != 'vscriptor' ||
        uri.host != 'oauth' ||
        uri.path != '/callback' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.queryParameters.isEmpty) {
      return null;
    }

    String? clean(String? value) {
      final normalized = value?.trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    }

    return OAuthCallbackEnvelope(
      uri: uri,
      code: clean(uri.queryParameters['code']),
      state: clean(uri.queryParameters['state']),
      error: clean(uri.queryParameters['error']),
      errorDescription: clean(uri.queryParameters['error_description']),
    );
  }

  /// Extracts the callback passed by the native runner without logging it.
  static Uri? uriFromArguments(Iterable<String> arguments) {
    const prefix = '--oauth-callback=';
    for (final argument in arguments) {
      if (!argument.startsWith(prefix)) continue;
      final uri = Uri.tryParse(argument.substring(prefix.length));
      if (uri == null || parse(uri) == null) return null;
      return uri;
    }
    return null;
  }
}

/// Small injectable boundary used by desktop bootstrap and tests.
abstract interface class OAuthCallbackSource {
  Stream<Uri> get callbacks;
}

final class MemoryOAuthCallbackSource implements OAuthCallbackSource {
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get callbacks => _controller.stream;

  void add(Uri uri) => _controller.add(uri);

  Future<void> dispose() => _controller.close();
}
