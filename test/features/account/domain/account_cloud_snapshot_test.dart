import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';

void main() {
  test('local-only snapshot never claims remote connections or fake quota', () {
    final snapshot = AccountCloudSnapshot.localOnly(
      session: const AuthSession.guest(),
    );

    expect(snapshot.accountModeLabel, 'Guest mode');
    expect(
      snapshot.service('local-project-storage').state,
      AccountCloudConnectionState.availableLocal,
    );
    expect(
      snapshot.service('google-drive').state,
      AccountCloudConnectionState.notConnected,
    );
    expect(
      snapshot.services.where((service) => service.usageLabel != null),
      isEmpty,
    );
  });

  test(
    'authenticated session marks only injected account identity connected',
    () {
      final snapshot = AccountCloudSnapshot.localOnly(
        session: const AuthSession(
          status: AuthStatus.authenticated,
          userId: 'provider-user',
          displayName: 'Verified Creator',
          email: 'verified@example.com',
        ),
      );

      expect(snapshot.accountModeLabel, 'Connected account');
      expect(
        snapshot.service('email-sign-in').state,
        AccountCloudConnectionState.connected,
      );
      expect(
        snapshot.service('cloud-sync').state,
        AccountCloudConnectionState.notConnected,
      );
    },
  );
}
