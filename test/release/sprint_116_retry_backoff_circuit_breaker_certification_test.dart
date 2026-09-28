import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_retry_backoff_circuit_breaker_certification.dart';

void main() {
  group('116.43 Retry, Backoff & Circuit Breaker Certification', () {
    test('locks the seven retry, backoff and breaker acceptance areas', () {
      expect(Sprint116ResilienceContract.requiredAreas, <String>[
        'idempotency',
        'bounded_retry',
        'exponential_backoff',
        'jitter',
        'retry_after',
        'cancellation',
        'circuit_breaker',
      ]);
      expect(Sprint116ResilienceContract.canonicalStep, '116.43');
      expect(Sprint116ResilienceContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(Sprint116ResilienceContract.delaySources, <String>[
        'none',
        'exponential_backoff',
        'retry_after',
      ]);
      expect(Sprint116ResilienceContract.breakerStates, <String>[
        'closed',
        'open',
        'half_open',
      ]);
    });

    test('exponential backoff doubles per attempt and honours the cap', () {
      int delay(int attemptIndex) =>
          Sprint116ResilienceContract.theoreticalDelayMs(
            baseDelayMs: 100,
            maxDelayMs: 1000,
            attemptIndex: attemptIndex,
          );

      expect(delay(0), 0);
      expect(delay(1), 100);
      expect(delay(2), 200);
      expect(delay(3), 400);
      expect(delay(4), 800);
      // 1600 is clamped to the configured ceiling instead of growing forever.
      expect(delay(5), 1000);
      expect(delay(6), 1000);
    });

    test('retries are bounded and non-idempotent writes need a key', () {
      Sprint116RetryPolicy healthy() => Sprint116RetryPolicy(
        policyId: 'pol_a',
        providerId: 'provider_a',
        operationId: 'commit_revision',
        idempotent: false,
        idempotencyKey: 'idem-abc-123',
        maxAttempts: 4,
        baseDelayMs: 100,
        maxDelayMs: 1000,
        jitterRatio: 0.2,
        cancellationSupported: true,
        attempts: <Sprint116RetryAttempt>[
          _attempt(0),
          _attempt(1, theoretical: 100, actual: 110),
          _attempt(2, theoretical: 200, actual: 190),
        ],
        breaker: _breaker('closed'),
        source: 'synthetic_local',
      );

      final ok = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[healthy()],
      );
      expect(ok.state, Sprint116ResilienceStatus.pass);
      expect(ok.invalidRecords, isEmpty);

      // A retried write without an idempotency key can double-apply a side
      // effect, so it must fail closed even though its backoff is correct.
      final noKey = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          Sprint116RetryPolicy(
            policyId: 'pol_b',
            providerId: 'provider_a',
            operationId: 'commit_revision',
            idempotent: false,
            maxAttempts: 4,
            baseDelayMs: 100,
            maxDelayMs: 1000,
            jitterRatio: 0.2,
            cancellationSupported: true,
            attempts: healthy().attempts,
            breaker: _breaker('closed'),
            source: 'synthetic_local',
          ),
        ],
      );
      expect(noKey.state, Sprint116ResilienceStatus.fail);
      expect(noKey.invalidRecords, contains('idempotency:pol_b'));

      // A non-idempotent operation that declares itself idempotent without a
      // stable key is still unprovable.
      final keylessAttempt = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          Sprint116RetryPolicy(
            policyId: 'pol_c',
            providerId: 'provider_a',
            operationId: 'commit_revision',
            idempotent: true,
            maxAttempts: 3,
            baseDelayMs: 100,
            maxDelayMs: 1000,
            jitterRatio: 0.2,
            cancellationSupported: true,
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              const Sprint116RetryAttempt(
                attemptIndex: 1,
                errorState: 'outage',
                theoreticalDelayMs: 100,
                actualDelayMs: 110,
                delaySource: 'exponential_backoff',
                idempotencyKey: '',
              ),
            ],
            breaker: _breaker('closed'),
            source: 'synthetic_local',
          ),
        ],
      );
      expect(keylessAttempt.state, Sprint116ResilienceStatus.fail);
      expect(keylessAttempt.invalidRecords, contains('idempotency:pol_c'));

      final unbounded = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            policyId: 'pol_no_ceiling',
            maxAttempts: 0,
            attempts: healthy().attempts,
          ),
          _policy(
            policyId: 'pol_endless',
            maxAttempts: 9999,
            attempts: healthy().attempts,
          ),
        ],
      );
      expect(unbounded.state, Sprint116ResilienceStatus.fail);
      expect(
        unbounded.invalidRecords,
        contains('bounded_retry:pol_no_ceiling'),
      );
      expect(unbounded.invalidRecords, contains('bounded_retry:pol_endless'));

      final overrun = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            policyId: 'pol_overrun',
            maxAttempts: 2,
            attempts: healthy().attempts,
          ),
        ],
      );
      expect(overrun.state, Sprint116ResilienceStatus.fail);
      expect(overrun.invalidRecords, contains('bounded_retry:pol_overrun'));
    });

    test(
      'jitter must actually perturb the delay and stay inside the ratio',
      () {
        final jittered = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              attempts: <Sprint116RetryAttempt>[
                _attempt(0),
                _attempt(1, theoretical: 100, actual: 115),
                _attempt(2, theoretical: 200, actual: 170),
              ],
            ),
          ],
        );
        expect(jittered.state, Sprint116ResilienceStatus.pass);

        // A fixed delay on every attempt is a thundering herd, not jitter.
        final noJitter = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              attempts: <Sprint116RetryAttempt>[
                _attempt(0),
                _attempt(1, theoretical: 100, actual: 100),
                _attempt(2, theoretical: 200, actual: 200),
              ],
            ),
          ],
        );
        expect(noJitter.state, Sprint116ResilienceStatus.fail);
        expect(noJitter.invalidRecords, contains('jitter:pol_ok'));

        // Jitter that escapes the declared ratio is unbounded spread.
        final wildJitter = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              attempts: <Sprint116RetryAttempt>[
                _attempt(0),
                _attempt(1, theoretical: 100, actual: 900),
              ],
            ),
          ],
        );
        expect(wildJitter.state, Sprint116ResilienceStatus.fail);
        expect(wildJitter.invalidRecords, contains('jitter:pol_ok'));
        expect(
          wildJitter.invalidRecords,
          contains('exponential_backoff:pol_ok'),
        );

        final noJitterRatio = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              jitterRatio: 0,
              attempts: <Sprint116RetryAttempt>[
                _attempt(0),
                _attempt(1, theoretical: 100, actual: 110),
              ],
            ),
          ],
        );
        expect(noJitterRatio.state, Sprint116ResilienceStatus.fail);
        expect(noJitterRatio.invalidRecords, contains('jitter:pol_ok'));
      },
    );

    test('provider retry_after overrides the computed backoff', () {
      final honoured = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              const Sprint116RetryAttempt(
                attemptIndex: 1,
                errorState: 'rate_limited',
                theoreticalDelayMs: 100,
                actualDelayMs: 30000,
                delaySource: 'retry_after',
                providerRetryAfterSeconds: 30,
                idempotencyKey: 'idem-abc-123',
              ),
            ],
          ),
        ],
      );
      expect(honoured.state, Sprint116ResilienceStatus.pass);

      // Backing off on our own schedule while the provider asked for 30s
      // would keep hammering a limit that is still in force.
      final ignored = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              const Sprint116RetryAttempt(
                attemptIndex: 1,
                errorState: 'rate_limited',
                theoreticalDelayMs: 100,
                actualDelayMs: 110,
                delaySource: 'exponential_backoff',
                providerRetryAfterSeconds: 30,
                idempotencyKey: 'idem-abc-123',
              ),
            ],
          ),
        ],
      );
      expect(ignored.state, Sprint116ResilienceStatus.fail);
      expect(ignored.invalidRecords, contains('retry_after:pol_ok'));

      final missing = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              const Sprint116RetryAttempt(
                attemptIndex: 1,
                errorState: 'rate_limited',
                theoreticalDelayMs: 100,
                actualDelayMs: 110,
                delaySource: 'exponential_backoff',
                idempotencyKey: 'idem-abc-123',
              ),
            ],
          ),
        ],
      );
      expect(missing.state, Sprint116ResilienceStatus.fail);
      expect(missing.invalidRecords, contains('retry_after:pol_ok'));
    });

    test('cancellation stops the retry loop and is mandatory', () {
      final cancelled = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            cancelledAtAttemptIndex: 1,
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              _attempt(
                1,
                theoretical: 100,
                actual: 110,
                source: 'none',
                delay: 0,
              ),
            ],
          ),
        ],
      );
      expect(cancelled.state, Sprint116ResilienceStatus.pass);
      expect(cancelled.coveredAreas, contains('cancellation'));

      // Retries recorded after the cancellation point mean the loop ignored
      // the user and kept spending provider quota.
      final resurrected = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[
          _policy(
            cancelledAtAttemptIndex: 1,
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              _attempt(
                1,
                theoretical: 100,
                actual: 110,
                source: 'none',
                delay: 0,
              ),
              _attempt(2, theoretical: 200, actual: 190),
            ],
          ),
        ],
      );
      expect(resurrected.state, Sprint116ResilienceStatus.fail);
      expect(resurrected.invalidRecords, contains('cancellation:pol_ok'));

      final unsupported = Sprint116ResilienceCertification().certify(
        policies: <Sprint116RetryPolicy>[_policy(cancellationSupported: false)],
      );
      expect(unsupported.state, Sprint116ResilienceStatus.fail);
      expect(unsupported.invalidRecords, contains('cancellation:pol_ok'));
    });

    test(
      'circuit breaker states are validated and an open circuit blocks work',
      () {
        final closed = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[_policy()],
        );
        expect(closed.state, Sprint116ResilienceStatus.pass);

        final open = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              attempts: <Sprint116RetryAttempt>[_attempt(0)],
              breaker: _breaker('open'),
            ),
          ],
        );
        expect(open.state, Sprint116ResilienceStatus.pass);

        // An open circuit that still records retries is not a breaker at all.
        final openButRetrying = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(policyId: 'brk_open_retrying', breaker: _breaker('open')),
          ],
        );
        expect(openButRetrying.state, Sprint116ResilienceStatus.fail);
        expect(
          openButRetrying.invalidRecords,
          contains('circuit_breaker:brk_open_retrying'),
        );

        final noBreaker = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(policyId: 'brk_missing', omitBreaker: true),
          ],
        );
        expect(noBreaker.state, Sprint116ResilienceStatus.fail);
        expect(
          noBreaker.invalidRecords,
          contains('circuit_breaker:brk_missing'),
        );

        final inconsistent = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              policyId: 'brk_stale_closed',
              attempts: <Sprint116RetryAttempt>[_attempt(0)],
              breaker: _breaker('closed', consecutiveFailures: 5, threshold: 3),
            ),
          ],
        );
        expect(inconsistent.state, Sprint116ResilienceStatus.fail);
        expect(
          inconsistent.invalidRecords,
          contains('circuit_breaker:brk_stale_closed'),
        );

        final unknownState = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              policyId: 'brk_unknown_state',
              attempts: <Sprint116RetryAttempt>[_attempt(0)],
              breaker: _breaker('halfopen'),
            ),
          ],
        );
        expect(unknownState.state, Sprint116ResilienceStatus.fail);
        expect(
          unknownState.invalidRecords,
          contains('circuit_breaker:brk_unknown_state'),
        );

        final noResetWindow = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(
              policyId: 'brk_no_window',
              attempts: <Sprint116RetryAttempt>[_attempt(0)],
              breaker: _breaker('closed', openDurationMs: 0),
            ),
          ],
        );
        expect(noResetWindow.state, Sprint116ResilienceStatus.fail);
        expect(
          noResetWindow.invalidRecords,
          contains('circuit_breaker:brk_no_window'),
        );
      },
    );

    test(
      'malformed policies fail closed, empty sets block, coverage required',
      () {
        final blocked = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[],
        );
        expect(blocked.state, Sprint116ResilienceStatus.blocked);
        expect(blocked.invalidRecords, <String>['policies']);

        final malformed = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(policyId: '  '),
            _policy(policyId: 'no_provider', providerId: ' '),
            _policy(policyId: 'no_operation', operationId: ''),
            _policy(policyId: 'bad_base', baseDelayMs: 0),
            _policy(policyId: 'cap_below_base', maxDelayMs: 50),
            _policy(policyId: 'mock_source', source: 'recorded'),
            _policy(policyId: 'live_bare', source: 'live'),
          ],
        );
        expect(malformed.state, Sprint116ResilienceStatus.fail);
        expect(malformed.invalidRecords, contains('policy_id:0'));
        expect(
          malformed.invalidRecords,
          contains('provider_aware:no_provider'),
        );
        expect(
          malformed.invalidRecords,
          contains('provider_aware:no_operation'),
        );
        expect(malformed.invalidRecords, contains('bounded_retry:bad_base'));
        expect(
          malformed.invalidRecords,
          contains('bounded_retry:cap_below_base'),
        );
        expect(
          malformed.invalidRecords,
          contains('no_mock_values:mock_source'),
        );
        expect(malformed.invalidRecords, contains('no_mock_values:live_bare'));
        // A record without an identity is rejected on identity alone, so it
        // must not also be scored against the remaining areas.
        expect(
          malformed.invalidRecords.where((r) => r.endsWith(':0')),
          isNot(contains('provider_aware:0')),
        );

        final liveOk = Sprint116ResilienceCertification().certify(
          policies: <Sprint116RetryPolicy>[
            _policy(source: 'live', evidenceRef: 'trace://retry/1'),
          ],
        );
        expect(liveOk.state, Sprint116ResilienceStatus.pass);

        // Coverage is about positive evidence per area, not about the record
        // merely existing.
        final partial = <Sprint116RetryPolicy>[
          _policy(
            policyId: 'cov_backoff',
            attempts: <Sprint116RetryAttempt>[
              _attempt(0),
              _attempt(1, theoretical: 100, actual: 110),
            ],
          ),
          _policy(
            policyId: 'cov_breaker',
            attempts: <Sprint116RetryAttempt>[_attempt(0)],
            breaker: _breaker('closed'),
          ),
        ];

        final withoutCoverage = Sprint116ResilienceCertification().certify(
          policies: partial,
        );
        expect(withoutCoverage.state, Sprint116ResilienceStatus.pass);

        final withCoverage = Sprint116ResilienceCertification().certify(
          policies: partial,
          requireCoverage: true,
        );
        expect(withCoverage.state, Sprint116ResilienceStatus.fail);
        expect(
          withCoverage.invalidRecords,
          contains('area_coverage:retry_after'),
        );
        expect(
          withCoverage.invalidRecords,
          contains('area_coverage:cancellation'),
        );
        expect(
          withCoverage.invalidRecords,
          isNot(contains('area_coverage:exponential_backoff')),
        );
        expect(
          withCoverage.invalidRecords,
          isNot(contains('area_coverage:circuit_breaker')),
        );
      },
    );

    test(
      'manifest fixture certifies locally without live claims or secrets',
      () {
        final report = Sprint116ResilienceCertification().certify(
          requireCoverage: true,
        );
        expect(report.state, Sprint116ResilienceStatus.pass);
        expect(report.invalidRecords, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
        expect(report.coveredAreas.toSet().length, 7);
        expect(
          report.coveredAreas.toSet(),
          Sprint116ResilienceContract.requiredAreas.toSet(),
        );

        final manifest =
            jsonDecode(
                  File(
                    Sprint116ResilienceContract.manifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(manifest['canonical_step'], '116.43');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['live_provider_verification'], false);
        expect(manifest['acceptance_areas'], <String>[
          'idempotency',
          'bounded_retry',
          'exponential_backoff',
          'jitter',
          'retry_after',
          'cancellation',
          'circuit_breaker',
        ]);
        expect(manifest['policies'], isA<List<dynamic>>());
        expect(manifest['policies'], isNotEmpty);

        for (final entry in manifest['policies'] as List<dynamic>) {
          final policy = entry as Map<String, dynamic>;
          expect(policy['source'], 'synthetic_local');
          expect(policy['provider_id'], isNotEmpty);
          expect(policy['operation_id'], isNotEmpty);
          expect(policy['max_attempts'], inInclusiveRange(1, 10));
          expect(policy['base_delay_ms'], greaterThan(0));
          expect(policy['max_delay_ms'], greaterThanOrEqualTo(1));
          expect(policy['jitter_ratio'], inInclusiveRange(0.01, 0.99));
          expect(policy['cancellation_supported'], isTrue);
          final breaker = policy['circuit_breaker'] as Map<String, dynamic>;
          expect(
            breaker['state'],
            isIn(<String>['closed', 'open', 'half_open']),
          );
          expect(breaker['failure_threshold'], greaterThan(0));
          expect(breaker['open_duration_ms'], greaterThan(0));
        }

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

Sprint116RetryAttempt _attempt(
  int attemptIndex, {
  int? theoretical,
  int? actual,
  String source = 'exponential_backoff',
  int? delay,
}) => Sprint116RetryAttempt(
  attemptIndex: attemptIndex,
  errorState: 'outage',
  theoreticalDelayMs: theoretical ?? 0,
  actualDelayMs: delay ?? actual ?? 0,
  delaySource: source,
  providerRetryAfterSeconds: null,
  idempotencyKey: 'idem-abc-123',
);

Sprint116CircuitRecord _breaker(
  String state, {
  int consecutiveFailures = 0,
  int threshold = 3,
  int openDurationMs = 30000,
}) => Sprint116CircuitRecord(
  breakerId: 'breaker_$state',
  state: state,
  consecutiveFailures: consecutiveFailures,
  failureThreshold: threshold,
  openDurationMs: openDurationMs,
  openedAtEpochMs: state == 'closed' ? 0 : 1700000000000,
);

Sprint116RetryPolicy _policy({
  String policyId = 'pol_ok',
  String providerId = 'provider_a',
  String operationId = 'commit_revision',
  int maxAttempts = 4,
  int baseDelayMs = 100,
  int maxDelayMs = 1000,
  double jitterRatio = 0.2,
  bool cancellationSupported = true,
  int? cancelledAtAttemptIndex,
  List<Sprint116RetryAttempt>? attempts,
  Sprint116CircuitRecord? breaker,
  bool omitBreaker = false,
  String source = 'synthetic_local',
  String? evidenceRef,
}) => Sprint116RetryPolicy(
  policyId: policyId,
  providerId: providerId,
  operationId: operationId,
  idempotent: false,
  idempotencyKey: 'idem-abc-123',
  maxAttempts: maxAttempts,
  baseDelayMs: baseDelayMs,
  maxDelayMs: maxDelayMs,
  jitterRatio: jitterRatio,
  cancellationSupported: cancellationSupported,
  cancelledAtAttemptIndex: cancelledAtAttemptIndex,
  attempts:
      attempts ??
      <Sprint116RetryAttempt>[
        _attempt(0),
        _attempt(1, theoretical: 100, actual: 110),
      ],
  breaker: omitBreaker ? null : (breaker ?? _breaker('closed')),
  source: source,
  evidenceRef: evidenceRef,
);
