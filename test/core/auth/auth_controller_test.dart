import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_identity_provider.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';

class _ConfiguredIdentityProvider implements AuthIdentityProvider {
  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      status: AuthStatus.authenticated,
      userId: 'provider-user',
      displayName: 'Verified Creator',
      email: email,
    );
  }
}

void main() {
  test('preloaded local session is available synchronously at app boot', () {
    final container = ProviderContainer(
      overrides: [
        initialAuthSessionProvider.overrideWithValue(
          const AuthSession.offline(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initial = container.read(authControllerProvider);

    expect(initial.valueOrNull?.status, AuthStatus.offline);
    expect(initial.isLoading, isFalse);
  });

  test(
    'account login fails closed when no identity provider is configured',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .login(email: 'creator@example.com', password: 'password');

      final result = container.read(authControllerProvider);
      expect(result.hasError, isTrue);
      expect(result.valueOrNull?.status, AuthStatus.offline);
    },
  );

  test(
    'configured identity provider can create an authenticated session',
    () async {
      final container = ProviderContainer(
        overrides: [
          authIdentityProviderProvider.overrideWithValue(
            _ConfiguredIdentityProvider(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .login(email: 'verified@example.com', password: 'provider-secret');

      final session = container.read(authControllerProvider).requireValue;
      expect(session.status, AuthStatus.authenticated);
      expect(session.userId, 'provider-user');
      expect(session.email, 'verified@example.com');
    },
  );
}
