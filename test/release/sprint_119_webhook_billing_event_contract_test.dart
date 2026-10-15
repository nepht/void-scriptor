import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_webhook_billing_event_contract.dart';

void main() {
  final now = DateTime.utc(2026, 3, 1, 12);
  final timestamp = DateTime.utc(2026, 3, 1, 11, 59, 30);
  const secret = 'test-webhook-key';
  const payload = '{"type":"invoice.paid","amount_minor_units":2500}';

  WebhookSignature signed({
    String key = secret,
    String body = payload,
    DateTime? at,
    WebhookSignatureAlgorithm algorithm = WebhookSignatureAlgorithm.hmacSha256,
    String keyId = 'whsec-primary',
  }) {
    final signature = WebhookSignature(
      algorithm: algorithm,
      keyId: keyId,
      timestampUtc: at ?? timestamp,
      value: '',
    );
    return WebhookSignature(
      algorithm: algorithm,
      keyId: keyId,
      timestampUtc: at ?? timestamp,
      value: WebhookBillingEventContract.computeSignature(
        key: key,
        signature: signature,
        payload: body,
      ),
    );
  }

  group('119.18 Webhook & Billing Event Contract', () {
    test('signature: hmac-sha256 matches the rfc 4231 test vector', () {
      expect(
        WebhookBillingEventContract.hmacSha256Hex(
          key: 'Jefe',
          data: 'what do ya want for nothing?',
        ),
        '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
      );
    });

    test('signature: a correctly signed payload verifies', () {
      expect(
        WebhookBillingEventContract.verifySignature(
          signature: signed(),
          payload: payload,
          key: secret,
          now: now,
        ),
        isEmpty,
      );
    });

    test(
      'signature: tampering, wrong key, stale timestamp, and bad shape are rejected',
      () {
        expect(
          WebhookBillingEventContract.verifySignature(
            signature: signed(),
            payload: '{"type":"invoice.paid","amount_minor_units":9999}',
            key: secret,
            now: now,
          ),
          contains('signature_mismatch'),
        );
        expect(
          WebhookBillingEventContract.verifySignature(
            signature: signed(),
            payload: payload,
            key: 'wrong-key',
            now: now,
          ),
          contains('signature_mismatch'),
        );
        expect(
          WebhookBillingEventContract.verifySignature(
            signature: signed(at: DateTime.utc(2026, 3, 1, 11, 30)),
            payload: payload,
            key: secret,
            now: now,
          ),
          contains('timestamp_outside_tolerance'),
        );
        expect(
          WebhookBillingEventContract.verifySignature(
            signature: WebhookSignature(
              algorithm: WebhookSignatureAlgorithm.unknown,
              keyId: 'whsec-primary',
              timestampUtc: timestamp,
              value: List<String>.filled(64, 'a').join(),
            ),
            payload: payload,
            key: secret,
            now: now,
          ),
          contains('algorithm_unsupported'),
        );
        expect(
          WebhookBillingEventContract.verifySignature(
            signature: WebhookSignature(
              algorithm: WebhookSignatureAlgorithm.hmacSha256,
              keyId: '',
              timestampUtc: timestamp,
              value: 'A1B2',
            ),
            payload: payload,
            key: secret,
            now: now,
          ),
          containsAll(<String>['key_id_missing', 'signature_shape_invalid']),
        );
      },
    );

    test('signature: the digest is never echoed in serialized form', () {
      final json = signed().toJson();
      expect(json['signature'], '[REDACTED]');
      expect(json['algorithm'], 'hmacSha256');
      expect(json['key_id'], 'whsec-primary');
      expect(json.toString(), isNot(contains(signed().value)));
    });

    test(
      'replay_protection: a repeated event id is refused and old entries expire',
      () {
        final guard = WebhookReplayGuard();
        expect(
          guard.register(eventId: 'evtref:psp:invoice-paid-01', atUtc: now),
          isTrue,
        );
        expect(
          guard.register(eventId: 'evtref:psp:invoice-paid-01', atUtc: now),
          isFalse,
        );
        expect(guard.hasSeen('evtref:psp:invoice-paid-01'), isTrue);
        expect(guard.trackedCount, 1);

        expect(
          guard.register(
            eventId: 'evtref:psp:invoice-paid-02',
            atUtc: now.add(const Duration(minutes: 1)),
          ),
          isTrue,
        );
        expect(guard.purgeExpired(now.add(const Duration(minutes: 10))), 2);
        expect(guard.trackedCount, 0);
        expect(
          guard.register(
            eventId: 'evtref:psp:invoice-paid-01',
            atUtc: now.add(const Duration(minutes: 10)),
          ),
          isTrue,
        );
      },
    );

    test(
      'idempotency: a repeated key is refused and its outcome is replayable',
      () {
        final ledger = IdempotencyLedger();
        expect(ledger.begin('idemref:psp:invoice-paid-01'), isTrue);
        expect(ledger.begin('idemref:psp:invoice-paid-01'), isFalse);
        expect(ledger.outcomeFor('idemref:psp:invoice-paid-01'), isNull);
        expect(ledger.hasPending, isTrue);

        ledger.complete('idemref:psp:invoice-paid-01', 'applied');
        expect(ledger.outcomeFor('idemref:psp:invoice-paid-01'), 'applied');
        expect(ledger.hasPending, isFalse);
        expect(ledger.begin('idemref:psp:invoice-paid-01'), isFalse);
      },
    );

    test('idempotency: keys must be opaque handles, not raw values', () {
      expect(
        WebhookBillingEventContract.isValidIdempotencyKey(
          'idemref:psp:invoice-paid-01',
        ),
        isTrue,
      );
      expect(
        WebhookBillingEventContract.isValidIdempotencyKey('invoice-paid-01'),
        isFalse,
      );
      expect(
        WebhookBillingEventContract.isValidIdempotencyKey('evtref:psp:other'),
        isFalse,
      );
    });

    test('ordering: sequences must increase strictly', () {
      WebhookEvent event(int sequence) => WebhookEvent(
        eventId: 'evtref:psp:invoice-paid-0$sequence',
        sequence: sequence,
        receivedAtUtc: now,
        type: 'invoice.paid',
      );

      expect(
        WebhookBillingEventContract.isOrdered(<WebhookEvent>[
          event(1),
          event(2),
          event(3),
        ]),
        isTrue,
      );
      expect(
        WebhookBillingEventContract.isOrdered(<WebhookEvent>[
          event(1),
          event(3),
          event(2),
        ]),
        isFalse,
      );
      expect(
        WebhookBillingEventContract.isOrdered(<WebhookEvent>[
          event(1),
          event(1),
        ]),
        isFalse,
      );
      expect(
        WebhookBillingEventContract.isOrdered(const <WebhookEvent>[]),
        isFalse,
      );

      expect(
        WebhookBillingEventContract.shouldAcceptSequence(
          incoming: 3,
          lastApplied: 2,
        ),
        isTrue,
      );
      expect(
        WebhookBillingEventContract.shouldAcceptSequence(
          incoming: 2,
          lastApplied: 2,
        ),
        isFalse,
      );
      expect(
        WebhookBillingEventContract.shouldAcceptSequence(
          incoming: 1,
          lastApplied: 2,
        ),
        isFalse,
      );
    });

    test(
      'retry: the schedule is deterministic, capped, and never retries a permanent error',
      () {
        expect(
          WebhookBillingEventContract.retryDelay(attempt: 1),
          const Duration(seconds: 2),
        );
        expect(
          WebhookBillingEventContract.retryDelay(attempt: 3),
          const Duration(seconds: 8),
        );
        expect(
          WebhookBillingEventContract.retryDelay(attempt: 30),
          WebhookBillingEventContract.retryCap,
        );
        expect(
          WebhookBillingEventContract.retryDelay(attempt: 0),
          const Duration(seconds: 2),
        );

        expect(
          WebhookBillingEventContract.shouldRetry(
            attempt: 4,
            retryable: true,
            maxAttempts: 5,
          ),
          isTrue,
        );
        expect(
          WebhookBillingEventContract.shouldRetry(
            attempt: 5,
            retryable: true,
            maxAttempts: 5,
          ),
          isFalse,
        );
        expect(
          WebhookBillingEventContract.shouldRetry(
            attempt: 1,
            retryable: false,
            maxAttempts: 5,
          ),
          isFalse,
        );
      },
    );

    test('reconciliation: differences are reported, never auto-merged', () {
      final report = WebhookBillingEventContract.reconcile(
        local: <WebhookEvent>[
          WebhookEvent(
            eventId: 'evtref:psp:invoice-paid-01',
            sequence: 1,
            receivedAtUtc: now,
            type: 'invoice.paid',
          ),
          WebhookEvent(
            eventId: 'evtref:psp:invoice-paid-02',
            sequence: 2,
            receivedAtUtc: now,
            type: 'invoice.paid',
          ),
        ],
        providerEventIds: const <String>{
          'evtref:psp:invoice-paid-02',
          'evtref:psp:invoice-paid-03',
        },
      );

      expect(report.missingLocally, <String>['evtref:psp:invoice-paid-03']);
      expect(report.unknownLocally, <String>['evtref:psp:invoice-paid-01']);
      expect(report.isConsistent, isFalse);

      final clean = WebhookBillingEventContract.reconcile(
        local: <WebhookEvent>[
          WebhookEvent(
            eventId: 'evtref:psp:invoice-paid-01',
            sequence: 1,
            receivedAtUtc: now,
            type: 'invoice.paid',
          ),
        ],
        providerEventIds: const <String>{'evtref:psp:invoice-paid-01'},
      );
      expect(clean.isConsistent, isTrue);
    });

    test('audit: the trail is append-only, ordered, and redacted', () {
      final trail = WebhookAuditTrail();
      trail.record(
        eventId: 'evtref:psp:invoice-paid-01',
        decision: WebhookDecision.accepted,
        reason: 'signature_verified',
        atUtc: now,
      );
      trail.record(
        eventId: 'evtref:psp:invoice-paid-02',
        decision: WebhookDecision.rejected,
        reason: 'signature_mismatch',
        atUtc: now.add(const Duration(seconds: 1)),
      );

      expect(trail.entries, hasLength(2));
      expect(trail.entries.map((e) => e.sequence).toList(), <int>[1, 2]);
      expect(trail.isOrdered, isTrue);
      expect(trail.entries.last.decision, WebhookDecision.rejected);
      expect(trail.entries.first.toJson()['event_ref'], '[REDACTED]');
      expect(
        () => trail.entries.add(trail.entries.first),
        throwsUnsupportedError,
      );
    });

    test('diagnostics redact event, idempotency, and payment references', () {
      expect(
        WebhookBillingEventContract.redact(
          'evtref:psp:invoice-paid-01 idemref:psp:key-01 payref:psp:pm-primary',
        ),
        '[REDACTED] [REDACTED] [REDACTED]',
      );
    });

    test('validates the canonical manifest acceptance points', () {
      expect(WebhookBillingEventContract.validateCanonicalManifest(), isEmpty);

      expect(
        WebhookBillingEventContract.validateManifest(<String, dynamic>{
          'canonical_step': '119.18',
          'unknown_field_policy': 'REJECT',
          'acceptance': <String, dynamic>{'signature': <String, dynamic>{}},
        }),
        containsAll(<String>[
          'acceptance_missing:replay_protection',
          'acceptance_missing:reconciliation',
          'acceptance_missing:audit',
        ]),
      );
      expect(
        WebhookBillingEventContract.validateManifest(<String, dynamic>{
          'canonical_step': '119.19',
          'unknown_field_policy': 'ALLOW',
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
        ]),
      );
    });
  });
}
