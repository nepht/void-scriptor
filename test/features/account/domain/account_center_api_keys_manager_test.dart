import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_api_keys_manager.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';

void main() {
  group('AccountCenterApiKeysManager', () {
    test('manifest preserves every canonical 115.27 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_api_keys_manager.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.27');
      expect(manifest['acceptance'], <String>[
        'add_replace',
        'validate',
        'revoke',
        'scope',
        'last_used',
        'masked_only',
        'secure_copy',
      ]);
    });

    test(
      'adds, replaces, and lists metadata without exposing plaintext',
      () async {
        final fixture = _Fixture();

        await fixture.manager.add(
          id: 'primary',
          providerId: 'cloud-ai',
          label: 'Primary key',
          secret: 'first-secret',
          scopes: const {'models:read', 'generation:write'},
        );
        await fixture.manager.replace(id: 'primary', secret: 'second-secret');

        final key = fixture.manager.keys.single;
        expect(key.id, 'primary');
        expect(key.providerId, 'cloud-ai');
        expect(key.scopes, {'models:read', 'generation:write'});
        expect(key.maskedValue, '••••••••••••');
        expect(key.replacedAt, fixture.now);
        expect(key.toPublicJson().toString(), isNot(contains('secret')));
        expect(key.toPublicJson().toString(), isNot(contains('second-secret')));
        expect(
          await fixture.store.read('account/account-1/api_key/primary'),
          'second-secret',
        );
      },
    );

    test(
      'validates through an injected probe and records no key material',
      () async {
        final fixture = _Fixture();
        await fixture.manager.add(
          id: 'primary',
          providerId: 'cloud-ai',
          label: 'Primary key',
          secret: 'valid-secret',
          scopes: const {'models:read'},
        );

        final result = await fixture.manager.validate('primary');

        expect(result, isTrue);
        expect(fixture.validatedSecrets, ['valid-secret']);
        expect(fixture.manager.keys.single.validation, ApiKeyValidation.valid);
        expect(fixture.manager.keys.single.validatedAt, fixture.now);
        expect(
          fixture.manager.audit.every((event) => event.secret == null),
          isTrue,
        );
      },
    );

    test('tracks last used metadata and revokes key material', () async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );

      fixture.manager.markUsed('primary');
      expect(fixture.manager.keys.single.lastUsedAt, fixture.now);
      await fixture.manager.revoke('primary');

      expect(fixture.manager.keys.single.status, ApiKeyStatus.revoked);
      expect(
        await fixture.store.read('account/account-1/api_key/primary'),
        isNull,
      );
      expect(() => fixture.manager.markUsed('primary'), throwsStateError);
    });

    test(
      'secure copy requires reauthentication and expires clipboard',
      () async {
        final fixture = _Fixture(reauthenticated: false);
        await fixture.manager.add(
          id: 'primary',
          providerId: 'cloud-ai',
          label: 'Primary key',
          secret: 'copy-secret',
          scopes: const {'models:read'},
        );

        expect(await fixture.manager.secureCopy('primary'), isFalse);
        expect(fixture.clipboard, isNull);
        fixture.reauthenticated = true;
        expect(await fixture.manager.secureCopy('primary'), isTrue);
        expect(fixture.clipboard, 'copy-secret');
        fixture.now = fixture.now.add(const Duration(seconds: 31));
        expect(await fixture.manager.clearExpiredClipboard(), 1);
        expect(fixture.clipboard, '');
      },
    );

    test(
      'fails closed for duplicate ids, empty scopes, and revoked actions',
      () async {
        final fixture = _Fixture();
        await fixture.manager.add(
          id: 'primary',
          providerId: 'cloud-ai',
          label: 'Primary key',
          secret: 'secret',
          scopes: const {'models:read'},
        );

        expect(
          () => fixture.manager.add(
            id: 'primary',
            providerId: 'other',
            label: 'Duplicate',
            secret: 'other',
            scopes: const {'models:read'},
          ),
          throwsStateError,
        );
        expect(
          () => fixture.manager.add(
            id: 'empty-scope',
            providerId: 'cloud-ai',
            label: 'Empty',
            secret: 'other',
            scopes: const {},
          ),
          throwsArgumentError,
        );
        await fixture.manager.revoke('primary');
        expect(() => fixture.manager.validate('primary'), throwsStateError);
        expect(() => fixture.manager.secureCopy('primary'), throwsStateError);
      },
    );
  });
}

class _Fixture {
  _Fixture({this.reauthenticated = true}) {
    vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => reauthenticated,
      clipboardWriter: (value) async => clipboard = value,
      clock: () => now,
    );
    manager = AccountCenterApiKeysManager(
      accountId: 'account-1',
      vault: vault,
      clock: () => now,
      validator: (request) async {
        validatedSecrets.add(request.secret);
        return request.secret == 'valid-secret';
      },
    );
  }

  final store = MemoryCredentialStore();
  late final AccountSecureTokenVault vault;
  late final AccountCenterApiKeysManager manager;
  final validatedSecrets = <String>[];
  DateTime now = DateTime.utc(2026, 9, 26, 2);
  bool reauthenticated;
  String? clipboard;
}
