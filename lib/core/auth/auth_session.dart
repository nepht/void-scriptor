import 'auth_status.dart';

class AuthSession {
  const AuthSession({
    required this.status,
    this.userId,
    this.displayName,
    this.email,
  });

  final AuthStatus status;
  final String? userId;
  final String? displayName;
  final String? email;

  const AuthSession.checking()
    : status = AuthStatus.checking,
      userId = null,
      displayName = null,
      email = null;

  const AuthSession.loggedOut()
    : status = AuthStatus.unauthenticated,
      userId = null,
      displayName = null,
      email = null;

  const AuthSession.guest()
    : status = AuthStatus.guest,
      userId = null,
      displayName = 'Guest',
      email = null;

  const AuthSession.offline()
    : status = AuthStatus.offline,
      userId = null,
      displayName = 'Offline User',
      email = null;
}
