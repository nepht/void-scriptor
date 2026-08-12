import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session.dart';
import 'auth_status.dart';

class AuthController extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const AuthSession.loggedOut();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = AsyncData(
      AuthSession(
        status: AuthStatus.authenticated,
        userId: 'local-demo-user',
        displayName: 'Void Creator',
        email: email,
      ),
    );
  }

  Future<void> continueAsGuest() async {
    state = const AsyncData(AuthSession.guest());
  }

  Future<void> continueOffline() async {
    state = const AsyncData(AuthSession.offline());
  }

  Future<void> logout() async {
    state = const AsyncData(AuthSession.loggedOut());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(
  AuthController.new,
);

// Kept for consumers that need to express a checking state explicitly.
const authCheckingStatus = AuthStatus.checking;
