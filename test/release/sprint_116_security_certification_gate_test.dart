import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_security_certification_gate.dart';

const int _now = 1700000100000;

void main() {
  group('116.45 Security Certification Gate', () {
    test(
      'locks the eight security evidence areas the canonical step demands',
      () {
        expect(Sprint116SecurityContract.requiredAreas, <String>[
          'oauth_tests',
          'vault_tests',
          'redirect_tests',
          'session_tests',
          'permission_tests',
          'webhook_tests',
          'dependency_scan',
          'audit_tests',
        ]);
        expect(Sprint116SecurityContract.canonicalStep, '116.45');
        expect(Sprint116SecurityContract.externalGates, 'DEFERRED-EXTERNAL');
        expect(
          Sprint116SecurityContract.manifestPath,
          'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        );
        expect(Sprint116SecurityContract.supportedSources, <String>[
          'synthetic_local',
          'live',
        ]);
        expect(Sprint116SecurityContract.cleanVulnerabilityStatuses, <String>[
          'clean',
          'mitigated',
          'remediated',
        ]);
        expect(Sprint116SecurityContract.blockedLicenses, <String>[
          'AGPL-3.0-only',
          'GPL-3.0-only',
          'SSPL-1.0',
        ]);
        expect(
          Sprint116SecurityContract.securityRelevantActions,
          contains('token_revoke'),
        );
        expect(
          Sprint116SecurityContract.securityRelevantActions,
          contains('vault_write'),
        );
      },
    );

    test('allow-lists are matched by identity, never by prefix or suffix', () {
      // The classic open-redirect: the allow-listed string is a prefix of the
      // attacker's host, so a startsWith check lets it through.
      expect(
        Sprint116SecurityContract.isRedirectUriAllowed(
          'https://app.voidscriptor.dev/oauth/callback?code=1',
          <String>['app.voidscriptor.dev'],
        ),
        isTrue,
      );
      expect(
        Sprint116SecurityContract.isRedirectUriAllowed(
          'https://app.voidscriptor.dev.evil.example/oauth/callback',
          <String>['app.voidscriptor.dev'],
        ),
        isFalse,
        reason: 'suffixed host must not inherit the allow-listed prefix',
      );
      expect(
        Sprint116SecurityContract.isRedirectUriAllowed(
          'https://evil.example/?next=app.voidscriptor.dev',
          <String>['app.voidscriptor.dev'],
        ),
        isFalse,
        reason: 'allow-listed host in the query is not the destination',
      );
      expect(
        Sprint116SecurityContract.isRedirectUriAllowed(
          'http://app.voidscriptor.dev/oauth/callback',
          <String>['app.voidscriptor.dev'],
        ),
        isFalse,
        reason: 'plaintext downgrade is never an allowed destination',
      );
      expect(
        Sprint116SecurityContract.isRedirectUriAllowed(
          'https://user:pass@app.voidscriptor.dev/oauth/callback',
          <String>['app.voidscriptor.dev'],
        ),
        isFalse,
        reason: 'userinfo in the URL is a phishing primitive, not a redirect',
      );
      expect(
        Sprint116SecurityContract.isRedirectUriAllowed(
          '//app.voidscriptor.dev/oauth/callback',
          <String>['app.voidscriptor.dev'],
        ),
        isFalse,
        reason: 'scheme-relative targets are resolved by the browser, not us',
      );
    });

    test('a complete healthy control set certifies and covers every area', () {
      final report = _certifyAll(
        controls: _healthyControls(),
        requireCoverage: true,
      );

      expect(report.state, Sprint116SecurityGateStatus.pass);
      expect(report.invalidRecords, isEmpty);
      for (final area in Sprint116SecurityContract.requiredAreas) {
        expect(report.coveredAreas, contains(area));
      }
      expect(report.toJson()['live_security_verification'], isFalse);
      expect(report.toJson()['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('empty control sets are blocked rather than certified', () {
      final certification = Sprint116SecurityCertificationGate();

      for (final empty in <Sprint116SecurityControlSet>[
        _healthyControls()..oauthFlows = const <Sprint116OAuthFlow>[],
        _healthyControls()..vaultEntries = const <Sprint116VaultEntry>[],
        _healthyControls()..redirects = const <Sprint116RedirectCheck>[],
        _healthyControls()..sessions = const <Sprint116SessionCheck>[],
        _healthyControls()..permissions = const <Sprint116PermissionGrant>[],
        _healthyControls()..webhooks = const <Sprint116WebhookEndpoint>[],
        _healthyControls()..dependencies = const <Sprint116Dependency>[],
        _healthyControls()..auditEntries = const <Sprint116AuditEntry>[],
      ]) {
        final report = certification.certify(
          controls: empty,
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116SecurityGateStatus.blocked);
        expect(report.invalidRecords, hasLength(1));
      }
    });

    test('an unpinned dependency verdict cannot be certified as clean', () {
      // `unknown` is not a clean bill of health; a fail-open dependency scan is
      // how a known CVE ships inside a CERTIFIED connector.
      final report = _certifyAll(
        controls: _healthyControls()
          ..dependencies = <Sprint116Dependency>[
            _dependency(
              dependencyId: 'dep_http',
              package: 'http',
              vulnerabilityStatus: 'unknown',
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('dependency_scan:dep_http'));
    });

    test('a wildcard or undeclared scope fails both oauth and permission', () {
      final wildcard = _certifyAll(
        controls: _healthyControls()
          ..oauthFlows = <Sprint116OAuthFlow>[
            _oauth(controlId: 'cf_google_pkce', requestedScopes: const ['*']),
          ],
      );
      expect(wildcard.state, Sprint116SecurityGateStatus.fail);
      expect(wildcard.invalidRecords, contains('oauth_tests:cf_google_pkce'));

      final escalate = _certifyAll(
        controls: _healthyControls()
          ..permissions = <Sprint116PermissionGrant>[
            _permission(
              grantId: 'grant_api_read',
              declaredPermissions: const ['read'],
              requestedPermissions: const ['read', 'admin:write'],
              grantedPermissions: const ['read', 'admin:write'],
            ),
          ],
      );
      expect(escalate.state, Sprint116SecurityGateStatus.fail);
      expect(
        escalate.invalidRecords,
        contains('permission_tests:grant_api_read'),
      );
    });

    test('a confidential OAuth client without PKCE is not certifiable', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..oauthFlows = <Sprint116OAuthFlow>[
            _oauth(
              controlId: 'cf_github_pkce',
              clientType: 'confidential',
              pkceEnabled: false,
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('oauth_tests:cf_github_pkce'));
    });

    test(
      'a missing OAuth state parameter is a CSRF gap, not a style choice',
      () {
        final report = _certifyAll(
          controls: _healthyControls()
            ..oauthFlows = <Sprint116OAuthFlow>[
              _oauth(controlId: 'cf_apple_pkce', stateParameter: ''),
            ],
        );

        expect(report.state, Sprint116SecurityGateStatus.fail);
        expect(report.invalidRecords, contains('oauth_tests:cf_apple_pkce'));
      },
    );

    test('a vault that leaks its secret through toString is a leak', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..vaultEntries = <Sprint116VaultEntry>[
            _vault(vaultId: 'vlt_provider_key', toStringIncludesSecret: true),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('vault_tests:vlt_provider_key'));
    });

    test('at-rest encryption and key separation are both mandatory', () {
      final plaintext = _certifyAll(
        controls: _healthyControls()
          ..vaultEntries = <Sprint116VaultEntry>[
            _vault(vaultId: 'vlt_user_token', encryptedAtRest: false),
          ],
      );
      expect(plaintext.invalidRecords, contains('vault_tests:vlt_user_token'));

      final sharedKey = _certifyAll(
        controls: _healthyControls()
          ..vaultEntries = <Sprint116VaultEntry>[
            _vault(vaultId: 'vlt_user_token', keySeparated: false),
          ],
      );
      expect(sharedKey.invalidRecords, contains('vault_tests:vlt_user_token'));
    });

    test('an unverified webhook must not be processed', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..webhooks = <Sprint116WebhookEndpoint>[
            _webhook(
              webhookId: 'whk_stripe_invoice',
              signatureVerifiedBeforeProcessing: false,
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('webhook_tests:whk_stripe_invoice'),
      );
    });

    test('a replayed webhook outside the tolerance window is rejected', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..webhooks = <Sprint116WebhookEndpoint>[
            _webhook(
              webhookId: 'whk_stripe_invoice',
              replayWindowSeconds: 300,
              eventTimestampEpochMs: 1700000000000,
              processingEpochMs: 1700000600000,
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('webhook_tests:whk_stripe_invoice'),
      );
    });

    test('session fixation and post-logout reuse are both defects', () {
      final noRotation = _certifyAll(
        controls: _healthyControls()
          ..sessions = <Sprint116SessionCheck>[
            _session(sessionId: 'ses_desktop', rotatedOnLogin: false),
          ],
      );
      expect(noRotation.invalidRecords, contains('session_tests:ses_desktop'));

      final survivesLogout = _certifyAll(
        controls: _healthyControls()
          ..sessions = <Sprint116SessionCheck>[
            _session(sessionId: 'ses_desktop', invalidatedOnLogout: false),
          ],
      );
      expect(
        survivesLogout.invalidRecords,
        contains('session_tests:ses_desktop'),
      );
    });

    test('an absolute session lifetime longer than the cap fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..sessions = <Sprint116SessionCheck>[
            _session(
              sessionId: 'ses_desktop',
              issuedAtEpochMs: 1699990000000,
              expiresAtEpochMs: 1700009999999,
              absoluteMaxLifetimeMs: 3600000,
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('session_tests:ses_desktop'));
    });

    test('a session token carried in the query string is a leak', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..sessions = <Sprint116SessionCheck>[
            _session(sessionId: 'ses_desktop', tokenInQueryString: true),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('session_tests:ses_desktop'));
    });

    test(
      'an unresolved redirect chain cannot certify the final destination',
      () {
        final report = _certifyAll(
          controls: _healthyControls()
            ..redirects = <Sprint116RedirectCheck>[
              _redirect(
                redirectId: 'rdr_oauth_callback',
                resolvedAfterRedirects: false,
              ),
            ],
        );

        expect(report.state, Sprint116SecurityGateStatus.fail);
        expect(
          report.invalidRecords,
          contains('redirect_tests:rdr_oauth_callback'),
        );
      },
    );

    test('a permission set that fails open is a defect, not a default', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..permissions = <Sprint116PermissionGrant>[
            _permission(grantId: 'grant_api_read', defaultDecision: 'allow'),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('permission_tests:grant_api_read'),
      );
    });

    test('silent scope widening on refresh is privilege escalation', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..permissions = <Sprint116PermissionGrant>[
            _permission(grantId: 'grant_api_read', escalationOnRefresh: true),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('permission_tests:grant_api_read'),
      );
    });

    test('an audit trail that can be rewritten is not an audit trail', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..auditEntries = <Sprint116AuditEntry>[
            _audit(entryId: 'aud_0001', mutatedAfterWrite: true),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('audit_tests:aud_0001'));
    });

    test('a secret written into the audit payload is a stored leak', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..auditEntries = <Sprint116AuditEntry>[
            _audit(entryId: 'aud_0001', payloadContainsSecret: true),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('audit_tests:aud_0001'));
    });

    test('security-relevant actions must actually be audited', () {
      // The gap this catches: a trail full of cosmetic events while token
      // revocation silently goes unlogged.
      final report = _certifyAll(
        controls: _healthyControls()
          ..auditEntries = <Sprint116AuditEntry>[
            _audit(
              entryId: 'aud_0001',
              action: 'theme_changed',
              targetId: 'settings',
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('audit_action_coverage:token_revoke'),
      );
      expect(report.unloggedSecurityActions, contains('vault_write'));
    });

    test('required audit actions follow the controls that actually exist', () {
      // A deployment with no OAuth connector has no oauth_link to log;
      // demanding one anyway would make the gate unfalsifiable rather than strict.
      expect(
        Sprint116SecurityContract.requiredAuditActions(_healthyControls()),
        <String>[
          'token_revoke',
          'vault_write',
          'session_invalidate',
          'permission_revoke',
          'oauth_link',
        ],
      );
      expect(
        Sprint116SecurityContract.requiredAuditActions(
          _healthyControls()..oauthFlows = const <Sprint116OAuthFlow>[],
        ),
        isNot(contains('oauth_link')),
      );
    });

    test('an anonymous audit entry cannot be attributed to anyone', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..auditEntries = <Sprint116AuditEntry>[
            _audit(entryId: 'aud_0001', actorId: ''),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('audit_tests:aud_0001'));
    });

    test('record identity is required before any control is trusted', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..oauthFlows = <Sprint116OAuthFlow>[_oauth(controlId: '   ')],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('record_id:oauth:0'));
    });

    test('a live claim without an evidence reference is rejected', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..sessions = <Sprint116SessionCheck>[
            _session(sessionId: 'ses_desktop', source: 'live'),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('no_mock_values:ses_desktop'));
    });

    test('a dependency with an unpinned or unapproved license fails', () {
      final floating = _certifyAll(
        controls: _healthyControls()
          ..dependencies = <Sprint116Dependency>[
            _dependency(
              dependencyId: 'dep_http',
              package: 'http',
              versionConstraint: 'any',
            ),
          ],
      );
      expect(floating.invalidRecords, contains('dependency_scan:dep_http'));

      final copyleft = _certifyAll(
        controls: _healthyControls()
          ..dependencies = <Sprint116Dependency>[
            _dependency(
              dependencyId: 'dep_sdk',
              package: 'some_sdk',
              license: 'GPL-3.0-only',
            ),
          ],
      );
      expect(copyleft.invalidRecords, contains('dependency_scan:dep_sdk'));
    });

    test('an explicit control set can never pass on manifest data', () {
      // The manifest itself is complete and healthy; borrowing it must not be
      // possible when the caller supplied its own broken set.
      final report = _certifyAll(
        controls: _healthyControls()
          ..sessions = <Sprint116SessionCheck>[
            _session(sessionId: 'ses_desktop', tokenInQueryString: true),
          ],
        requireCoverage: false,
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('session_tests:ses_desktop'));
    });

    test('a granted scope the user never requested is escalation', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..oauthFlows = <Sprint116OAuthFlow>[
            _oauth(
              controlId: 'cf_google_pkce',
              requestedScopes: const ['openid', 'email', 'profile'],
              grantedScopes: const [
                'openid',
                'email',
                'https://www.googleapis.com/auth/drive',
              ],
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('oauth_tests:cf_google_pkce'));
    });

    test('a plain code challenge method is not a challenge method', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..oauthFlows = <Sprint116OAuthFlow>[
            _oauth(controlId: 'cf_google_pkce', codeChallengeMethod: 'plain'),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('oauth_tests:cf_google_pkce'));
    });

    test('an OAuth callback outside the allow-list is rejected', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..oauthFlows = <Sprint116OAuthFlow>[
            _oauth(
              controlId: 'cf_google_pkce',
              redirectUri:
                  'https://app.voidscriptor.dev.evil.example/oauth/callback',
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('oauth_tests:cf_google_pkce'));
    });

    test('a control without a reference instant is blocked', () {
      // Lifetime and replay checks are all relative to a clock; without one
      // every timestamp check would pass on an unmeasured assumption.
      final report = Sprint116SecurityCertificationGate().certify(
        controls: _healthyControls(),
      );

      expect(report.state, Sprint116SecurityGateStatus.blocked);
      expect(report.invalidRecords, contains('as_of_epoch_ms'));
    });

    test('coverage is only claimed when every area has positive evidence', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..webhooks = const <Sprint116WebhookEndpoint>[],
        requireCoverage: true,
      );

      expect(report.state, Sprint116SecurityGateStatus.blocked);
      expect(report.invalidRecords, contains('webhook_tests'));
    });

    test('an unrejected duplicate delivery is an unproven dedupe guard', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..webhooks = <Sprint116WebhookEndpoint>[
            _webhook(
              webhookId: 'whk_stripe_invoice',
              duplicateDeliveryDetected: true,
              duplicateDeliveryRejected: false,
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('webhook_tests:whk_stripe_invoice'),
      );
    });

    test('a future-dated event is forged, not fresh', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..webhooks = <Sprint116WebhookEndpoint>[
            _webhook(
              webhookId: 'whk_stripe_invoice',
              eventTimestampEpochMs: 1700000200000,
              processingEpochMs: 1700000200500,
            ),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('webhook_tests:whk_stripe_invoice'),
      );
    });

    test(
      'a session claiming to be dead while its expiry is live is a contradiction',
      () {
        final report = _certifyAll(
          controls: _healthyControls()
            ..sessions = <Sprint116SessionCheck>[
              _session(sessionId: 'ses_desktop', stillActive: false),
            ],
        );

        expect(report.state, Sprint116SecurityGateStatus.fail);
        expect(report.invalidRecords, contains('session_tests:ses_desktop'));
      },
    );

    test(
      'an idle session past its own idle timeout is a timeout that never fired',
      () {
        final report = _certifyAll(
          controls: _healthyControls()
            ..sessions = <Sprint116SessionCheck>[
              _session(
                sessionId: 'ses_desktop',
                lastSeenAtEpochMs: 1699999000000,
                idleTimeoutMs: 900000,
              ),
            ],
        );

        expect(report.state, Sprint116SecurityGateStatus.fail);
        expect(report.invalidRecords, contains('session_tests:ses_desktop'));
      },
    );

    test('a vault without redaction is a leak waiting for a log line', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..vaultEntries = <Sprint116VaultEntry>[
            _vault(vaultId: 'vlt_user_token', logRedactionEnabled: false),
          ],
      );

      expect(report.state, Sprint116SecurityGateStatus.fail);
      expect(report.invalidRecords, contains('vault_tests:vlt_user_token'));
    });

    test('the checked-in manifest certifies without borrowing anything', () {
      final report = Sprint116SecurityCertificationGate().certify();

      expect(report.state, Sprint116SecurityGateStatus.pass);
      expect(report.invalidRecords, isEmpty);
    });

    test('the manifest carries no credential, token, or private key', () {
      final raw = File(
        Sprint116SecurityContract.manifestPath,
      ).readAsStringSync();
      final lower = raw.toLowerCase();

      for (final forbidden in const <String>[
        'sk-',
        'ghp_',
        '-----begin',
        'client_secret":',
        'access_token":',
        'refresh_token":',
        'password":',
      ]) {
        expect(
          lower.contains(forbidden.toLowerCase()),
          isFalse,
          reason: 'manifest must not contain $forbidden',
        );
      }
      final decoded = jsonDecode(raw);
      expect(decoded['live_security_verification'], isFalse);
      expect(decoded['limitations'], isA<String>());
      expect((decoded['limitations'] as String).trim(), isNotEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

Sprint116SecurityReport _certifyAll({
  required Sprint116SecurityControlSet controls,
  bool requireCoverage = false,
}) {
  return Sprint116SecurityCertificationGate().certify(
    controls: controls,
    asOfEpochMs: _now,
    requireCoverage: requireCoverage,
  );
}

Sprint116SecurityControlSet _healthyControls() {
  return Sprint116SecurityControlSet(
    oauthFlows: <Sprint116OAuthFlow>[
      _oauth(controlId: 'cf_google_pkce'),
      _oauth(
        controlId: 'cf_github_pkce',
        allowedRedirectUris: const <String>[
          'https://app.voidscriptor.dev/oauth/github/callback',
        ],
        redirectUri: 'https://app.voidscriptor.dev/oauth/github/callback',
      ),
    ],
    vaultEntries: <Sprint116VaultEntry>[
      _vault(vaultId: 'vlt_user_token'),
      _vault(vaultId: 'vlt_provider_key'),
    ],
    redirects: <Sprint116RedirectCheck>[
      _redirect(redirectId: 'rdr_oauth_callback'),
      _redirect(redirectId: 'rdr_deep_link'),
    ],
    sessions: <Sprint116SessionCheck>[
      _session(sessionId: 'ses_desktop'),
      _session(sessionId: 'ses_mobile'),
    ],
    permissions: <Sprint116PermissionGrant>[
      _permission(grantId: 'grant_api_read'),
      _permission(grantId: 'grant_project_write'),
    ],
    webhooks: <Sprint116WebhookEndpoint>[
      _webhook(webhookId: 'whk_stripe_invoice'),
      _webhook(webhookId: 'whk_github_push'),
    ],
    dependencies: <Sprint116Dependency>[
      _dependency(
        dependencyId: 'dep_http',
        package: 'http',
        license: 'BSD-3-Clause',
      ),
      _dependency(
        dependencyId: 'dep_secure_storage',
        package: 'flutter_secure_storage',
        license: 'BSD-3-Clause',
      ),
    ],
    auditEntries: <Sprint116AuditEntry>[
      _audit(
        entryId: 'aud_0001',
        action: 'token_revoke',
        targetId: 'vlt_user_token',
      ),
      _audit(
        entryId: 'aud_0002',
        action: 'vault_write',
        targetId: 'vlt_provider_key',
      ),
      _audit(
        entryId: 'aud_0003',
        action: 'session_invalidate',
        targetId: 'ses_desktop',
      ),
      _audit(
        entryId: 'aud_0004',
        action: 'permission_revoke',
        targetId: 'grant_api_read',
      ),
      _audit(
        entryId: 'aud_0005',
        action: 'oauth_link',
        targetId: 'provider_google',
      ),
    ],
  );
}

Sprint116OAuthFlow _oauth({
  required String controlId,
  String clientType = 'public',
  bool pkceEnabled = true,
  String codeChallengeMethod = 'S256',
  String stateParameter = 'state_8f2c1d',
  List<String> allowedRedirectUris = const <String>[
    'https://app.voidscriptor.dev/oauth/callback',
  ],
  List<String> allowedRedirectHosts = const <String>['app.voidscriptor.dev'],
  String redirectUri = 'https://app.voidscriptor.dev/oauth/callback',
  List<String> requestedScopes = const <String>['openid', 'email', 'profile'],
  List<String> grantedScopes = const <String>['openid', 'email'],
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116OAuthFlow(
    controlId: controlId,
    providerId: 'provider_google',
    clientType: clientType,
    pkceEnabled: pkceEnabled,
    codeChallengeMethod: codeChallengeMethod,
    stateParameter: stateParameter,
    allowedRedirectUris: allowedRedirectUris,
    allowedRedirectHosts: allowedRedirectHosts,
    redirectUri: redirectUri,
    requestedScopes: requestedScopes,
    grantedScopes: grantedScopes,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116VaultEntry _vault({
  required String vaultId,
  bool secretStoredPlaintext = false,
  bool encryptedAtRest = true,
  String keyId = 'key_2026_q3_01',
  bool keySeparated = true,
  bool toStringIncludesSecret = false,
  bool toJsonIncludesSecret = false,
  bool logRedactionEnabled = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116VaultEntry(
    vaultId: vaultId,
    ownerScope: 'user',
    secretStoredPlaintext: secretStoredPlaintext,
    encryptedAtRest: encryptedAtRest,
    keyId: keyId,
    keySeparated: keySeparated,
    toStringIncludesSecret: toStringIncludesSecret,
    toJsonIncludesSecret: toJsonIncludesSecret,
    logRedactionEnabled: logRedactionEnabled,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RedirectCheck _redirect({
  required String redirectId,
  String finalUrl = 'https://app.voidscriptor.dev/oauth/callback?code=ok',
  List<String> allowedHosts = const <String>['app.voidscriptor.dev'],
  bool requireHttps = true,
  bool resolvedAfterRedirects = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RedirectCheck(
    redirectId: redirectId,
    finalUrl: finalUrl,
    allowedHosts: allowedHosts,
    requireHttps: requireHttps,
    resolvedAfterRedirects: resolvedAfterRedirects,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116SessionCheck _session({
  required String sessionId,
  String subjectId = 'user_0001',
  int issuedAtEpochMs = 1700000000000,
  int expiresAtEpochMs = 1700003600000,
  int absoluteMaxLifetimeMs = 3600000,
  int lastSeenAtEpochMs = 1700000050000,
  int idleTimeoutMs = 900000,
  bool tokenInQueryString = false,
  bool rotatedOnLogin = true,
  bool invalidatedOnLogout = true,
  bool stillActive = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116SessionCheck(
    sessionId: sessionId,
    subjectId: subjectId,
    issuedAtEpochMs: issuedAtEpochMs,
    expiresAtEpochMs: expiresAtEpochMs,
    absoluteMaxLifetimeMs: absoluteMaxLifetimeMs,
    lastSeenAtEpochMs: lastSeenAtEpochMs,
    idleTimeoutMs: idleTimeoutMs,
    tokenInQueryString: tokenInQueryString,
    rotatedOnLogin: rotatedOnLogin,
    invalidatedOnLogout: invalidatedOnLogout,
    stillActive: stillActive,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116PermissionGrant _permission({
  required String grantId,
  String subjectId = 'user_0001',
  String resourceId = 'project_0001',
  List<String> declaredPermissions = const <String>['read', 'write'],
  List<String> requestedPermissions = const <String>['read'],
  List<String> grantedPermissions = const <String>['read'],
  String defaultDecision = 'deny',
  bool escalationOnRefresh = false,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116PermissionGrant(
    grantId: grantId,
    subjectId: subjectId,
    resourceId: resourceId,
    declaredPermissions: declaredPermissions,
    requestedPermissions: requestedPermissions,
    grantedPermissions: grantedPermissions,
    defaultDecision: defaultDecision,
    escalationOnRefresh: escalationOnRefresh,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116WebhookEndpoint _webhook({
  required String webhookId,
  String providerId = 'provider_stripe',
  bool signatureVerifiedBeforeProcessing = true,
  bool constantTimeCompare = true,
  int replayWindowSeconds = 300,
  int eventTimestampEpochMs = 1700000050000,
  int processingEpochMs = 1700000050500,
  bool duplicateDeliveryDetected = false,
  bool duplicateDeliveryRejected = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116WebhookEndpoint(
    webhookId: webhookId,
    providerId: providerId,
    signatureVerifiedBeforeProcessing: signatureVerifiedBeforeProcessing,
    constantTimeCompare: constantTimeCompare,
    replayWindowSeconds: replayWindowSeconds,
    eventTimestampEpochMs: eventTimestampEpochMs,
    processingEpochMs: processingEpochMs,
    duplicateDeliveryDetected: duplicateDeliveryDetected,
    duplicateDeliveryRejected: duplicateDeliveryRejected,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116Dependency _dependency({
  required String dependencyId,
  required String package,
  String versionConstraint = '^1.6.0',
  String license = 'BSD-3-Clause',
  String vulnerabilityStatus = 'clean',
  bool pinnedToLockfile = true,
  bool devOnly = false,
  bool referencedFromProductionCode = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116Dependency(
    dependencyId: dependencyId,
    package: package,
    versionConstraint: versionConstraint,
    license: license,
    vulnerabilityStatus: vulnerabilityStatus,
    pinnedToLockfile: pinnedToLockfile,
    devOnly: devOnly,
    referencedFromProductionCode: referencedFromProductionCode,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116AuditEntry _audit({
  required String entryId,
  String actorId = 'user_0001',
  String action = 'token_revoke',
  String targetId = 'vlt_user_token',
  int occurredAtEpochMs = 1700000050000,
  bool mutatedAfterWrite = false,
  bool payloadContainsSecret = false,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116AuditEntry(
    entryId: entryId,
    actorId: actorId,
    action: action,
    targetId: targetId,
    occurredAtEpochMs: occurredAtEpochMs,
    mutatedAfterWrite: mutatedAfterWrite,
    payloadContainsSecret: payloadContainsSecret,
    source: source,
    evidenceRef: evidenceRef,
  );
}
