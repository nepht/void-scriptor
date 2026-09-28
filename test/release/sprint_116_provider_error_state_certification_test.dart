import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_provider_error_state_certification.dart';

void main() {
  group('116.42 Provider Error-State Certification', () {
    test('locks the eight provider error-state acceptance areas', () {
      expect(Sprint116ErrorStateContract.requiredStates, <String>[
        'invalid_credentials',
        'expired',
        'revoked',
        'scope_denied',
        'rate_limited',
        'outage',
        'unsupported_region',
        'unsupported_plan',
      ]);
      expect(Sprint116ErrorStateContract.canonicalStep, '116.42');
      expect(Sprint116ErrorStateContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('retry semantics are enforced per error state', () {
      Sprint116ErrorObservation observation(
        String id,
        String errorState, {
        required bool retryable,
        int? httpStatus,
        int? retryAfterSeconds,
      }) => Sprint116ErrorObservation(
        observationId: id,
        providerId: 'provider_a',
        errorState: errorState,
        retryable: retryable,
        httpStatus: httpStatus,
        retryAfterSeconds: retryAfterSeconds,
        userMessage: 'Provider reported $errorState.',
        observedAtEpochMs: 1700000000000,
        source: 'synthetic_local',
      );

      // A rate limit is only honest when it says retryable and when it says
      // how long to wait; an outage may leave the delay unknown.
      final rateLimited = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          observation(
            'rl_ok',
            'rate_limited',
            retryable: true,
            httpStatus: 429,
            retryAfterSeconds: 30,
          ),
          observation('outage_ok', 'outage', retryable: true, httpStatus: 503),
        ],
      );
      expect(rateLimited.state, Sprint116ErrorStateStatus.pass);
      expect(rateLimited.retryableIds, <String>['rl_ok', 'outage_ok']);

      final rlNotRetryable = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          observation('rl_bad', 'rate_limited', retryable: false),
        ],
      );
      expect(rlNotRetryable.state, Sprint116ErrorStateStatus.fail);
      expect(rlNotRetryable.invalidRecords, contains('retry_semantics:rl_bad'));

      final rlNoDelay = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          observation('rl_nodelay', 'rate_limited', retryable: true),
        ],
      );
      expect(rlNoDelay.state, Sprint116ErrorStateStatus.fail);
      expect(rlNoDelay.invalidRecords, contains('retry_after:rl_nodelay'));

      final rlBadDelay = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          observation(
            'rl_zerodelay',
            'rate_limited',
            retryable: true,
            retryAfterSeconds: 0,
          ),
        ],
      );
      expect(rlBadDelay.state, Sprint116ErrorStateStatus.fail);
      expect(rlBadDelay.invalidRecords, contains('retry_after:rl_zerodelay'));

      // Permanent states must never advertise a retry that cannot succeed.
      for (final permanent in <String>[
        'invalid_credentials',
        'expired',
        'revoked',
        'scope_denied',
        'unsupported_region',
        'unsupported_plan',
      ]) {
        final retried = Sprint116ErrorStateCertification().certify(
          observations: <Sprint116ErrorObservation>[
            observation('perm_1', permanent, retryable: true),
          ],
        );
        expect(retried.state, Sprint116ErrorStateStatus.fail);
        expect(
          retried.invalidRecords,
          contains('retry_semantics:perm_1'),
          reason: permanent,
        );

        final notRetried = Sprint116ErrorStateCertification().certify(
          observations: <Sprint116ErrorObservation>[
            observation('perm_2', permanent, retryable: false),
          ],
        );
        expect(notRetried.state, Sprint116ErrorStateStatus.pass);
      }
    });

    test('malformed observations fail closed and empty sets block', () {
      final blocked = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[],
      );
      expect(blocked.state, Sprint116ErrorStateStatus.blocked);
      expect(blocked.invalidRecords, <String>['observations']);

      Sprint116ErrorObservation base({
        String id = 'obs_1',
        String providerId = 'provider_a',
        String errorState = 'outage',
        bool retryable = true,
        int? httpStatus = 503,
        int observedAtEpochMs = 1700000000000,
        String userMessage = 'Service unavailable.',
      }) => Sprint116ErrorObservation(
        observationId: id,
        providerId: providerId,
        errorState: errorState,
        retryable: retryable,
        httpStatus: httpStatus,
        userMessage: userMessage,
        observedAtEpochMs: observedAtEpochMs,
        source: 'synthetic_local',
      );

      final malformed = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          base(id: '  '),
          base(id: 'no_provider', providerId: ' '),
          base(id: 'bad_state', errorState: 'quota_exceeded'),
          base(id: 'ok_status', httpStatus: 200),
          base(id: 'no_clock', observedAtEpochMs: 0),
        ],
      );
      expect(malformed.state, Sprint116ErrorStateStatus.fail);
      expect(malformed.invalidRecords, contains('observation_id:0'));
      expect(malformed.invalidRecords, contains('provider_id:no_provider'));
      expect(malformed.invalidRecords, contains('error_state:bad_state'));
      expect(malformed.invalidRecords, contains('http_status:ok_status'));
      expect(malformed.invalidRecords, contains('observed_at:no_clock'));
    });

    test('user messages are required and never leak credential material', () {
      Sprint116ErrorObservation message(String id, String text) =>
          Sprint116ErrorObservation(
            observationId: id,
            providerId: 'provider_a',
            errorState: 'invalid_credentials',
            retryable: false,
            httpStatus: 401,
            userMessage: text,
            observedAtEpochMs: 1700000000000,
            source: 'synthetic_local',
          );

      final clean = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          message('msg_ok', 'Sign in again to continue.'),
        ],
      );
      expect(clean.state, Sprint116ErrorStateStatus.pass);

      final leaking = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          message('msg_empty', '   '),
          message('msg_leak', '401 for Authorization: Bearer sk-live-123'),
        ],
      );
      expect(leaking.state, Sprint116ErrorStateStatus.fail);
      expect(leaking.invalidRecords, contains('user_message:msg_empty'));
      expect(leaking.invalidRecords, contains('redaction:msg_leak'));
    });

    test('coverage can be required and unknown sources fail closed', () {
      Sprint116ErrorObservation observation(
        String id,
        String errorState, {
        String source = 'synthetic_local',
        String? evidenceRef,
      }) => Sprint116ErrorObservation(
        observationId: id,
        providerId: 'provider_a',
        errorState: errorState,
        retryable: errorState == 'rate_limited' || errorState == 'outage',
        httpStatus: errorState == 'rate_limited' ? 429 : 503,
        retryAfterSeconds: errorState == 'rate_limited' ? 10 : null,
        userMessage: 'Provider reported $errorState.',
        observedAtEpochMs: 1700000000000,
        source: source,
        evidenceRef: evidenceRef,
      );

      final partial = <Sprint116ErrorObservation>[
        observation('cov_1', 'outage'),
        observation('cov_2', 'rate_limited'),
      ];

      final withoutCoverage = Sprint116ErrorStateCertification().certify(
        observations: partial,
      );
      expect(withoutCoverage.state, Sprint116ErrorStateStatus.pass);
      expect(withoutCoverage.coveredStates, <String>['outage', 'rate_limited']);

      final withCoverage = Sprint116ErrorStateCertification().certify(
        observations: partial,
        requireCoverage: true,
      );
      expect(withCoverage.state, Sprint116ErrorStateStatus.fail);
      expect(
        withCoverage.invalidRecords,
        contains('state_coverage:invalid_credentials'),
      );
      expect(withCoverage.invalidRecords, contains('state_coverage:expired'));
      expect(withCoverage.invalidRecords, contains('state_coverage:revoked'));
      expect(
        withCoverage.invalidRecords,
        isNot(contains('state_coverage:outage')),
      );

      final liveOk = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          observation(
            'live_1',
            'outage',
            source: 'live',
            evidenceRef: 'trace://errors/1',
          ),
        ],
      );
      expect(liveOk.state, Sprint116ErrorStateStatus.pass);

      final liveBare = Sprint116ErrorStateCertification().certify(
        observations: <Sprint116ErrorObservation>[
          observation('live_2', 'outage', source: 'live'),
          observation('mock_1', 'outage', source: 'recorded'),
        ],
      );
      expect(liveBare.state, Sprint116ErrorStateStatus.fail);
      expect(liveBare.invalidRecords, contains('no_mock_values:live_2'));
      expect(liveBare.invalidRecords, contains('no_mock_values:mock_1'));
    });

    test(
      'manifest fixture certifies locally without live claims or secrets',
      () {
        final report = Sprint116ErrorStateCertification().certify();
        expect(report.state, Sprint116ErrorStateStatus.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
        expect(report.coveredStates, hasLength(8));
        expect(
          report.coveredStates.toSet(),
          Sprint116ErrorStateContract.requiredStates.toSet(),
        );
        expect(report.retryableIds.toSet(), <String>{
          'obs_rate_limited',
          'obs_outage',
        });

        final manifest =
            jsonDecode(
                  File(
                    Sprint116ErrorStateContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.42');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['live_provider_verification'], false);
        expect(manifest['required_states'], <String>[
          'invalid_credentials',
          'expired',
          'revoked',
          'scope_denied',
          'rate_limited',
          'outage',
          'unsupported_region',
          'unsupported_plan',
        ]);
        final rules = manifest['error_state_rules'] as Map<String, dynamic>;
        expect(
          rules.keys.toSet(),
          Sprint116ErrorStateContract.requiredStates.toSet(),
        );
        expect(rules['rate_limited'], contains('retry_after'));
        expect(rules['invalid_credentials'], contains('not retryable'));

        final observations = manifest['observations'] as List<dynamic>;
        expect(observations, hasLength(8));
        final states = <String>{};
        for (final observation in observations) {
          final map = observation as Map<String, dynamic>;
          states.add(map['error_state'].toString());
          expect(map['source'], 'synthetic_local');
          expect(map['user_message'], isNotEmpty);
          expect(map['observed_at_epoch_ms'], isA<num>());
          expect(
            (map['retryable'] as bool) ==
                (map['error_state'] == 'rate_limited' ||
                    map['error_state'] == 'outage'),
            isTrue,
          );
        }
        expect(states, Sprint116ErrorStateContract.requiredStates.toSet());
        expect(
          manifest.keys
              .where(
                (key) =>
                    key.toLowerCase().contains('secret') ||
                    key.toLowerCase().contains('api_key') ||
                    key.toLowerCase().contains('password') ||
                    key.toLowerCase().contains('webhook_url'),
              )
              .toList(),
          isEmpty,
        );
      },
    );
  });
}
