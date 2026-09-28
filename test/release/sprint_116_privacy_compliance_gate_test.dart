import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_privacy_compliance_gate.dart';

const int _now = 1700000100000;

void main() {
  group('116.46 Privacy & Compliance Gate', () {
    test(
      'locks the eight privacy evidence areas the canonical step demands',
      () {
        expect(Sprint116PrivacyContract.requiredAreas, <String>[
          'data_flow',
          'consent',
          'minimization',
          'destinations',
          'retention',
          'deletion',
          'disconnect',
          'terms_limits',
        ]);
        expect(Sprint116PrivacyContract.canonicalStep, '116.46');
        expect(Sprint116PrivacyContract.externalGates, 'DEFERRED-EXTERNAL');
        expect(
          Sprint116PrivacyContract.manifestPath,
          'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json',
        );
        expect(Sprint116PrivacyContract.supportedSources, <String>[
          'synthetic_local',
          'live',
        ]);
        expect(
          Sprint116PrivacyContract.knownDataCategories,
          contains('billing'),
        );
        expect(
          Sprint116PrivacyContract.knownDataCategories,
          isNot(contains('unknown')),
          reason: 'an unresolved category must not be a nameable category',
        );
        expect(Sprint116PrivacyContract.knownRegions, contains('eu'));
        expect(Sprint116PrivacyContract.knownRegions, isNot(contains('mars')));
        expect(Sprint116PrivacyContract.transferMechanisms, <String>[
          'none_required',
          'adequacy_decision',
          'standard_contract_clauses',
          'privacy_shield',
        ]);
      },
    );

    test('a complete healthy control set certifies and covers every area', () {
      final report = _certifyAll(
        controls: _healthyControls(),
        requireCoverage: true,
      );

      expect(report.state, Sprint116PrivacyGateStatus.pass);
      expect(report.invalidRecords, isEmpty);
      for (final area in Sprint116PrivacyContract.requiredAreas) {
        expect(report.coveredAreas, contains(area));
      }
      expect(report.uncoveredPurposes, isEmpty);
      expect(report.uncertifiedDestinations, isEmpty);
      expect(report.unretainedCategories, isEmpty);
      expect(report.unreviewedProviders, isEmpty);
      expect(report.toJson()['live_privacy_verification'], isFalse);
      expect(report.toJson()['canonical_step'], '116.46');
      expect(report.toJson()['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('empty control sets are blocked rather than certified', () {
      final certification = Sprint116PrivacyCertificationGate();

      for (final empty in <Sprint116PrivacyControlSet>[
        _healthyControls()..dataFlows = const <Sprint116DataFlow>[],
        _healthyControls()..consents = const <Sprint116ConsentRecord>[],
        _healthyControls()..datasets = const <Sprint116MinimizationRecord>[],
        _healthyControls()..destinations = const <Sprint116Destination>[],
        _healthyControls()..retentions = const <Sprint116RetentionRule>[],
        _healthyControls()..deletions = const <Sprint116DeletionRequest>[],
        _healthyControls()..disconnects = const <Sprint116AccountDisconnect>[],
        _healthyControls()..termsReviews = const <Sprint116ProviderTerms>[],
      ]) {
        final report = certification.certify(
          controls: empty,
          asOfEpochMs: _now,
        );
        expect(report.state, Sprint116PrivacyGateStatus.blocked);
        expect(report.invalidRecords, hasLength(1));
      }
    });

    test('a run without a reference clock is blocked, not certified', () {
      final report = Sprint116PrivacyCertificationGate().certify(
        controls: _healthyControls(),
        asOfEpochMs: 0,
      );
      expect(report.state, Sprint116PrivacyGateStatus.blocked);
      expect(report.invalidRecords, contains('as_of_epoch_ms'));
    });

    test('a data flow with no stated purpose cannot be certified', () {
      // No purpose means no lawful basis; the record still flowing is the
      // entire problem this gate exists to catch.
      final report = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', purpose: '   '),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('data_flow:flow_google'));
    });

    test('an unresolved data category fails rather than passing quietly', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(
              flowId: 'flow_google',
              dataCategories: const <String>['account_identity', 'unknown'],
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('data_flow:flow_google'));
    });

    test('personal data may not travel unencrypted or unredacted', () {
      final unencrypted = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', encryptedInTransit: false),
          ],
      );
      expect(unencrypted.invalidRecords, contains('data_flow:flow_google'));

      final unredacted = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', fieldsRedactedInLogs: false),
          ],
      );
      expect(unredacted.invalidRecords, contains('data_flow:flow_google'));
    });

    test('a pre-ticked or bundled consent is not consent', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..consents = <Sprint116ConsentRecord>[
            _consent(consentId: 'cns_google', bundledOrPreTicked: true),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('consent:cns_google'));
    });

    test('consent that contradicts its own timestamps fails', () {
      // A refusal is a real, coherent record, so it carries a withdrawal
      // stamp rather than a granted_at it never earned.
      final notGranted = _certifyAll(
        controls: _healthyControls()
          ..consents = <Sprint116ConsentRecord>[
            _consent(
              consentId: 'cns_google',
              granted: false,
              grantedAtEpochMs: 0,
              withdrawnAtEpochMs: 1699995000000,
            ),
          ],
      );
      expect(notGranted.state, Sprint116PrivacyGateStatus.fail);
      expect(
        notGranted.invalidRecords,
        contains('consent:cns_google'),
        reason: 'a refusal carrying a granted_at is a contradiction',
      );

      final backwards = _certifyAll(
        controls: _healthyControls()
          ..consents = <Sprint116ConsentRecord>[
            _consent(
              consentId: 'cns_google',
              grantedAtEpochMs: 1699999000000,
              withdrawnAtEpochMs: 1699990000000,
            ),
          ],
      );
      expect(
        backwards.invalidRecords,
        contains('consent:cns_google'),
        reason: 'withdrawal predates the grant it claims to cancel',
      );
    });

    test('a future-dated or irrevocable consent fails', () {
      final future = _certifyAll(
        controls: _healthyControls()
          ..consents = <Sprint116ConsentRecord>[
            _consent(consentId: 'cns_google', grantedAtEpochMs: 1700000900000),
          ],
      );
      expect(future.invalidRecords, contains('consent:cns_google'));

      final irrevocable = _certifyAll(
        controls: _healthyControls()
          ..consents = <Sprint116ConsentRecord>[
            _consent(consentId: 'cns_google', revocable: false),
          ],
      );
      expect(irrevocable.invalidRecords, contains('consent:cns_google'));
    });

    test('a live flow whose purpose has no granted consent is uncovered', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..consents = <Sprint116ConsentRecord>[
            _consent(consentId: 'cns_google', purpose: 'authenticate_user'),
            _consent(
              consentId: 'cns_stripe',
              purpose: 'process_payment',
              granted: false,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(
        report.invalidRecords,
        contains('consent_coverage:process_payment'),
      );
      expect(report.uncoveredPurposes, contains('process_payment'));
    });

    test('a withdrawn consent does not cover a flow still running', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', purpose: 'authenticate_user'),
            _flow(
              flowId: 'flow_telemetry',
              providerId: 'provider_local',
              dataCategories: const <String>['usage_telemetry'],
              purpose: 'improve_product',
              personalData: true,
              leavesDevice: true,
            ),
          ]
          ..consents = <Sprint116ConsentRecord>[
            _consent(consentId: 'cns_google', purpose: 'authenticate_user'),
            _consent(consentId: 'cns_stripe', purpose: 'process_payment'),
            _consent(
              consentId: 'cns_telemetry',
              purpose: 'improve_product',
              grantedAtEpochMs: 1699990000000,
              withdrawnAtEpochMs: 1699999000000,
            ),
          ],
      );
      expect(
        report.invalidRecords,
        contains('consent_coverage:improve_product'),
      );
    });

    test('fields collected beyond the declared purpose fail minimization', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..datasets = <Sprint116MinimizationRecord>[
            _dataset(
              datasetId: 'ds_account',
              collectedFields: const <String>[
                'email',
                'date_of_birth',
                'home_address',
              ],
              purposeRequiredFields: const <String>['email'],
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('minimization:ds_account'));
    });

    test('a retained field that was never collected fails minimization', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..datasets = <Sprint116MinimizationRecord>[
            _dataset(
              datasetId: 'ds_account',
              collectedFields: const <String>['email'],
              purposeRequiredFields: const <String>['email'],
              retainedFields: const <String>['email', 'device_fingerprint'],
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('minimization:ds_account'));
    });

    test('a destination reached over plaintext is not a lawful transfer', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..destinations = <Sprint116Destination>[
            _destination(destinationId: 'dst_google', scheme: 'http'),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('destinations:dst_google'));
    });

    test('an unknown region fails rather than passing as undeclared', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..destinations = <Sprint116Destination>[
            _destination(destinationId: 'dst_google', region: 'mars'),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('destinations:dst_google'));
    });

    test('cross-border transfer without a mechanism is not compliance', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..destinations = <Sprint116Destination>[
            _destination(
              destinationId: 'dst_google',
              crossBorderTransfer: true,
              transferMechanism: '',
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('destinations:dst_google'));
    });

    test('an unrecognized transfer mechanism is not a mechanism', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..destinations = <Sprint116Destination>[
            _destination(
              destinationId: 'dst_google',
              crossBorderTransfer: true,
              transferMechanism: 'vibes',
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('destinations:dst_google'));
    });

    test('personal data shared without a listed subprocessor fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..destinations = <Sprint116Destination>[
            _destination(
              destinationId: 'dst_google',
              subprocessorListed: false,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('destinations:dst_google'));
    });

    test(
      'a category leaving the device with no declared destination fails',
      () {
        // `contact` is in circulation via the account flow, but the only
        // destinations declare `account_identity` and `billing`. A destination
        // that exists for a different category does not cover this one.
        final report = _certifyAll(
          controls: _healthyControls()
            ..destinations = <Sprint116Destination>[
              _destination(
                destinationId: 'dst_google',
                dataCategories: const <String>['account_identity'],
              ),
              _destination(
                destinationId: 'dst_stripe',
                providerId: 'provider_stripe',
                crossBorderTransfer: false,
                transferMechanism: 'none_required',
                dataCategories: const <String>['billing'],
              ),
            ],
        );
        expect(report.state, Sprint116PrivacyGateStatus.fail);
        expect(
          report.invalidRecords,
          contains('destination_coverage:flow_google:contact'),
        );
        expect(report.uncertifiedDestinations, contains('flow_google:contact'));
      },
    );

    test('a destination provider whose terms were never reviewed fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(providerId: 'provider_google'),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('terms_coverage:provider_stripe'));
      expect(report.unreviewedProviders, contains('provider_stripe'));
    });

    test('a retention window of zero or over the policy cap fails', () {
      final zero = _certifyAll(
        controls: _healthyControls()
          ..retentions = <Sprint116RetentionRule>[
            _retention(retentionId: 'ret_billing', retentionDays: 0),
          ],
      );
      expect(zero.invalidRecords, contains('retention:ret_billing'));

      final overCap = _certifyAll(
        controls: _healthyControls()
          ..retentions = <Sprint116RetentionRule>[
            _retention(retentionId: 'ret_billing', retentionDays: 36500),
          ],
      );
      expect(overCap.invalidRecords, contains('retention:ret_billing'));
    });

    test('a record still present past its own retention window fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..retentions = <Sprint116RetentionRule>[
            _retention(
              retentionId: 'ret_billing',
              retentionDays: 30,
              windowStartedAtEpochMs: 1690000000000,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('retention:ret_billing'));
    });

    test('retention held indefinitely without a justification fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..retentions = <Sprint116RetentionRule>[
            _retention(
              retentionId: 'ret_billing',
              retentionDays: 30,
              windowStartedAtEpochMs: 1690000000000,
              legalHold: true,
              legalHoldJustification: '  ',
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('retention:ret_billing'));
    });

    test('disabling automatic deletion fails retention', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..retentions = <Sprint116RetentionRule>[
            _retention(retentionId: 'ret_billing', autoDeleteEnabled: false),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('retention:ret_billing'));
    });

    test('a category with no retention rule at all is unretained', () {
      // `creative_content` is in circulation via the account flow but has no
      // retention rule, so the promise is missing rather than merely wrong.
      final report = _certifyAll(
        controls: _healthyControls()
          ..retentions = <Sprint116RetentionRule>[
            _retention(
              retentionId: 'ret_identity',
              dataCategory: 'account_identity',
            ),
            _retention(retentionId: 'ret_contact', dataCategory: 'contact'),
            _retention(
              retentionId: 'ret_telemetry',
              dataCategory: 'usage_telemetry',
            ),
            _retention(retentionId: 'ret_billing', dataCategory: 'billing'),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.pass);

      final missing = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(
              flowId: 'flow_google',
              dataCategories: const <String>[
                'account_identity',
                'creative_content',
              ],
            ),
          ]
          ..retentions = <Sprint116RetentionRule>[
            _retention(
              retentionId: 'ret_identity',
              dataCategory: 'account_identity',
            ),
          ],
      );
      expect(missing.state, Sprint116PrivacyGateStatus.fail);
      expect(
        missing.invalidRecords,
        contains('retention_coverage:creative_content'),
      );
      expect(missing.unretainedCategories, contains('creative_content'));
    });

    test('erasure requested without identity verification fails', () {
      // Unverified erasure destroys someone else's data just as surely as a
      // verified one preserves the user's own.
      final report = _certifyAll(
        controls: _healthyControls()
          ..deletions = <Sprint116DeletionRequest>[
            _deletion(requestId: 'del_0001', identityVerified: false),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('deletion:del_0001'));
    });

    test('an erasure completed before it was requested fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..deletions = <Sprint116DeletionRequest>[
            _deletion(
              requestId: 'del_0001',
              requestedAtEpochMs: 1700000050000,
              completedAtEpochMs: 1700000000000,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('deletion:del_0001'));
    });

    test('an erasure declared complete while still connected fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..deletions = <Sprint116DeletionRequest>[
            _deletion(requestId: 'del_0001', stillConnected: true),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('deletion:del_0001'));
    });

    test('an uncascaded erasure with no declared residual fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..deletions = <Sprint116DeletionRequest>[
            _deletion(
              requestId: 'del_0001',
              cascadedToBackups: false,
              residualCopiesDeclared: const <String>[],
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('deletion:del_0001'));
    });

    test('an erasure request overdue its own service window fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..deletions = <Sprint116DeletionRequest>[
            _deletion(
              requestId: 'del_0001',
              completed: false,
              completedAtEpochMs: 0,
              requestedAtEpochMs: 1690000000000,
              slaDays: 30,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('deletion:del_0001'));
    });

    test('a disconnect that leaves the token or vault behind fails', () {
      final noRevoke = _certifyAll(
        controls: _healthyControls()
          ..disconnects = <Sprint116AccountDisconnect>[
            _disconnect(disconnectId: 'dcn_google', tokenRevoked: false),
          ],
      );
      expect(noRevoke.invalidRecords, contains('disconnect:dcn_google'));

      final vaultKept = _certifyAll(
        controls: _healthyControls()
          ..disconnects = <Sprint116AccountDisconnect>[
            _disconnect(disconnectId: 'dcn_google', vaultEntryRemoved: false),
          ],
      );
      expect(vaultKept.invalidRecords, contains('disconnect:dcn_google'));

      final cacheKept = _certifyAll(
        controls: _healthyControls()
          ..disconnects = <Sprint116AccountDisconnect>[
            _disconnect(disconnectId: 'dcn_google', cacheCleared: false),
          ],
      );
      expect(cacheKept.invalidRecords, contains('disconnect:dcn_google'));
    });

    test('a disconnect that deletes the user own work fails', () {
      // Over-deletion is still data loss: the novel is the user's, not the
      // provider's, and unlinking a cloud account must not take it with it.
      final report = _certifyAll(
        controls: _healthyControls()
          ..disconnects = <Sprint116AccountDisconnect>[
            _disconnect(
              disconnectId: 'dcn_google',
              localProjectDataDeleted: true,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('disconnect:dcn_google'));
    });

    test('a cache still readable after disconnect fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..disconnects = <Sprint116AccountDisconnect>[
            _disconnect(
              disconnectId: 'dcn_google',
              cacheReadableAfterDisconnect: true,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('disconnect:dcn_google'));
    });

    test('a disconnect discarding its own minimal audit proof fails', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..disconnects = <Sprint116AccountDisconnect>[
            _disconnect(
              disconnectId: 'dcn_google',
              auditRetainedMinimal: false,
            ),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('disconnect:dcn_google'));
    });

    test('terms overdue for review cannot certify', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(
              providerId: 'provider_google',
              nextReviewAtEpochMs: 1699000000000,
            ),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('terms_limits:provider_google'));
    });

    test('terms that permit resale or provider training cannot certify', () {
      final resale = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(providerId: 'provider_google', resaleProhibited: false),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(resale.invalidRecords, contains('terms_limits:provider_google'));

      final training = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(
              providerId: 'provider_google',
              aiTrainingOptOutHonored: false,
            ),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(training.invalidRecords, contains('terms_limits:provider_google'));
    });

    test('a sandbox available but unused fails the terms gate', () {
      // The canonical contract requires the test account when one exists.
      final report = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(providerId: 'provider_google', sandboxAccountUsed: false),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('terms_limits:provider_google'));
    });

    test('terms with no api use, region limits, or version cannot certify', () {
      final noApi = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(providerId: 'provider_google', apiUsePermitted: false),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(noApi.invalidRecords, contains('terms_limits:provider_google'));

      final noRegion = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(providerId: 'provider_google', regionLimitsDeclared: false),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(noRegion.invalidRecords, contains('terms_limits:provider_google'));

      final noVersion = _certifyAll(
        controls: _healthyControls()
          ..termsReviews = <Sprint116ProviderTerms>[
            _terms(providerId: 'provider_google', termsVersion: '  '),
            _terms(providerId: 'provider_stripe'),
          ],
      );
      expect(
        noVersion.invalidRecords,
        contains('terms_limits:provider_google'),
      );
    });

    test('live claims need evidence and unknown sources never pass', () {
      final noEvidence = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', source: 'live'),
          ],
      );
      expect(
        noEvidence.invalidRecords,
        contains('no_mock_values:flow_google'),
        reason: 'a live source without an evidence reference is a bare claim',
      );

      final unknown = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', source: 'best_effort'),
          ],
      );
      expect(unknown.invalidRecords, contains('no_mock_values:flow_google'));

      final attested = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(
              flowId: 'flow_google',
              source: 'live',
              evidenceRef: 'docs/evidence/sprint-116-46-live-flow.json',
            ),
          ],
      );
      expect(
        attested.invalidRecords,
        isNot(contains('no_mock_values:flow_google')),
      );
    });

    test('an unidentifiable record is rejected on identity alone', () {
      final report = _certifyAll(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[_flow(flowId: '   ')],
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('record_id:data_flow:0'));
    });

    test('requireCoverage fails an area with no positive evidence', () {
      final report = Sprint116PrivacyCertificationGate().certify(
        controls: _healthyControls()
          ..termsReviews = const <Sprint116ProviderTerms>[],
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      // An absent group is a blocked gate, never a silent pass.
      expect(report.state, Sprint116PrivacyGateStatus.blocked);
      expect(report.invalidRecords, contains('terms_limits'));
    });

    test('an explicit control set never borrows manifest fixtures', () {
      final report = Sprint116PrivacyCertificationGate().certify(
        controls: _healthyControls()
          ..dataFlows = <Sprint116DataFlow>[
            _flow(flowId: 'flow_google', purpose: '   '),
          ],
        asOfEpochMs: _now,
        requireCoverage: true,
      );
      expect(report.state, Sprint116PrivacyGateStatus.fail);
      expect(report.invalidRecords, contains('data_flow:flow_google'));
    });

    test('the shipped manifest certifies on its own and carries no secret', () {
      final file = File(Sprint116PrivacyContract.manifestPath);
      expect(file.existsSync(), isTrue, reason: 'manifest must ship');

      final report = Sprint116PrivacyCertificationGate().certify(
        requireCoverage: true,
      );
      expect(
        report.state,
        Sprint116PrivacyGateStatus.pass,
        reason:
            'shipped manifest must be self-consistent: ${report.invalidRecords}',
      );
      expect(report.invalidRecords, isEmpty);

      final raw = file.readAsStringSync().toLowerCase();
      for (final forbidden in <String>[
        'sk-',
        'ghp_',
        '-----begin',
        'client_secret":',
        'access_token":',
        'refresh_token":',
        'password":',
        'bearer ',
      ]) {
        expect(
          raw.contains(forbidden.toLowerCase()),
          isFalse,
          reason: 'manifest must not contain $forbidden',
        );
      }
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded['live_privacy_verification'], isFalse);
      expect(decoded['limitations'], isA<String>());
      expect((decoded['limitations'] as String).trim(), isNotEmpty);
    });
  });
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

Sprint116PrivacyReport _certifyAll({
  required Sprint116PrivacyControlSet controls,
  bool requireCoverage = false,
}) {
  return Sprint116PrivacyCertificationGate().certify(
    controls: controls,
    asOfEpochMs: _now,
    requireCoverage: requireCoverage,
  );
}

Sprint116PrivacyControlSet _healthyControls() {
  return Sprint116PrivacyControlSet(
    dataFlows: <Sprint116DataFlow>[
      _flow(flowId: 'flow_google'),
      _flow(
        flowId: 'flow_telemetry',
        providerId: 'provider_local',
        dataCategories: const <String>['usage_telemetry'],
        purpose: 'improve_product',
        personalData: false,
        leavesDevice: false,
      ),
      _flow(
        flowId: 'flow_stripe',
        providerId: 'provider_stripe',
        dataCategories: const <String>['billing'],
        purpose: 'process_payment',
      ),
    ],
    consents: <Sprint116ConsentRecord>[
      _consent(consentId: 'cns_google', purpose: 'authenticate_user'),
      _consent(consentId: 'cns_telemetry', purpose: 'improve_product'),
      _consent(consentId: 'cns_stripe', purpose: 'process_payment'),
    ],
    datasets: <Sprint116MinimizationRecord>[
      _dataset(datasetId: 'ds_account'),
      _dataset(
        datasetId: 'ds_telemetry',
        collectedFields: const <String>['session_count', 'feature_flags'],
        purposeRequiredFields: const <String>['session_count', 'feature_flags'],
        retainedFields: const <String>['session_count'],
      ),
    ],
    destinations: <Sprint116Destination>[
      _destination(destinationId: 'dst_google'),
      _destination(
        destinationId: 'dst_stripe',
        providerId: 'provider_stripe',
        dataCategories: const <String>['billing'],
      ),
    ],
    retentions: <Sprint116RetentionRule>[
      _retention(retentionId: 'ret_identity', dataCategory: 'account_identity'),
      _retention(retentionId: 'ret_contact', dataCategory: 'contact'),
      _retention(retentionId: 'ret_telemetry', dataCategory: 'usage_telemetry'),
      _retention(retentionId: 'ret_billing', dataCategory: 'billing'),
    ],
    deletions: <Sprint116DeletionRequest>[
      _deletion(requestId: 'del_0001'),
      _deletion(
        requestId: 'del_0002',
        subjectId: 'user_0002',
        requestedAtEpochMs: 1699990000000,
        completedAtEpochMs: 1699995000000,
      ),
    ],
    disconnects: <Sprint116AccountDisconnect>[
      _disconnect(disconnectId: 'dcn_google'),
      _disconnect(disconnectId: 'dcn_stripe', providerId: 'provider_stripe'),
    ],
    termsReviews: <Sprint116ProviderTerms>[
      _terms(providerId: 'provider_google'),
      _terms(providerId: 'provider_stripe'),
    ],
  );
}

Sprint116DataFlow _flow({
  required String flowId,
  String providerId = 'provider_google',
  List<String> dataCategories = const <String>['account_identity', 'contact'],
  String purpose = 'authenticate_user',
  bool personalData = true,
  bool leavesDevice = true,
  bool encryptedInTransit = true,
  bool fieldsRedactedInLogs = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116DataFlow(
    flowId: flowId,
    providerId: providerId,
    subjectScope: 'user',
    dataCategories: dataCategories,
    purpose: purpose,
    personalData: personalData,
    leavesDevice: leavesDevice,
    encryptedInTransit: encryptedInTransit,
    fieldsRedactedInLogs: fieldsRedactedInLogs,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116ConsentRecord _consent({
  required String consentId,
  String subjectId = 'user_0001',
  String purpose = 'authenticate_user',
  bool granted = true,
  bool bundledOrPreTicked = false,
  bool revocable = true,
  String policyVersion = 'policy-2026-09-01',
  int grantedAtEpochMs = 1699990000000,
  int withdrawnAtEpochMs = 0,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116ConsentRecord(
    consentId: consentId,
    subjectId: subjectId,
    purpose: purpose,
    granted: granted,
    bundledOrPreTicked: bundledOrPreTicked,
    revocable: revocable,
    policyVersion: policyVersion,
    grantedAtEpochMs: grantedAtEpochMs,
    withdrawnAtEpochMs: withdrawnAtEpochMs,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116MinimizationRecord _dataset({
  required String datasetId,
  String featurePurpose = 'account_settings',
  List<String> collectedFields = const <String>['email', 'display_name'],
  List<String> purposeRequiredFields = const <String>['email', 'display_name'],
  List<String> retainedFields = const <String>['email'],
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116MinimizationRecord(
    datasetId: datasetId,
    featurePurpose: featurePurpose,
    collectedFields: collectedFields,
    purposeRequiredFields: purposeRequiredFields,
    retainedFields: retainedFields,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116Destination _destination({
  required String destinationId,
  String providerId = 'provider_google',
  String host = 'oauth2.googleapis.com',
  String scheme = 'https',
  String region = 'us',
  List<String> dataCategories = const <String>['account_identity', 'contact'],
  bool subprocessorListed = true,
  bool crossBorderTransfer = true,
  String transferMechanism = 'adequacy_decision',
  bool personalDataShared = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116Destination(
    destinationId: destinationId,
    providerId: providerId,
    host: host,
    scheme: scheme,
    region: region,
    dataCategories: dataCategories,
    subprocessorListed: subprocessorListed,
    crossBorderTransfer: crossBorderTransfer,
    transferMechanism: transferMechanism,
    personalDataShared: personalDataShared,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116RetentionRule _retention({
  required String retentionId,
  String dataCategory = 'billing',
  int retentionDays = 365,
  int windowStartedAtEpochMs = 1699000000000,
  bool autoDeleteEnabled = true,
  String deletionTrigger = 'retention_window_elapsed',
  bool legalHold = false,
  String legalHoldJustification = '',
  bool recordPresent = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116RetentionRule(
    retentionId: retentionId,
    dataCategory: dataCategory,
    retentionDays: retentionDays,
    windowStartedAtEpochMs: windowStartedAtEpochMs,
    autoDeleteEnabled: autoDeleteEnabled,
    deletionTrigger: deletionTrigger,
    legalHold: legalHold,
    legalHoldJustification: legalHoldJustification,
    recordPresent: recordPresent,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116DeletionRequest _deletion({
  required String requestId,
  String subjectId = 'user_0001',
  List<String> scope = const <String>['account_profile', 'billing_history'],
  int requestedAtEpochMs = 1699999000000,
  int completedAtEpochMs = 1700000050000,
  bool completed = true,
  int slaDays = 30,
  bool identityVerified = true,
  bool cascadedToBackups = true,
  List<String> residualCopiesDeclared = const <String>[],
  bool stillConnected = false,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116DeletionRequest(
    requestId: requestId,
    subjectId: subjectId,
    scope: scope,
    requestedAtEpochMs: requestedAtEpochMs,
    completedAtEpochMs: completedAtEpochMs,
    completed: completed,
    slaDays: slaDays,
    identityVerified: identityVerified,
    cascadedToBackups: cascadedToBackups,
    residualCopiesDeclared: residualCopiesDeclared,
    stillConnected: stillConnected,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116AccountDisconnect _disconnect({
  required String disconnectId,
  String providerId = 'provider_google',
  String subjectId = 'user_0001',
  bool tokenRevoked = true,
  bool cacheCleared = true,
  bool vaultEntryRemoved = true,
  bool localProjectDataDeleted = false,
  bool cacheReadableAfterDisconnect = false,
  bool auditRetainedMinimal = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116AccountDisconnect(
    disconnectId: disconnectId,
    providerId: providerId,
    subjectId: subjectId,
    tokenRevoked: tokenRevoked,
    cacheCleared: cacheCleared,
    vaultEntryRemoved: vaultEntryRemoved,
    localProjectDataDeleted: localProjectDataDeleted,
    cacheReadableAfterDisconnect: cacheReadableAfterDisconnect,
    auditRetainedMinimal: auditRetainedMinimal,
    source: source,
    evidenceRef: evidenceRef,
  );
}

Sprint116ProviderTerms _terms({
  required String providerId,
  String termsVersion = 'terms-2026-07-15',
  int reviewedAtEpochMs = 1699900000000,
  int nextReviewAtEpochMs = 1705000000000,
  bool apiUsePermitted = true,
  bool aiTrainingOptOutHonored = true,
  bool resaleProhibited = true,
  bool sandboxAccountAvailable = true,
  bool sandboxAccountUsed = true,
  bool regionLimitsDeclared = true,
  String source = 'synthetic_local',
  String? evidenceRef,
}) {
  return Sprint116ProviderTerms(
    providerId: providerId,
    termsVersion: termsVersion,
    reviewedAtEpochMs: reviewedAtEpochMs,
    nextReviewAtEpochMs: nextReviewAtEpochMs,
    apiUsePermitted: apiUsePermitted,
    aiTrainingOptOutHonored: aiTrainingOptOutHonored,
    resaleProhibited: resaleProhibited,
    sandboxAccountAvailable: sandboxAccountAvailable,
    sandboxAccountUsed: sandboxAccountUsed,
    regionLimitsDeclared: regionLimitsDeclared,
    source: source,
    evidenceRef: evidenceRef,
  );
}
