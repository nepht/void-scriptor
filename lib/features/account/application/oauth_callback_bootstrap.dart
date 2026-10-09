import 'oauth_callback_router.dart';

/// Callback used by desktop bootstrap to complete the active OAuth flow.
typedef OAuthCallbackCompletion = Future<void> Function(Uri callback);

/// Converts the native runner argument into a validated callback and hands it
/// to the active OAuth composition root. OAuth values remain in memory only.
final class OAuthCallbackBootstrap {
  const OAuthCallbackBootstrap({required this.complete});

  final OAuthCallbackCompletion complete;

  /// Returns `true` when a syntactically valid callback was found and handed
  /// to the completion boundary. Completion failures are deliberately exposed
  /// as `false` without logging code, state, or token material.
  Future<bool> process(Iterable<String> arguments) async {
    final callback = OAuthCallbackRouter.uriFromArguments(arguments);
    if (callback == null) return false;
    try {
      await complete(callback);
      return true;
    } on Object {
      return false;
    }
  }
}
