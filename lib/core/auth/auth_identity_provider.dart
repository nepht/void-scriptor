import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';

abstract interface class AuthIdentityProvider {
  Future<AuthSession> signIn({required String email, required String password});
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
