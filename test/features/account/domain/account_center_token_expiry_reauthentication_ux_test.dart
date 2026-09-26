import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_token_expiry_reauthentication_ux.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json',
  );

  test('pins the canonical step and acceptance vocabulary', () {
    expect(manifestFile.existsSync(), isTrue);
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    expect(manifest['canonical_step'], '115.43');
    expect(
      manifest['acceptance'],
      AccountCenterTokenExpiryReauthenticationUx.canonicalAcceptance,
    );
  });

  test(
    'expired connection exposes affected capabilities and preserves local data',
    () {
      final state = AccountCenterTokenExpiryReauthenticationUx.expired(
        providerId: 'drive',
        accountLabel: 'Work Drive',
        affectedCapabilities: const ['sync', 'backup'],
        hasLocalData: true,
      );

      expect(state.notice, 'Connection expired for Work Drive.');
      expect(state.affectedCapabilities, ['sync', 'backup']);
      expect(state.requiresReauthentication, isTrue);
      expect(state.localDataPreserved, isTrue);
      expect(state.canRetry, isFalse);
      expect(state.canRevoke, isTrue);
    },
  );

  test(
    'reauthentication success restores safe retry without touching local data',
    () {
      final expired = AccountCenterTokenExpiryReauthenticationUx.expired(
        providerId: 'drive',
        accountLabel: 'Work Drive',
        affectedCapabilities: const ['sync'],
        hasLocalData: true,
      );
      final reauthed = expired.reauthenticated();

      expect(reauthed.requiresReauthentication, isFalse);
      expect(reauthed.canRetry, isTrue);
      expect(reauthed.retryLabel, 'Retry sync');
      expect(reauthed.localDataPreserved, isTrue);
      expect(reauthed.notice, 'Connection restored for Work Drive.');
    },
  );

  test(
    'safe retry is explicit and does not retry affected capabilities blindly',
    () {
      final state =
          AccountCenterTokenExpiryReauthenticationUx.reauthenticatedState(
            providerId: 'drive',
            accountLabel: 'Work Drive',
            affectedCapabilities: const ['sync', 'backup'],
            hasLocalData: true,
          );

      expect(state.retry('sync').accepted, isTrue);
      expect(state.retry('delete').accepted, isFalse);
      expect(
        state.retry('delete').reason,
        'Capability is not available for retry.',
      );
    },
  );

  test('revoke is explicit and terminal while retaining local data', () {
    final state = AccountCenterTokenExpiryReauthenticationUx.expired(
      providerId: 'drive',
      accountLabel: 'Work Drive',
      affectedCapabilities: const ['sync'],
      hasLocalData: true,
    );
    final revoked = state.revoked();

    expect(revoked.isRevoked, isTrue);
    expect(revoked.requiresReauthentication, isFalse);
    expect(revoked.canRetry, isFalse);
    expect(revoked.canRevoke, isFalse);
    expect(revoked.notice, 'Connection revoked for Work Drive.');
    expect(revoked.localDataPreserved, isTrue);
  });

  test(
    'rejects blank identities, capabilities, and duplicate capabilities',
    () {
      expect(
        () => AccountCenterTokenExpiryReauthenticationUx.expired(
          providerId: ' ',
          accountLabel: 'Drive',
          affectedCapabilities: const ['sync'],
          hasLocalData: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => AccountCenterTokenExpiryReauthenticationUx.expired(
          providerId: 'drive',
          accountLabel: 'Drive',
          affectedCapabilities: const ['sync', 'sync'],
          hasLocalData: true,
        ),
        throwsArgumentError,
      );
    },
  );
}
