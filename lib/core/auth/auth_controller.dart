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
    if (initialSession != null) return initialSession;

    // Sprint 145.20: restore a persisted local session (Guest/Offline) so a
    // restart does not force the user back through the login screen.
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

  Future<void> continueAsGuest() async {
    await _enterSession(const AuthSession.guest());
  }

  Future<void> continueOffline() async {
    await _enterSession(const AuthSession.offline());
  }

  Future<void> logout() async {
    state = const AsyncData(AuthSession.loggedOut());
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
