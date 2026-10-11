import 'auth_status.dart';

class AuthSession {
  const AuthSession({
    required this.status,
    this.userId,
    this.displayName,
    this.email,
    this.identityProvider,
    this.linkedIdentityProviders = const <String>[],
  });

  final AuthStatus status;
  final String? userId;
  final String? displayName;
  final String? email;

  /// The remote identity provider that authenticated this session.
  ///
  /// This is deliberately metadata only (never a token or credential). It is
  /// optional so local Guest/Offline sessions and older persisted sessions
  /// remain valid. It is intentionally kept out of the local session JSON;
  /// the server-backed provider is the source of truth on the next restore.
  /// The Account & Cloud Center uses it to show the provider that actually
  /// authenticated the account instead of guessing Email.
  final String? identityProvider;

  /// Provider identities linked to the same remote account. This is metadata
  /// only; credentials and tokens never enter the session model.
  final List<String> linkedIdentityProviders;

  const AuthSession.checking()
    : status = AuthStatus.checking,
      userId = null,
      displayName = null,
      email = null,
      identityProvider = null,
      linkedIdentityProviders = const <String>[];

  const AuthSession.loggedOut()
    : status = AuthStatus.unauthenticated,
      userId = null,
      displayName = null,
      email = null,
      identityProvider = null,
      linkedIdentityProviders = const <String>[];

  const AuthSession.guest()
    : status = AuthStatus.guest,
      userId = null,
      displayName = 'Guest',
      email = null,
      identityProvider = null,
      linkedIdentityProviders = const <String>[];

  const AuthSession.offline()
    : status = AuthStatus.offline,
      userId = null,
      displayName = 'Offline User',
      email = null,
      identityProvider = null,
      linkedIdentityProviders = const <String>[];
}
