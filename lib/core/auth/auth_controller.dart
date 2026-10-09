import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_identity_provider.dart';
import 'auth_session.dart';
import 'auth_session_store.dart';
import 'auth_status.dart';

class AuthController extends AsyncNotifier<AuthSession> {
  @override
  FutureOr<AuthSession> build() {
    final initialSession = ref.watch(initialAuthSessionProvider);
    final identityProvider = ref.read(authIdentityProviderProvider);

    // A remote account is authoritative when an opaque web session token is
    // present. Network failure remains non-fatal: the local Guest/Offline
    // session is still allowed to boot.
    if (identityProvider case final AuthSessionRestorer restorer) {
      return _restoreRemoteSession(restorer, initialSession);
    }

    if (initialSession != null) return initialSession;

    // Sprint 145.20: restore a persisted local session (Guest/Offline) so a
    // restart does not force the user back through the login screen.
    return loadLocalFirstAuthSession(ref.read(authSessionStoreProvider));
  }

  Future<AuthSession> _restoreRemoteSession(
    AuthSessionRestorer restorer,
    AuthSession? fallback,
  ) async {
    try {
      final remote = await restorer.restoreSession();
      if (remote != null) return remote;
    } on Object {
      // Fail closed to the local session; never block startup on auth.
    }
    if (fallback != null) return fallback;
    return loadLocalFirstAuthSession(ref.read(authSessionStoreProvider));
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final session = await ref
          .read(authIdentityProviderProvider)
          .signIn(email: email, password: password);
      state = AsyncData(session);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loginWithProvider(String provider) async {
    final identityProvider = ref.read(authIdentityProviderProvider);
    if (identityProvider is! SocialAuthIdentityProvider) {
      state = AsyncError(const AuthIdentityUnavailable(), StackTrace.current);
      return;
    }
    state = const AsyncLoading();
    try {
      final session = await (identityProvider as SocialAuthIdentityProvider)
          .signInWithProvider(provider: provider);
      state = AsyncData(session);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> continueAsGuest() async {
    await _enterSession(const AuthSession.guest());
  }

  Future<void> continueOffline() async {
    await _enterSession(const AuthSession.offline());
  }

  Future<void> logout() async {
    state = const AsyncData(AuthSession.loggedOut());
    final identityProvider = ref.read(authIdentityProviderProvider);
    if (identityProvider case final AuthSessionRestorer restorer) {
      try {
        await restorer.logoutRemote();
      } on Object {
        // Local logout must still complete if the remote is unavailable.
      }
    }
    try {
      await ref.read(authSessionStoreProvider).clear();
    } on Object {
      // Best-effort: even if clearing fails, the in-memory state is logged
      // out and the next successful save/clear will reconcile the file.
    }
  }

  Future<void> _enterSession(AuthSession session) async {
    state = AsyncData(session);
    try {
      await ref.read(authSessionStoreProvider).save(session);
    } on Object {
      // Persistence is best-effort; the session stays active in memory.
    }
  }
}

final initialAuthSessionProvider = Provider<AuthSession?>((ref) => null);

Future<AuthSession> loadLocalFirstAuthSession(AuthSessionStore store) async {
  try {
    final restored = await store.load();
    if (restored != null && restored.status != AuthStatus.unauthenticated) {
      return restored;
    }
    const localSession = AuthSession.offline();
    if (restored != null) await store.save(localSession);
    return localSession;
  } on Object {
    // Missing or unreadable session data must never block local startup.
    return const AuthSession.offline();
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);
