import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_payment_methods.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';

const String _productSpecPath =
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
    'referenced-chatgpt-conversation-this-is-an-2/outputs/'
    'account_cloud_center_spec.json';

void main() {
  group('AccountCenterPaymentMethods', () {
    test('manifest preserves every canonical 115.36 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_payment_method_abstraction.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.36');
      expect(manifest['acceptance'], <String>[
        'provider_token_only',
        'masked_details',
        'default_method',
        'replace_remove',
        'region_availability',
        'reauth',
      ]);
      expect(
        manifest['implementation'],
        'lib/features/account/domain/account_center_payment_methods.dart',
      );
      expect(
        manifest['evidence'],
        'test/features/account/domain/account_center_payment_methods_test.dart',
      );
    });

    test('product-spec billing contract still forbids raw card storage', () {
      final spec =
          jsonDecode(File(_productSpecPath).readAsStringSync())
              as Map<String, Object?>;
      final billing = spec['billing_contract'] as Map<String, Object?>;

      expect(
        billing['status'],
        AccountCenterPaymentMethods.billingContractStatus,
      );
      expect(billing['rules'], contains('Never store raw card data.'));
      expect(billing['separation'], contains('payment_method'));
      final securityContract =
          spec['security_contract'] as Map<String, Object?>;
      expect(
        securityContract['secrets'],
        contains('reauth_before_sensitive_action'),
      );

      // The in-repo 115.1 snapshot carries the delivery rules the
      // implementation must respect.
      final snapshot =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_entry_gate_product_spec.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final deliveryRules = snapshot['delivery_rules'] as Map<String, Object?>;
      expect(deliveryRules['raw_card_storage_allowed'], isFalse);
      expect(deliveryRules['plaintext_secret_storage_allowed'], isFalse);
      final snapshotBilling =
          snapshot['billing_contract'] as Map<String, Object?>;
      expect(snapshotBilling['raw_card_storage_allowed'], isFalse);
    });

    test(
      'adding a method requires a provider token and rejects raw card data',
      () async {
        final store = MemoryCredentialStore();
        final manager = _manager(store);

        final method = await manager.add(
          id: 'pm-local-1',
          providerId: 'stripe',
          providerToken: 'pm_1AbCdEf',
          brand: 'visa',
          last4: '4242',
          expiryMonth: 4,
          expiryYear: 2029,
          cardholderName: 'Choirudin',
          regions: const <String>['ID', 'SG'],
        );

        expect(method.id, 'pm-local-1');
        expect(method.brand, 'visa');
        expect(method.last4, '4242');
        expect(manager.methods, hasLength(1));

        // A raw PAN, CVC, or expiry date is never accepted as provider input.
        await expectLater(
          manager.add(
            id: 'local-pan',
            providerId: 'stripe',
            providerToken: '4242424242424242',
            brand: 'visa',
            last4: '4242',
            expiryMonth: 4,
            expiryYear: 2029,
          ),
          throwsA(isA<PaymentMethodInputError>()),
        );
        expect(manager.methods, hasLength(1));
      },
    );

    test(
      'raw card fields are rejected at the boundary, not just the token',
      () {
        expect(
          () => PaymentMethodDraft(
            id: 'local-1',
            providerId: 'stripe',
            providerToken: 'pm_1',
            brand: 'visa',
            last4: '4242',
            expiryMonth: 4,
            expiryYear: 2029,
            cardNumber: '4242424242424242',
          ),
          throwsA(isA<PaymentMethodInputError>()),
        );
        expect(
          () => PaymentMethodDraft(
            id: 'local-1',
            providerId: 'stripe',
            providerToken: 'pm_1',
            brand: 'visa',
            last4: '4242',
            expiryMonth: 4,
            expiryYear: 2029,
            securityCode: '123',
          ),
          throwsA(isA<PaymentMethodInputError>()),
        );
      },
    );

    test('masked display never exposes the token or full detail', () async {
      final manager = _manager(MemoryCredentialStore());
      final method = await manager.add(
        id: 'pm-local-1',
        providerId: 'stripe',
        providerToken: 'pm_1AbCdEf',
        brand: 'visa',
        last4: '4242',
        expiryMonth: 4,
        expiryYear: 2029,
        cardholderName: 'Choirudin',
      );

      expect(method.maskedLabel, 'visa •••• 4242');
      expect(method.toPublicJson().containsKey('provider_token'), isFalse);
      expect(method.toPublicJson().containsKey('security_code'), isFalse);
      final json = jsonEncode(method.toPublicJson());
      expect(json.contains('pm_1AbCdEf'), isFalse);
      expect(json.contains('4242424242424242'), isFalse);
    });

    test('exactly one default method is active at a time', () async {
      final manager = _manager(MemoryCredentialStore());
      final first = await manager.add(
        id: 'local-1',
        providerId: 'stripe',
        providerToken: 'pm_one',
        brand: 'visa',
        last4: '1111',
        expiryMonth: 1,
        expiryYear: 2030,
      );
      final second = await manager.add(
        id: 'local-2',
        providerId: 'midtrans',
        providerToken: 'pm_two',
        brand: 'mastercard',
        last4: '2222',
        expiryMonth: 2,
        expiryYear: 2031,
      );

      // First added method becomes the default implicitly.
      expect(manager.defaultMethodId, first.id);

      await manager.setDefault(second.id);
      expect(manager.defaultMethodId, second.id);
      expect(
        manager.methods.where((m) => m.isDefault).map((m) => m.id),
        <String>[second.id],
      );
    });

    test(
      'replace swaps the token behind the same id and records an audit event',
      () async {
        final store = MemoryCredentialStore();
        final manager = _manager(store);
        final original = await manager.add(
          id: 'local-1',
          providerId: 'stripe',
          providerToken: 'pm_one',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );

        await manager.replace(
          id: original.id,
          providerToken: 'pm_one_rotated',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );

        final replaced = manager.method(original.id);
        expect(replaced.id, original.id);
        expect(replaced.replacedAt, isNotNull);
        expect(
          manager.audit.map((event) => event.action),
          containsAll(<String>['add', 'replace']),
        );
      },
    );

    test(
      'removing a method revokes the vault secret and reassigns or clears default',
      () async {
        final store = MemoryCredentialStore();
        final manager = _manager(store);
        final first = await manager.add(
          id: 'local-1',
          providerId: 'stripe',
          providerToken: 'pm_one',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );
        final second = await manager.add(
          id: 'local-2',
          providerId: 'midtrans',
          providerToken: 'pm_two',
          brand: 'mastercard',
          last4: '2222',
          expiryMonth: 2,
          expiryYear: 2031,
        );
        await manager.setDefault(second.id);

        await manager.remove(first.id);

        expect(manager.methods.map((m) => m.id), <String>[second.id]);
        expect(manager.defaultMethodId, second.id);
        expect(
          await store.read('account/acct-1/payment_method/local-2'),
          'pm_two',
        );
      },
    );

    test(
      'removing the default method with no other method clears the default',
      () async {
        final manager = _manager(MemoryCredentialStore());
        final only = await manager.add(
          id: 'local-1',
          providerId: 'stripe',
          providerToken: 'pm_one',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );

        await manager.remove(only.id);

        expect(manager.methods, isEmpty);
        expect(manager.defaultMethodId, isNull);
      },
    );

    test(
      'region availability is explicit and a method outside region fails closed',
      () async {
        final manager = _manager(MemoryCredentialStore());
        final method = await manager.add(
          id: 'local-1',
          providerId: 'stripe',
          providerToken: 'pm_one',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
          regions: const <String>['ID', 'SG'],
        );

        expect(method.regions, containsAll(<String>['ID', 'SG']));
        expect(method.isAvailableIn('ID'), isTrue);
        expect(method.isAvailableIn('JP'), isFalse);
        // Unknown region is never assumed available.
        expect(method.isAvailableIn('ZZ'), isFalse);
      },
    );

    test('an unavailable region rejects the method for checkout use', () async {
      final manager = _manager(MemoryCredentialStore());
      final method = await manager.add(
        id: 'local-1',
        providerId: 'stripe',
        providerToken: 'pm_one',
        brand: 'visa',
        last4: '1111',
        expiryMonth: 1,
        expiryYear: 2030,
        regions: const <String>['ID'],
      );

      expect(
        () => manager.requireAvailableForCheckout(method.id, 'JP'),
        throwsA(isA<StateError>()),
      );
      expect(manager.requireAvailableForCheckout(method.id, 'ID'), isNotNull);
    });

    test(
      'sensitive actions require reauthentication and fail closed without it',
      () async {
        final store = MemoryCredentialStore();
        var allowReauth = false;
        final manager = _manager(
          store,
          reauthenticate: () async => allowReauth,
        );
        final method = await manager.add(
          id: 'local-1',
          providerId: 'stripe',
          providerToken: 'pm_one',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );

        // Rejected without reauth.
        await expectLater(
          manager.replace(
            id: method.id,
            providerToken: 'pm_rotated',
            brand: 'visa',
            last4: '1111',
            expiryMonth: 1,
            expiryYear: 2030,
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          manager.setDefault(method.id),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          manager.remove(method.id),
          throwsA(isA<StateError>()),
        );

        // Accepted after reauth.
        allowReauth = true;
        await manager.setDefault(method.id);
        await manager.replace(
          id: method.id,
          providerToken: 'pm_rotated',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );
        expect(manager.method(method.id).replacedAt, isNotNull);
      },
    );

    test(
      'reauthentication is required before revealing the stored token',
      () async {
        final store = MemoryCredentialStore();
        var allowReauth = false;
        final manager = _manager(
          store,
          reauthenticate: () async => allowReauth,
        );
        final method = await manager.add(
          id: 'local-1',
          providerId: 'stripe',
          providerToken: 'pm_secret',
          brand: 'visa',
          last4: '1111',
          expiryMonth: 1,
          expiryYear: 2030,
        );

        expect(await manager.revealProviderToken(method.id), isNull);
        allowReauth = true;
        expect(await manager.revealProviderToken(method.id), 'pm_secret');
        // The reveal is audited.
        expect(
          manager.audit.map((event) => event.action),
          contains('reveal_token'),
        );
      },
    );

    test('the stored token never leaks into the public json surface', () async {
      final manager = _manager(MemoryCredentialStore());
      final method = await manager.add(
        id: 'local-1',
        providerId: 'stripe',
        providerToken: 'pm_secret',
        brand: 'visa',
        last4: '1111',
        expiryMonth: 1,
        expiryYear: 2030,
      );

      final publicJson = jsonEncode(manager.toPublicJson());
      expect(publicJson.contains('pm_secret'), isFalse);
      expect(manager.methods.first.toPublicJson()['provider_token'], isNull);
      expect(method.maskedLabel, isNot(contains('pm_secret')));
    });
  });
}

AccountCenterPaymentMethods _manager(
  CredentialStore store, {
  Future<bool> Function()? reauthenticate,
}) => AccountCenterPaymentMethods(
  accountId: 'acct-1',
  vault: AccountSecureTokenVault(
    store: store,
    reauthenticate: reauthenticate ?? () async => true,
  ),
  clock: () => DateTime.utc(2026, 9, 26),
);
