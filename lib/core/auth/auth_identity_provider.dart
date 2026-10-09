import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

abstract interface class AuthIdentityProvider {
  Future<AuthSession> signIn({required String email, required String password});
}

/// Optional capability implemented by providers that can start a social/OAuth
/// sign-in flow. Keeping it separate from the email/password contract lets
/// local, test, and offline providers remain deliberately small.
abstract interface class SocialAuthIdentityProvider {
  Future<AuthSession> signInWithProvider({required String provider});
}

/// Optional capability used by the composition root to restore a remote
/// account session without making local/offline startup depend on a network.
abstract interface class AuthSessionRestorer {
  Future<AuthSession?> restoreSession();

  Future<void> logoutRemote();
}

class AuthIdentityUnavailable implements Exception {
  const AuthIdentityUnavailable();

  @override
  String toString() => 'Account identity provider is not configured.';
}

class UnavailableAuthIdentityProvider implements AuthIdentityProvider {
  const UnavailableAuthIdentityProvider();

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    throw const AuthIdentityUnavailable();
  }
}

final authIdentityProviderProvider = Provider<AuthIdentityProvider>(
  (ref) => const UnavailableAuthIdentityProvider(),
);
