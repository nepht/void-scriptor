/// 117.32 — Security Assessment (gate gagal-tertutup).
///
/// Menguji delapan `required_evidence` kanonik step `117.32` secara langsung
/// terhadap kode yang benar-benar di-ship, bukan terhadap deskripsi kontrak.
/// Setiap grup di bawah membuktikan bahwa permukaan yang diukur gagal-tertutup;
/// biaya untuk membuktikannya diuji di grup `necessity`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/core/auth/auth_session_store_io.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/security/application/secret_redactor.dart';
import 'package:void_scriptor/core/security/application/secret_scanner.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_security_assessment.dart';

void main() {
  group('117.32 gate structure', () {
    test('covers exactly the eight canonical evidence areas', () {
      expect(Sprint117SecurityAssessment.requiredAreas, <String>[
        'oauth',
        'redirects',
        'vault',
        'sessions',
        'permissions',
        'webhooks',
        'dependencies',
        'log_redaction',
      ]);
    });

    test('empty evidence fails closed', () {
      final result = Sprint117SecurityAssessment.evaluate(
        const <Sprint117SecurityCheck>[],
      );
      expect(result.pass, isFalse);
      expect(result.failures, contains('no_checks'));
    });

    test('an area carrying only violations is named, not just "violated"', () {
      final result = Sprint117SecurityAssessment.evaluate(
        <Sprint117SecurityCheck>[
          for (final area in Sprint117SecurityAssessment.requiredAreas)
            if (area == 'oauth')
              Sprint117SecurityCheck.violation(
                area: area,
                check: 'code_verifier',
                declared: 'PKCE verifier is bound to the authorization request',
                observed: 'measured: verifier absent',
              )
            else
              Sprint117SecurityCheck.pass_(
                area: area,
                check: 'measured',
                declared: 'measured and within contract',
                observed: 'measured and within contract',
              ),
        ],
      );
      expect(result.pass, isFalse);
      expect(result.failures, contains('area_without_pass:oauth'));
      expect(result.violationCodes, contains('oauth:code_verifier'));
    });

    test('vacuous and duplicate evidence cannot manufacture a pass', () {
      final check = Sprint117SecurityCheck.pass_(
        area: 'oauth',
        check: 'c',
        declared: '',
        observed: '   ',
      );
      final result = Sprint117SecurityAssessment.evaluate(
        <Sprint117SecurityCheck>[check, check],
      );
      expect(result.pass, isFalse);
      expect(result.failures, contains('vacuous_declared:oauth:c'));
      expect(result.failures, contains('vacuous:oauth:c'));
      expect(result.failures, contains('duplicate_check:oauth:c'));
    });

    test('an unmet check is reported without failing its validated area', () {
      // `unmet` is a documented gap, not a measured violation: an area that
      // was otherwise measured clean and additionally reports an unreachable
      // external source still passes, and the gap stays visible in open_items.
      final result = Sprint117SecurityAssessment.evaluate(
        <Sprint117SecurityCheck>[
          for (final area in Sprint117SecurityAssessment.requiredAreas) ...<
            Sprint117SecurityCheck
          >[
            Sprint117SecurityCheck.pass_(
              area: area,
              check: 'measured',
              declared: 'measured and within contract',
              observed: 'measured and within contract',
            ),
            if (area == 'dependencies')
              Sprint117SecurityCheck.unmet(
                area: area,
                check: 'external_advisory',
                declared: 'upstream advisory database is consulted',
                observed: 'offline: no advisory database reachable',
              ),
          ],
        ],
      );
      expect(result.pass, isTrue);
      expect(result.openItems, contains('dependencies:external_advisory'));
    });

    test('an area whose only evidence is unmet has validated nothing', () {
      // Reporting a gap must not become a way to pass the gate with zero
      // measurements. An area with nothing but `unmet` carries no pass and
      // no violation, and is named as unvalidated rather than counted clean.
      final result =
          Sprint117SecurityAssessment.evaluate(<Sprint117SecurityCheck>[
            for (final area in Sprint117SecurityAssessment.requiredAreas)
              if (area == 'webhooks')
                Sprint117SecurityCheck.unmet(
                  area: area,
                  check: 'external_advisory',
                  declared: 'upstream advisory database is consulted',
                  observed: 'offline: no advisory database reachable',
                )
              else
                Sprint117SecurityCheck.pass_(
                  area: area,
                  check: 'measured',
                  declared: 'measured and within contract',
                  observed: 'measured and within contract',
                ),
          ]);
      expect(result.pass, isFalse);
      expect(result.failures, contains('area_without_pass:webhooks'));
      expect(result.openItems, contains('webhooks:external_advisory'));
    });
  });

  group('oauth', () {
    test('a spent authorization is released from the pending map', () async {
      final flow = _flow();
      final request = flow.beginAuthorization(
        configuration: _configuration(),
        consent: _consent(),
      );
      expect(
        flow.liveAuthorizationCount,
        1,
        reason: 'an issued authorization is in flight until it resolves',
      );
      await flow.completeAuthorization(
        callback: Uri.parse(
          'voidscriptor://oauth/callback'
          '?code=auth-code'
          '&state=${request.state}'
          '&nonce=${request.nonce}',
        ),
      );
      expect(
        flow.liveAuthorizationCount,
        0,
        reason: 'the PKCE verifier must not stay resident after redemption',
      );
    });

    test('the same callback cannot be replayed', () async {
      final flow = _flow();
      final request = flow.beginAuthorization(
        configuration: _configuration(),
        consent: _consent(),
      );
      final callback = Uri.parse(
        'voidscriptor://oauth/callback'
        '?code=auth-code'
        '&state=${request.state}'
        '&nonce=${request.nonce}',
      );
      await flow.completeAuthorization(callback: callback);
      await expectLater(
        flow.completeAuthorization(callback: callback),
        throwsA(isA<OAuthFlowException>()),
        reason: 'a redeemed state is a spent state',
      );
    });
  });

  group('redirects', () {
    test('the desktop custom-scheme callback still completes', () async {
      final flow = _flow();
      final request = flow.beginAuthorization(
        configuration: _configuration(),
        consent: _consent(),
      );
      await expectLater(
        flow.completeAuthorization(
          callback: Uri.parse(
            'voidscriptor://oauth/callback'
            '?code=auth-code'
            '&state=${request.state}'
            '&nonce=${request.nonce}',
          ),
        ),
        completes,
        reason: 'the desktop custom scheme carries no port and still works',
      );
    });

    test(
      'a callback on an https redirect is compared including its port',
      () async {
        final flow = _flow();
        final configuration = OAuthProviderConfiguration(
          connector: _connector(),
          authorizationEndpoint: Uri.parse(
            'https://identity.example.test/oauth/authorize',
          ),
          redirectUri: Uri.parse('https://app.example.test:443/callback'),
          scopes: const <String>{'openid'},
        );
        final request = flow.beginAuthorization(
          configuration: configuration,
          consent: OAuthScopeConsent(
            requestedScopes: configuration.scopes,
            grantedScopes: configuration.scopes,
            explicitlyApproved: true,
          ),
        );
        await expectLater(
          flow.completeAuthorization(
            callback: Uri.parse(
              'https://app.example.test:8443/callback'
              '?code=auth-code'
              '&state=${request.state}'
              '&nonce=${request.nonce}',
            ),
          ),
          throwsA(
            isA<OAuthFlowException>().having(
              (e) => e.code,
              'code',
              OAuthFlowErrorCode.callbackMismatch,
            ),
          ),
          reason: 'same host and path on another port is a different authority',
        );
      },
    );

    test('a callback carrying user info is rejected', () async {
      final flow = _flow();
      final configuration = OAuthProviderConfiguration(
        connector: _connector(),
        authorizationEndpoint: Uri.parse(
          'https://identity.example.test/oauth/authorize',
        ),
        redirectUri: Uri.parse('https://app.example.test/callback'),
        scopes: const <String>{'openid'},
      );
      final request = flow.beginAuthorization(
        configuration: configuration,
        consent: OAuthScopeConsent(
          requestedScopes: configuration.scopes,
          grantedScopes: configuration.scopes,
          explicitlyApproved: true,
        ),
      );
      await expectLater(
        flow.completeAuthorization(
          callback: Uri.parse(
            'https://user:pw@app.example.test/callback'
            '?code=auth-code'
            '&state=${request.state}'
            '&nonce=${request.nonce}',
          ),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (e) => e.code,
            'code',
            OAuthFlowErrorCode.callbackMismatch,
          ),
        ),
      );
    });

    test('an insecure http redirect is refused at configuration time', () {
      expect(
        () => OAuthProviderConfiguration(
          connector: _connector(),
          authorizationEndpoint: Uri.parse(
            'https://identity.example.test/oauth/authorize',
          ),
          redirectUri: Uri.parse('http://app.example.test/callback'),
          scopes: const <String>{'openid'},
        ),
        throwsArgumentError,
        reason: 'the authorization code would travel in cleartext',
      );
    });
  });

  group('vault', () {
    test('audit rows never carry secret material', () async {
      final rows = <String>[];
      final vault = AccountSecureTokenVault(
        store: _MemoryStore(),
        reauthenticate: () async => true,
        auditSink: (event) => rows.add('${event.action}|${event.secret}'),
      );
      await vault.save(
        accountId: 'acct-1',
        secret: 'super-secret-value',
        kind: VaultSecretKind.apiKey,
        secretId: 'primary',
      );
      await vault.revoke(
        accountId: 'acct-1',
        kind: VaultSecretKind.apiKey,
        secretId: 'primary',
      );
      expect(rows, <String>['save|null', 'revoke|null']);
    });

    test(
      'a failed reauthentication reads nothing and claims nothing',
      () async {
        final store = _MemoryStore();
        await store.write(key: 'account/a/api_key', value: 'the-secret');
        var audits = 0;
        final vault = AccountSecureTokenVault(
          store: store,
          reauthenticate: () async => false,
          auditSink: (_) => audits++,
        );
        final value = await vault.read(
          accountId: 'a',
          kind: VaultSecretKind.apiKey,
        );
        expect(value, isNull);
        expect(
          audits,
          0,
          reason:
              'a denied read must not leave a "read" row in the audit trail',
        );
      },
    );
  });

  group('sessions', () {
    test(
      'a session file holding valid JSON of the wrong shape fails closed',
      () async {
        final dir = Directory.systemTemp.createTempSync('vs_11732_session');
        addTearDown(() => dir.deleteSync(recursive: true));
        // `["guest"]` is valid JSON, so a bare `as Map<String, dynamic>` cast
        // throws a TypeError the FormatException clause never catches — an
        // unhandled crash on a tampered session file instead of a logged-out one.
        File('${dir.path}/session.json').writeAsStringSync('["guest"]');

        final store = AuthSessionStoreIo(
          file: File('${dir.path}/session.json'),
        );
        expect(await store.load(), isNull);
      },
    );

    test('a well-formed session still round-trips', () async {
      final dir = Directory.systemTemp.createTempSync('vs_11732_session_ok');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = AuthSessionStoreIo.inDirectory(dir);
      await store.save(const AuthSession.guest());
      final restored = await store.load();
      expect(restored, isNotNull);
      expect(restored!.status, AuthStatus.guest);
    });
  });

  group('permissions', () {
    test('a manifest requesting an unknown permission is refused', () {
      expect(
        () => PluginManifest.fromJson(<String, Object?>{
          'id': 'com.example.plugin',
          'name': 'Example',
          'version': '1.0.0',
          'author': 'A',
          'apiVersion': '1.0',
          'capabilities': <String>['ui'],
          'permissions': <String>['storage', 'not_a_permission'],
          'entrypoint': 'main.dart',
        }),
        throwsA(isA<PluginManifestException>()),
        reason: 'unvalidated permission strings must not reach the sandbox',
      );
    });

    test('a manifest with only known permissions still parses', () {
      final manifest = PluginManifest.fromJson(<String, Object?>{
        'id': 'com.example.plugin',
        'name': 'Example',
        'version': '1.0.0',
        'author': 'A',
        'apiVersion': '1.0',
        'capabilities': <String>['ui'],
        'permissions': <String>['storage', 'ui'],
        'entrypoint': 'main.dart',
      });
      expect(manifest.permissions, <String>['storage', 'ui']);
    });
  });

  group('webhooks', () {
    late Sprint117WebhookSignatureVerifier verifier;

    setUp(() {
      verifier = Sprint117WebhookSignatureVerifier.withSecretKey(
        SecretKey(List<int>.generate(32, (i) => (i * 7) & 0xFF)),
      );
    });

    test('a genuine signature verifies', () {
      const payload = '{"event_id":"evt_1","amount":100}';
      expect(
        verifier.verify(payload: payload, signature: verifier.sign(payload)),
        isTrue,
      );
    });

    test('a single flipped bit fails verification', () {
      const payload = '{"event_id":"evt_1","amount":100}';
      final signature = verifier.sign(payload);
      final tampered = signature.replaceRange(
        0,
        1,
        signature[0] == 'a' ? 'b' : 'a',
      );
      expect(verifier.verify(payload: payload, signature: tampered), isFalse);
    });

    test('a payload edited after signing fails verification', () {
      const payload = '{"event_id":"evt_1","amount":100}';
      final signature = verifier.sign(payload);
      expect(
        verifier.verify(
          payload: '{"event_id":"evt_1","amount":100000}',
          signature: signature,
        ),
        isFalse,
      );
    });

    test('the self-attested status string is not a signature', () {
      expect(
        Sprint117WebhookSignatureVerifier.verifySelfAttested(
          signatureStatus: 'VERIFIED',
        ),
        isFalse,
        reason: 'a self-declared status must never stand in for a signature',
      );
      expect(
        Sprint117WebhookSignatureVerifier.verifySelfAttested(
          signatureStatus: '',
        ),
        isFalse,
      );
    });

    test('an unsigned event is rejected rather than reconciled', () {
      expect(
        Sprint117WebhookSignatureVerifier.verifySelfAttested(
          signatureStatus: 'UNSIGNED',
        ),
        isFalse,
      );
    });
  });

  group('dependencies', () {
    test('every hosted package is sha256 pinned with no git/path source', () {
      final lock = File('pubspec.lock').readAsStringSync();
      final hosted = lock.split('source: hosted').length - 1;
      final pinned = 'sha256:'.allMatches(lock).length;
      expect(hosted, greaterThan(0));
      expect(
        pinned,
        hosted,
        reason: 'a hosted package without a pin is mutable',
      );
      expect(lock.contains('source: git'), isFalse);
      expect(lock.contains('source: path'), isFalse);
      expect(
        const SecretScanner().scan(lock),
        isEmpty,
        reason: 'no credential material may live in the lockfile',
      );
    });
  });

  group('log_redaction', () {
    const scanner = SecretScanner();
    const redactor = SecretRedactor();

    test('scanner catches the secret families the shipped patterns missed', () {
      final probes = <String, String>{
        'pem': '-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA\n',
        'openssh': '-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1r\n',
        'google': 'AIzaSyA1234567890abcdefghijklmnopqrstuv',
        'anthropic': 'sk-ant-api03-AbCdEfGhIjKlMnOpQrStUvWxYz0123456789',
        'github_pat': 'github_pat_11ABCDEFG0abcdefghij_ABCDEFGHIJKLMNOPQRSTUV',
        'slack_hook': 'https://hooks.slack.com/services/T0000/B0000/XXXXXX',
        'stripe': 'sk_live_4eC39HqLyjWDarjtT1zdp7dc',
        'jwt':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
            '.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4ifQ'
            '.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
      };
      for (final entry in probes.entries) {
        expect(
          scanner.scan(entry.value),
          isNotEmpty,
          reason: '${entry.key} secret family must be detected',
        );
      }
    });

    test('redaction is case-insensitive', () {
      const secret = 'sk-abcDEF123456789xyz';
      expect(
        redactor.redact('key=${secret.toUpperCase()}', secrets: const [secret]),
        'key=[REDACTED]',
      );
    });

    test('redaction does not depend on secret ordering', () {
      const shorter = 'sk-abc';
      const longer = 'sk-abcDEF123456789xyz';
      final forward = redactor.redact(
        'k=$longer',
        secrets: const [shorter, longer],
      );
      final reverse = redactor.redact(
        'k=$longer',
        secrets: const [longer, shorter],
      );
      expect(forward, reverse);
      expect(forward, 'k=[REDACTED]');
    });

    test('the control patterns that already worked still work', () {
      expect(scanner.scan('sk-abcdefgh12345678'), isNotEmpty);
      expect(scanner.scan('AKIAIOSFODNN7EXAMPLE'), isNotEmpty);
      expect(scanner.scan('ghp_abcdefghij0123456789abcd'), isNotEmpty);
      expect(scanner.scan('xoxb-123456789012-abcdefghij'), isNotEmpty);
    });
  });

  group('necessity', () {
    test('the fixed production behaviours are load-bearing', () {
      expect(
        const SecretScanner().scan('sk_live_4eC39HqLyjWDarjtT1zdp7dc'),
        isNotEmpty,
      );
      expect(
        const SecretScanner().scan('-----BEGIN RSA PRIVATE KEY-----'),
        isNotEmpty,
      );
      expect(
        () => PluginManifest.fromJson(<String, Object?>{
          'id': 'a',
          'name': 'n',
          'version': '1.0.0',
          'author': 'a',
          'apiVersion': '1.0',
          'capabilities': <String>[],
          'permissions': <String>['bogus'],
          'entrypoint': 'main.dart',
        }),
        throwsA(isA<PluginManifestException>()),
      );
    });
  });
}

AccountOAuthFlow _flow() => AccountOAuthFlow(broker: _Broker());

OAuthProviderConfiguration _configuration() => OAuthProviderConfiguration(
  connector: _connector(),
  authorizationEndpoint: Uri.parse(
    'https://identity.example.test/oauth/authorize',
  ),
  redirectUri: Uri.parse('voidscriptor://oauth/callback'),
  scopes: const <String>{'openid'},
);

OAuthScopeConsent _consent() => OAuthScopeConsent(
  requestedScopes: _configuration().scopes,
  grantedScopes: _configuration().scopes,
  explicitlyApproved: true,
);

class _Broker implements OAuthTokenBroker {
  @override
  Future<OAuthTokenResponse> exchange(OAuthTokenExchangeRequest request) async {
    final now = DateTime.now().toUtc();
    return OAuthTokenResponse(
      providerId: request.configuration.connector.providerId,
      providerAccountId: 'provider-account-1',
      displayName: 'Provider Account',
      accessToken: 'access-token-value',
      refreshToken: 'refresh-token-value',
      accessTokenExpiresAt: now.add(const Duration(hours: 1)),
      issuedAt: now,
      scopes: request.scopes,
    );
  }

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async {
    final now = DateTime.now().toUtc();
    return OAuthTokenResponse(
      providerId: request.grant.providerId,
      providerAccountId: 'provider-account-1',
      displayName: 'Provider Account',
      accessToken: 'access-token-value-2',
      refreshToken: 'refresh-token-value-2',
      accessTokenExpiresAt: now.add(const Duration(hours: 1)),
      issuedAt: now,
      scopes: request.grant.scopes,
    );
  }

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {}
}

ProviderConnectorEntry _connector() => ProviderConnectorEntry.fixture(
  'fixture-identity',
  displayName: 'Fixture Identity',
  category: ProviderConnectorCategory.identity,
  capabilities: const {
    ProviderConnectorCapability.identity,
    ProviderConnectorCapability.health,
  },
  availability: ProviderConnectorAvailability.available,
  authType: ProviderAuthType.oauth2Pkce,
  permissions: const {
    ProviderPermission.accountMetadata,
    ProviderPermission.providerConnection,
  },
);

/// Minimal in-memory [CredentialStore]; holds values only for the duration of
/// one test and is never written to disk.
class _MemoryStore implements CredentialStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
