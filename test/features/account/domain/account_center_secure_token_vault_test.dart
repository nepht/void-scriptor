import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';

void main() {
  test(
    'stores through the injected secure store and never exposes plaintext',
    () async {
      final store = MemoryCredentialStore();
      final audit = <VaultAuditEvent>[];
      final vault = AccountSecureTokenVault(
        store: store,
        reauthenticate: () async => true,
        auditSink: audit.add,
      );

      await vault.save(
        accountId: 'acct-1',
        secret: 'super-secret-token',
        kind: VaultSecretKind.apiKey,
      );

      expect(await store.read('account/acct-1/api_key'), 'super-secret-token');
      expect(vault.maskedDisplay('super-secret-token'), '••••••••••••');
      expect(audit.single.secret, isNull);
      expect(audit.single.accountId, 'acct-1');
    },
  );

  test(
    'requires reauthentication for read and secure clipboard copy',
    () async {
      final store = MemoryCredentialStore();
      var allowed = false;
      String? clipboard;
      final vault = AccountSecureTokenVault(
        store: store,
        reauthenticate: () async => allowed,
        clipboardWriter: (value) async => clipboard = value,
      );
      await vault.save(
        accountId: 'acct-1',
        secret: 'secret',
        kind: VaultSecretKind.oauthRefreshToken,
      );

      expect(
        await vault.read(
          accountId: 'acct-1',
          kind: VaultSecretKind.oauthRefreshToken,
        ),
        isNull,
      );
      expect(
        await vault.copyToClipboard(
          accountId: 'acct-1',
          kind: VaultSecretKind.oauthRefreshToken,
        ),
        isFalse,
      );
      allowed = true;
      expect(
        await vault.copyToClipboard(
          accountId: 'acct-1',
          kind: VaultSecretKind.oauthRefreshToken,
        ),
        isTrue,
      );
      expect(clipboard, 'secret');
    },
  );

  test(
    'expires clipboard contents and supports revoke with redacted audit',
    () async {
      final store = MemoryCredentialStore();
      var now = DateTime.utc(2026, 1, 1);
      String? clipboard;
      final audit = <VaultAuditEvent>[];
      final vault = AccountSecureTokenVault(
        store: store,
        reauthenticate: () async => true,
        clipboardWriter: (value) async => clipboard = value,
        clock: () => now,
        auditSink: audit.add,
        clipboardTimeout: const Duration(seconds: 30),
      );
      await vault.save(
        accountId: 'acct-1',
        secret: 'secret',
        kind: VaultSecretKind.apiKey,
      );
      await vault.copyToClipboard(
        accountId: 'acct-1',
        kind: VaultSecretKind.apiKey,
      );
      now = now.add(const Duration(seconds: 31));
      expect(await vault.clearExpiredClipboard(), 1);
      expect(clipboard, '');
      await vault.revoke(accountId: 'acct-1', kind: VaultSecretKind.apiKey);
      expect(await store.read('account/acct-1/api_key'), isNull);
      expect(audit.every((event) => event.secret == null), isTrue);
    },
  );
}
