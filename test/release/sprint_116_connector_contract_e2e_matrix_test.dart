import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_connector_contract_e2e_matrix.dart';

const int _now = 1700000100000;
const int _base = _now - 604800000;

/// Lifecycle minutes used by every fixture. The order matters: the gate
/// compares the recorded sequence, so a run that claims to disconnect before
/// it ever connected has to be catchable.
const int _connected = 0;
const int _used = 60;
const int _refreshed = 120;
const int _errored = 180;
const int _disconnected = 300;
const int _cleaned = 360;

int _t(int minutes) => _base + minutes * 60000;

void main() {
  group('116.48 Connector Contract & End-to-End Matrix', () {
    test('locks the nine suites the canonical step demands', () {
      expect(Sprint116ConnectorMatrixContract.requiredSuites, <String>[
        'manifest',
        'auth',
        'capability',
        'usage',
        'error',
        'reauth',
        'disconnect',
        'cleanup',
        'regression',
      ]);
      expect(Sprint116ConnectorMatrixContract.canonicalStep, '116.48');
      expect(
        Sprint116ConnectorMatrixContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
      expect(
        Sprint116ConnectorMatrixContract.manifestPath,
        'docs/planning/v1.2/sprint_116_connector_contract_e2e_matrix.json',
      );
      expect(Sprint116ConnectorMatrixContract.knownAuthTypes, <String>[
        'oauth2_pkce',
        'oidc',
        'device_code',
        'api_key',
        'local_broker',
        'none',
      ]);
      expect(
        Sprint116ConnectorMatrixContract.knownCapabilities,
        contains('ai_text'),
      );
      expect(
        Sprint116ConnectorMatrixContract.knownCapabilities,
        contains('storage'),
      );
      expect(
        Sprint116ConnectorMatrixContract.knownErrorStates,
        contains('rate_limited'),
      );
      expect(
        Sprint116ConnectorMatrixContract.knownUsageUnits,
        contains('tokens'),
      );
      expect(Sprint116ConnectorMatrixContract.maxEvidenceAgeDays, 180);
    });

    test('a complete proposed connector set certifies', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.coveredSuites, containsAll(<String>['cleanup', 'reauth']));
      expect(report.unauditedConnectors, isEmpty);
    });

    test('no reference clock is blocked, not passed', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(),
        asOfEpochMs: 0,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.blocked);
      expect(report.invalidRecords, <String>['as_of_epoch_ms']);
    });

    test('an empty suite is a gap rather than a pass', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(reconnect: <Sprint116ReauthRun>[]),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.blocked);
      expect(report.invalidRecords, <String>['reauth']);
    });

    test('an empty manifest means no connector was even proposed', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(manifests: <Sprint116ConnectorManifestRecord>[]),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.blocked);
      expect(report.invalidRecords, <String>['manifest']);
    });

    test(
      'a connector nobody audited cannot ride on another connector rows',
      () {
        final report = Sprint116ConnectorE2EMatrix().certify(
          controls: _controls(
            manifests: <Sprint116ConnectorManifestRecord>[
              _manifest(),
              _manifest(
                connectorId: 'conn_google_drive',
                providerId: 'google_drive',
              ),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116ConnectorMatrixStatus.fail);
        expect(
          report.invalidRecords,
          contains('suite_coverage:conn_google_drive'),
        );
        expect(report.unauditedConnectors, contains('conn_google_drive'));
      },
    );

    test('a proposed connector with no manifest row is a phantom', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[
            _connect(),
            _connect(connectorId: 'conn_phantom', tokenSha256: _sha('p')),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(
        report.invalidRecords,
        contains('manifest_agreement:conn_phantom'),
      );
    });

    test('availability cannot be claimed from a local fixture', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          manifests: <Sprint116ConnectorManifestRecord>[
            _manifest(availability: 'AVAILABLE'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('manifest:conn_openai'));
    });

    test('a scope the app never asked for is a consent defect', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[
            _connect(
              requestedScopes: <String>['read', 'write'],
              grantedScopes: <String>['read', 'write', 'admin'],
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('auth:conn_openai'));
    });

    test('a partial grant must be admitted, not absorbed', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[
            _connect(
              requestedScopes: <String>['read', 'write'],
              grantedScopes: <String>['read'],
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('auth:conn_openai'));
    });

    test('plain PKCE is a downgrade, not a hardening', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[_connect(pkceMethod: 'plain')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('auth:conn_openai'));
    });

    test('an api key connector may not claim a token refresh', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          manifests: <Sprint116ConnectorManifestRecord>[
            _manifest(),
            _manifest(
              connectorId: 'conn_midtrans',
              providerId: 'midtrans',
              authType: 'api_key',
              capabilities: <String>['payment'],
            ),
          ],
          authRuns: <Sprint116ConnectRun>[
            _connect(),
            _connect(
              connectorId: 'conn_midtrans',
              tokenSha256: _sha('midtrans'),
            ),
          ],
          capabilityRuns: <Sprint116CapabilityRun>[
            _capability(),
            _capability(
              connectorId: 'conn_midtrans',
              exercisedCapabilities: <String>['payment'],
            ),
          ],
          usageRuns: <Sprint116UsageRun>[
            _usage(),
            _usage(
              connectorId: 'conn_midtrans',
              unit: 'credits',
              meter: 'settlement_balance',
              attributedCapability: 'payment',
            ),
          ],
          errorRuns: <Sprint116ErrorRun>[
            _error(),
            _error(connectorId: 'conn_midtrans'),
          ],
          reconnect: <Sprint116ReauthRun>[
            _reauth(),
            _reauth(
              connectorId: 'conn_midtrans',
              strategy: 'not_applicable',
              refreshedTokenSha256: _sha('midtrans'),
            ),
          ],
          disconnectRuns: <Sprint116DisconnectRun>[
            _disconnect(),
            _disconnect(connectorId: 'conn_midtrans'),
          ],
          cleanupRuns: <Sprint116CleanupRun>[
            _cleanup(),
            _cleanup(connectorId: 'conn_midtrans'),
          ],
          regressionRuns: <Sprint116RegressionRun>[
            _regression(),
            _regression(connectorId: 'conn_midtrans'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('reauth:conn_midtrans'));
    });

    test(
      'a refresh that only happens after expiry is a user-visible outage',
      () {
        final report = Sprint116ConnectorE2EMatrix().certify(
          controls: _controls(
            reconnect: <Sprint116ReauthRun>[
              _reauth(
                refreshedAtMinutes: 90,
                refreshedTokenExpiresMinutes: 100,
              ),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116ConnectorMatrixStatus.fail);
        expect(report.invalidRecords, contains('reauth:conn_openai'));
      },
    );

    test('a refresh that returns the same credential is not a refresh', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          reconnect: <Sprint116ReauthRun>[
            _reauth(refreshedTokenSha256: _sha('openai')),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('reauth:conn_openai'));
    });

    test(
      'a call the connector still answers after unlink is a privacy failure',
      () {
        final report = Sprint116ConnectorE2EMatrix().certify(
          controls: _controls(
            disconnectRuns: <Sprint116DisconnectRun>[
              _disconnect(callsAfterDisconnectRejected: false),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116ConnectorMatrixStatus.fail);
        expect(report.invalidRecords, contains('disconnect:conn_openai'));
      },
    );

    test('disconnecting something already disconnected proves nothing', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          disconnectRuns: <Sprint116DisconnectRun>[
            _disconnect(stateBeforeDisconnect: 'disconnected'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('disconnect:conn_openai'));
    });

    test('a cleanup that leaves the token usable is not a cleanup', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          cleanupRuns: <Sprint116CleanupRun>[
            _cleanup(postCleanupProbeAuthorized: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('cleanup:conn_openai'));
    });

    test(
      'a usage probe after cleanup still holding a session is a contradiction',
      () {
        // Cleanup claims removal, yet a later run reports a valid session. Both
        // records look healthy on their own; only the join can see the lie.
        final report = Sprint116ConnectorE2EMatrix().certify(
          controls: _controls(
            usageRuns: <Sprint116UsageRun>[
              _usage(observedAtEpochMs: _t(_cleaned + 60), sessionValid: true),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116ConnectorMatrixStatus.fail);
        expect(
          report.invalidRecords,
          contains('credential_residue:conn_openai'),
        );
      },
    );

    test('disconnecting the whole app is not the app right to take', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          cleanupRuns: <Sprint116CleanupRun>[
            _cleanup(localProjectDataDeleted: true),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('cleanup:conn_openai'));
    });

    test('cleanup without the audit trail destroys the security gate', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          cleanupRuns: <Sprint116CleanupRun>[_cleanup(auditRetained: false)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('cleanup:conn_openai'));
    });

    test(
      'a capability the manifest declares but nobody probes is unverified',
      () {
        final report = Sprint116ConnectorE2EMatrix().certify(
          controls: _controls(
            capabilityRuns: <Sprint116CapabilityRun>[
              _capability(exercisedCapabilities: <String>['ai_text']),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116ConnectorMatrixStatus.fail);
        expect(
          report.invalidRecords,
          contains('capability_unexercised:conn_openai:ai_image'),
        );
      },
    );

    test('a call beyond the declared capability is a manifest bug', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          capabilityRuns: <Sprint116CapabilityRun>[
            _capability(
              exercisedCapabilities: <String>[
                'ai_text',
                'ai_image',
                'ai_audio',
              ],
            ),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(
        report.invalidRecords,
        contains('capability_undeclared:conn_openai:ai_audio'),
      );
    });

    test('a swallowed error is invisible to the author', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          errorRuns: <Sprint116ErrorRun>[_error(failureSurfaced: false)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('error:conn_openai'));
    });

    test('an unknown error state cannot be certified as a known one', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          errorRuns: <Sprint116ErrorRun>[_error(errorState: 'teapot')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('error:conn_openai'));
    });

    test('a usage figure with no meter is a number somebody made up', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          usageRuns: <Sprint116UsageRun>[_usage(unit: 'requests', meter: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('usage:conn_openai'));
    });

    test('unknown usage is not the same as zero', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          usageRuns: <Sprint116UsageRun>[
            _usage(rawValue: 0, valueAvailable: false),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('usage:conn_openai'));
    });

    test('a usage snapshot from the future is not a measurement', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          usageRuns: <Sprint116UsageRun>[
            _usage(observedAtEpochMs: _now + 60000),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('usage:conn_openai'));
    });

    test('disconnect cannot be recorded before the connection existed', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          disconnectRuns: <Sprint116DisconnectRun>[
            _disconnect(disconnectedAtMinutes: _connected - 30),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('lifecycle_ordering:conn_openai'));
    });

    test('cleanup before disconnect leaves nothing to clean', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          cleanupRuns: <Sprint116CleanupRun>[
            _cleanup(cleanedAtMinutes: _disconnected - 30),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('lifecycle_ordering:conn_openai'));
    });

    test('a regression run that failed cannot be filed as a passing gate', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          regressionRuns: <Sprint116RegressionRun>[_regression(exitCode: 1)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(
        report.invalidRecords,
        contains('regression:conn_openai:gate_chain'),
      );
    });

    test('a regression run that passed nothing is not a regression', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          regressionRuns: <Sprint116RegressionRun>[
            _regression(passed: 0, total: 0),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(
        report.invalidRecords,
        contains('regression:conn_openai:gate_chain'),
      );
    });

    test('a skipped test needs a name and an owner', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          regressionRuns: <Sprint116RegressionRun>[_regression(skipped: 3)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(
        report.invalidRecords,
        contains('regression_skip:conn_openai:gate_chain'),
      );
    });

    test('regressing one suite does not regress the other eight', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          regressionRuns: <Sprint116RegressionRun>[
            _regression(coveredSuites: <String>['regression']),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('regression_suite_coverage:auth'));
    });

    test('a live row without evidence is a mock value', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[
            _connect(source: 'live', evidenceRef: ''),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('no_mock_values:conn_openai'));
    });

    test('an unknown source is not a source', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[_connect(source: 'vibes')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('no_mock_values:conn_openai'));
    });

    test('a callback with no state parameter cannot be tied to a request', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          authRuns: <Sprint116ConnectRun>[_connect(stateParameter: '')],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('auth:conn_openai'));
    });

    test('an auth type nobody recognises is not a contract', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          manifests: <Sprint116ConnectorManifestRecord>[
            _manifest(authType: 'carrier_pigeon'),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('manifest:conn_openai'));
    });

    test('a connector declaring no capability is a name, not a contract', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          manifests: <Sprint116ConnectorManifestRecord>[
            _manifest(capabilities: const <String>[]),
          ],
          capabilityRuns: <Sprint116CapabilityRun>[
            _capability(exercisedCapabilities: const <String>[]),
          ],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('manifest:conn_openai'));
    });

    test(
      'payload that leaves the device unencrypted is a transport defect',
      () {
        final report = Sprint116ConnectorE2EMatrix().certify(
          controls: _controls(
            capabilityRuns: <Sprint116CapabilityRun>[
              _capability(leavesDevice: true, dataEgressEncrypted: false),
            ],
          ),
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116ConnectorMatrixStatus.fail);
        expect(report.invalidRecords, contains('capability:conn_openai'));
      },
    );

    test('an error nobody proved recovers from is a hope, not a test', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          errorRuns: <Sprint116ErrorRun>[_error(recoveryVerifiedAtEpochMs: 0)],
        ),
        asOfEpochMs: _now,
      );
      expect(report.state, Sprint116ConnectorMatrixStatus.fail);
      expect(report.invalidRecords, contains('error:conn_openai'));
    });

    test('the local manifest is UNVERIFIED and free of secrets', () {
      final matrix = Sprint116ConnectorE2EMatrix();
      final report = matrix.certify();
      expect(report.state, Sprint116ConnectorMatrixStatus.pass);
      expect(report.invalidRecords, isEmpty);
      expect(report.unauditedConnectors, isEmpty);
      expect(report.toJson()['live_connector_execution'], isFalse);
      expect(report.toJson()['canonical_step'], '116.48');
      expect(report.coveredSuites, <String>[
        'auth',
        'capability',
        'cleanup',
        'disconnect',
        'error',
        'manifest',
        'reauth',
        'regression',
        'usage',
      ]);

      final raw = File(
        Sprint116ConnectorMatrixContract.manifestPath,
      ).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_connector_execution'], isFalse);
      expect(manifest['as_of_epoch_ms'], _now);
      expect(
        manifest['acceptance_suites'],
        Sprint116ConnectorMatrixContract.requiredSuites,
      );
      // Key names are inspected, not raw prose: the limitations text says
      // "no credential" on purpose, and a substring scan would flag that
      // disclaimer as the very leak it denies.
      //
      // Declared enum members are exempt as *values* only. `api_key` is the
      // name of an auth type the contract recognises, so it carries no
      // entropy and cannot be a credential, while a real secret pasted into
      // the same field would not be a declared member and still trips.
      final vocabulary = <String>{
        ...Sprint116ConnectorMatrixContract.knownAuthTypes,
        ...Sprint116ConnectorMatrixContract.knownCapabilities,
        ...Sprint116ConnectorMatrixContract.knownErrorStates,
        ...Sprint116ConnectorMatrixContract.knownUsageUnits,
        ...Sprint116ConnectorMatrixContract.knownReauthStrategies,
        ...Sprint116ConnectorMatrixContract.knownPreDisconnectStates,
        ...Sprint116ConnectorMatrixContract.supportedSources,
        ...Sprint116ConnectorMatrixContract.requiredSuites,
      };

      for (final secret in <String>[
        'api_key',
        'apikey',
        'access_token',
        'bearer',
        'client_secret',
        'password',
        'private_key',
      ]) {
        bool carriesSecret(Object? node) {
          if (node is Map) {
            for (final entry in node.entries) {
              if (entry.key.toString().toLowerCase().contains(secret)) {
                return true;
              }
              if (carriesSecret(entry.value)) return true;
            }
            return false;
          }
          if (node is List) return node.any(carriesSecret);
          final text = node.toString();
          if (vocabulary.contains(text)) return false;
          return text.toLowerCase().contains(secret);
        }

        expect(
          carriesSecret(manifest),
          isFalse,
          reason: 'manifest must not carry $secret',
        );
      }

      // Positive control: the exemption above is narrow, so a real value in
      // the same field is still caught. Without this the scanner could be
      // weakened into silence and every assertion above would be theatre.
      for (final secret in <String>['api_key', 'password']) {
        bool wouldBeCaught(Map<String, Object?> node) {
          bool walk(Object? value) {
            if (value is Map) {
              for (final entry in value.entries) {
                if (entry.key.toString().toLowerCase().contains(secret)) {
                  return true;
                }
                if (walk(entry.value)) return true;
              }
              return false;
            }
            if (value is List) return value.any(walk);
            final text = value.toString();
            if (vocabulary.contains(text)) return false;
            return text.toLowerCase().contains(secret);
          }

          return walk(node);
        }

        expect(
          wouldBeCaught(<String, Object?>{
            'manifests': <Object?>[
              <String, Object?>{'auth_type': '$secret=not-a-real-value'},
            ],
          }),
          isTrue,
          reason: 'a real credential in an auth_type field must be caught',
        );
      }
    });

    test('coverage mode still reports the area nobody proved', () {
      final report = Sprint116ConnectorE2EMatrix().certify(
        controls: _controls(
          errorRuns: <Sprint116ErrorRun>[_error(errorState: 'teapot')],
        ),
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.invalidRecords, contains('area_coverage:error'));
    });
  });
}

// The default is the healthy single-connector fixture, and an explicitly
// passed empty list stays empty. A helper that substitutes a fixture when the
// caller sends an empty list can never assert "this area was not run".
Sprint116ConnectorControlSet _controls({
  List<Sprint116ConnectorManifestRecord>? manifests,
  List<Sprint116ConnectRun>? authRuns,
  List<Sprint116CapabilityRun>? capabilityRuns,
  List<Sprint116UsageRun>? usageRuns,
  List<Sprint116ErrorRun>? errorRuns,
  List<Sprint116ReauthRun>? reconnect,
  List<Sprint116DisconnectRun>? disconnectRuns,
  List<Sprint116CleanupRun>? cleanupRuns,
  List<Sprint116RegressionRun>? regressionRuns,
}) {
  return Sprint116ConnectorControlSet(
    manifests: manifests ?? <Sprint116ConnectorManifestRecord>[_manifest()],
    connectRuns: authRuns ?? <Sprint116ConnectRun>[_connect()],
    capabilityRuns: capabilityRuns ?? <Sprint116CapabilityRun>[_capability()],
    usageRuns: usageRuns ?? <Sprint116UsageRun>[_usage()],
    errorRuns: errorRuns ?? <Sprint116ErrorRun>[_error()],
    reauthRuns: reconnect ?? <Sprint116ReauthRun>[_reauth()],
    disconnectRuns: disconnectRuns ?? <Sprint116DisconnectRun>[_disconnect()],
    cleanupRuns: cleanupRuns ?? <Sprint116CleanupRun>[_cleanup()],
    regressionRuns: regressionRuns ?? <Sprint116RegressionRun>[_regression()],
  );
}

String _sha(String seed) {
  final body = seed.padRight(64, '0');
  return body.substring(0, 64);
}

Sprint116ConnectorManifestRecord _manifest({
  String connectorId = 'conn_openai',
  String providerId = 'openai',
  String authType = 'oauth2_pkce',
  String availability = 'UNVERIFIED',
  List<String> capabilities = const <String>['ai_text', 'ai_image'],
}) {
  return Sprint116ConnectorManifestRecord(
    connectorId: connectorId,
    providerId: providerId,
    connectorVersion: '1.4.2',
    authType: authType,
    declaredCapabilities: capabilities,
    requestedPermissions: const <String>[
      'usage_metadata',
      'provider_connection',
    ],
    availability: availability,
    proposed: true,
    evidenceRef: null,
    source: 'synthetic_local',
  );
}

Sprint116ConnectRun _connect({
  String connectorId = 'conn_openai',
  String pkceMethod = 'S256',
  String stateParameter = 'state-7f1a',
  List<String> requestedScopes = const <String>['read', 'write'],
  List<String> grantedScopes = const <String>['read', 'write'],
  String tokenSha256 = '',
  String source = 'synthetic_local',
  String? evidenceRef,
  int connectedAtMinutes = _connected,
}) {
  return Sprint116ConnectRun(
    connectorId: connectorId,
    pkceMethod: pkceMethod,
    stateParameter: stateParameter,
    requestedScopes: requestedScopes,
    grantedScopes: grantedScopes,
    partialGrantAccepted: false,
    tokenSha256: tokenSha256.isEmpty ? _sha('openai') : tokenSha256,
    secretRedactedInLogs: true,
    connectedAtEpochMs: _t(connectedAtMinutes),
    atEpochMs: _t(connectedAtMinutes),
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116CapabilityRun _capability({
  String connectorId = 'conn_openai',
  List<String> exercisedCapabilities = const <String>['ai_text', 'ai_image'],
  bool leavesDevice = false,
  bool dataEgressEncrypted = false,
  int atMinutes = _used,
}) {
  return Sprint116CapabilityRun(
    connectorId: connectorId,
    exercisedCapabilities: exercisedCapabilities,
    callSucceeded: true,
    failureClassified: true,
    leavesDevice: leavesDevice,
    dataEgressEncrypted: dataEgressEncrypted,
    sessionValid: true,
    atEpochMs: _t(atMinutes),
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116UsageRun _usage({
  String connectorId = 'conn_openai',
  String unit = 'tokens',
  String meter = 'total_tokens',
  String attributedCapability = 'ai_text',
  num rawValue = 184320,
  bool valueAvailable = true,
  int? observedAtEpochMs,
  bool sessionValid = true,
}) {
  return Sprint116UsageRun(
    connectorId: connectorId,
    unit: unit,
    meter: meter,
    rawValue: rawValue,
    valueAvailable: valueAvailable,
    attributedCapability: attributedCapability,
    observedAtEpochMs: observedAtEpochMs ?? _t(_used + 30),
    freshnessTtlSeconds: 3600,
    sessionValid: sessionValid,
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116ErrorRun _error({
  String connectorId = 'conn_openai',
  String errorState = 'rate_limited',
  bool failureSurfaced = true,
  int? recoveryVerifiedAtEpochMs,
  int atMinutes = _errored,
}) {
  return Sprint116ErrorRun(
    connectorId: connectorId,
    errorState: errorState,
    httpStatus: 429,
    failureSurfaced: failureSurfaced,
    userMessage: 'Provider is rate limited. Try again in 30 seconds.',
    recoveryVerifiedAtEpochMs: recoveryVerifiedAtEpochMs ?? _t(atMinutes + 5),
    atEpochMs: _t(atMinutes),
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116ReauthRun _reauth({
  String connectorId = 'conn_openai',
  String strategy = 'token_refresh',
  String refreshedTokenSha256 = '',
  int refreshedAtMinutes = _refreshed,
  int refreshedTokenExpiresMinutes = _refreshed + 240,
}) {
  return Sprint116ReauthRun(
    connectorId: connectorId,
    strategy: strategy,
    priorTokenSha256: _sha('openai'),
    refreshedTokenSha256: refreshedTokenSha256.isEmpty
        ? _sha('openai-rotated')
        : refreshedTokenSha256,
    priorTokenInvalidated: true,
    refreshedTokenExpiresEpochMs: _t(refreshedTokenExpiresMinutes),
    refreshedAtEpochMs: _t(refreshedAtMinutes),
    sessionValidAfterReauth: true,
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116DisconnectRun _disconnect({
  String connectorId = 'conn_openai',
  String stateBeforeDisconnect = 'connected',
  bool callsAfterDisconnectRejected = true,
  int disconnectedAtMinutes = _disconnected,
}) {
  return Sprint116DisconnectRun(
    connectorId: connectorId,
    stateBeforeDisconnect: stateBeforeDisconnect,
    disconnectRequested: true,
    callsAfterDisconnectRejected: callsAfterDisconnectRejected,
    newTokensIssuedAfterDisconnect: false,
    disconnectedAtEpochMs: _t(disconnectedAtMinutes),
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116CleanupRun _cleanup({
  String connectorId = 'conn_openai',
  bool postCleanupProbeAuthorized = false,
  bool localProjectDataDeleted = false,
  bool auditRetained = true,
  int cleanedAtMinutes = _cleaned,
}) {
  return Sprint116CleanupRun(
    connectorId: connectorId,
    tokenRemoved: true,
    cacheRemoved: true,
    vaultEntryRemoved: true,
    postCleanupProbeAuthorized: postCleanupProbeAuthorized,
    localProjectDataDeleted: localProjectDataDeleted,
    auditRetained: auditRetained,
    cleanedAtEpochMs: _t(cleanedAtMinutes),
    source: 'synthetic_local',
    evidenceRef: null,
  );
}

Sprint116RegressionRun _regression({
  String connectorId = 'conn_openai',
  String runId = 'gate_chain',
  int exitCode = 0,
  int passed = 187,
  int total = 187,
  int skipped = 0,
  List<String> coveredSuites = const <String>[
    'manifest',
    'auth',
    'capability',
    'usage',
    'error',
    'reauth',
    'disconnect',
    'cleanup',
    'regression',
  ],
}) {
  return Sprint116RegressionRun(
    connectorId: connectorId,
    runId: runId,
    command: 'flutter test --no-pub test/release',
    exitCode: exitCode,
    passed: passed,
    total: total,
    skipped: skipped,
    skipReason: '',
    coveredSuites: coveredSuites,
    headSha: 'a' * 40,
    source: 'local_run',
    evidenceRef: 'docs/evidence/sprint-116-48-regression-20260930.meta',
  );
}
