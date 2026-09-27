import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_identity_linking_collision.dart';

void main() {
  group('116.14 Identity Linking & Collision Tests', () {
    test('pins the canonical acceptance and local-only boundary', () {
      final manifest =
          jsonDecode(
                File(IdentityLinkingContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.14');
      expect(manifest['acceptance'], IdentityLinkingContract.acceptance);
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('detects duplicate email and provider identities without merging', () {
      final service = IdentityLinkingService([
        IdentityAccount(
          accountId: 'account-a',
          email: 'writer@example.test',
          identities: {const IdentityCredential('google', 'google-a')},
          recoveryEmail: 'recovery@example.test',
        ),
      ]);

      expect(
        () => service.link(
          targetAccountId: 'account-a',
          candidate: const IdentityCredential('github', 'github-a'),
          candidateEmail: 'WRITER@example.test',
          confirmedSafeMerge: false,
        ),
        throwsA(isA<IdentityCollisionException>()),
      );
      expect(service.accounts, hasLength(1));
    });

    test(
      'safe merge requires explicit confirmation and preserves both identities',
      () {
        final service = IdentityLinkingService([
          IdentityAccount(
            accountId: 'account-a',
            email: 'a@example.test',
            identities: {const IdentityCredential('google', 'google-a')},
            recoveryEmail: 'recovery@example.test',
          ),
          IdentityAccount(
            accountId: 'account-b',
            email: 'b@example.test',
            identities: {const IdentityCredential('github', 'github-b')},
            recoveryEmail: 'recovery-b@example.test',
          ),
        ]);

        expect(
          () => service.merge(
            primaryAccountId: 'account-a',
            secondaryAccountId: 'account-b',
            confirmedSafeMerge: false,
          ),
          throwsA(isA<IdentityMergeConfirmationException>()),
        );
        final merged = service.merge(
          primaryAccountId: 'account-a',
          secondaryAccountId: 'account-b',
          confirmedSafeMerge: true,
        );
        expect(merged.accountId, 'account-a');
        expect(
          merged.identities,
          containsAll(const [
            IdentityCredential('google', 'google-a'),
            IdentityCredential('github', 'github-b'),
          ]),
        );
        expect(service.find('account-b'), isNull);
      },
    );

    test(
      'protects the last login method and requires recovery before unlink',
      () {
        final service = IdentityLinkingService([
          IdentityAccount(
            accountId: 'account-a',
            email: 'a@example.test',
            identities: {const IdentityCredential('google', 'google-a')},
            recoveryEmail: null,
          ),
        ]);

        expect(
          () => service.unlink(
            accountId: 'account-a',
            credential: const IdentityCredential('google', 'google-a'),
          ),
          throwsA(isA<LastLoginMethodException>()),
        );
        final recovered = service.recover(
          accountId: 'account-a',
          recoveryEmail: 'new-recovery@example.test',
        );
        expect(recovered.recoveryEmail, 'new-recovery@example.test');
        expect(
          service.unlink(
            accountId: 'account-a',
            credential: const IdentityCredential('google', 'google-a'),
          ),
          isTrue,
        );
        expect(service.find('account-a')!.identities, isEmpty);
      },
    );

    test(
      'prevents takeover by rejecting an identity owned by another account',
      () {
        final service = IdentityLinkingService([
          IdentityAccount(
            accountId: 'account-a',
            email: 'a@example.test',
            identities: {const IdentityCredential('google', 'google-a')},
            recoveryEmail: 'recovery-a@example.test',
          ),
          IdentityAccount(
            accountId: 'account-b',
            email: 'b@example.test',
            identities: {const IdentityCredential('github', 'github-b')},
            recoveryEmail: 'recovery-b@example.test',
          ),
        ]);

        expect(
          () => service.link(
            targetAccountId: 'account-a',
            candidate: const IdentityCredential('github', 'github-b'),
            candidateEmail: 'b@example.test',
            confirmedSafeMerge: true,
          ),
          throwsA(isA<IdentityTakeoverException>()),
        );
        expect(
          service.find('account-b')!.identities,
          contains(const IdentityCredential('github', 'github-b')),
        );
      },
    );
  });
}
