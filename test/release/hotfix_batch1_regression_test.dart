import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/safety_runtime.dart';

/// Sprint 107 hotfix batch 1 — regression gates over v1.1.0 stable code
/// (ledger steps 107.14 / 107.15 / 107.21). These tests pin behaviour that
/// must not change during post-release stabilization.
void main() {
  group('107.15 — approval-gate regression', () {
    final base = DateTime.utc(2026, 8, 25, 12);

    test(
      'sensitive action cannot wait for human without durable checkpoint',
      () {
        final runtime = HumanDecisionRuntime();
        expect(
          () => runtime.waitForHuman(
            requestId: 'req-no-checkpoint',
            gate: const ApprovalGate(
              gateId: 'g-destructive',
              type: ApprovalGateType.approveExternalTransfer,
            ),
            checkpointPersisted: false,
            now: base,
          ),
          throwsStateError,
        );
      },
    );

    test('every canonical gate type produces a checkpointed request', () {
      final runtime = HumanDecisionRuntime();
      for (final type in ApprovalGateType.values) {
        final request = runtime.waitForHuman(
          requestId: 'req-$type',
          gate: ApprovalGate(gateId: 'gate-$type', type: type),
          checkpointPersisted: true,
          now: base,
        );
        expect(
          request.checkpointed,
          isTrue,
          reason: 'checkpoint_before_wait contract must hold for $type',
        );
        expect(request.deadline.isAfter(base), isTrue);
      }
      expect(ApprovalGateType.values.length, 5);
    });

    test('decision inside deadline is accepted and audited', () {
      final runtime = HumanDecisionRuntime();
      final request = runtime.waitForHuman(
        requestId: 'req-ok',
        gate: const ApprovalGate(
          gateId: 'g-publish',
          type: ApprovalGateType.reviewOutput,
        ),
        checkpointPersisted: true,
        now: base,
      );
      final accepted = runtime.decide(
        request: request,
        decision: HumanDecision.approved,
        now: base.add(const Duration(minutes: 5)),
      );
      expect(accepted, isTrue);
      expect(runtime.audit, contains('human:req-ok:approved'));
    });

    test('decision after deadline is rejected (expired path)', () {
      final runtime = HumanDecisionRuntime();
      final request = runtime.waitForHuman(
        requestId: 'req-late',
        gate: const ApprovalGate(
          gateId: 'g-transfer',
          type: ApprovalGateType.approveExternalTransfer,
        ),
        checkpointPersisted: true,
        now: base,
      );
      final accepted = runtime.decide(
        request: request,
        decision: HumanDecision.approved,
        now: request.deadline.add(const Duration(seconds: 1)),
      );
      expect(accepted, isFalse);
    });

    test('timeout resolves fail-safe DENIED and leaves an audit trail', () {
      final runtime = HumanDecisionRuntime();
      final request = runtime.waitForHuman(
        requestId: 'req-timeout',
        gate: const ApprovalGate(
          gateId: 'g-secret-use',
          type: ApprovalGateType.reauthentication,
        ),
        checkpointPersisted: true,
        now: base,
      );
      expect(runtime.resolveTimeout(request), isFalse);
      expect(runtime.audit, contains('timeout:req-timeout:denied'));
    });
  });

  group('107.14 — duplicate-effect prevention regression', () {
    final base = DateTime.utc(2026, 8, 25, 12);

    test('same logical event inside window is suppressed', () {
      final suppressor = DuplicateTriggerSuppressor(
        window: const Duration(minutes: 10),
      );
      final first = suppressor.submit(
        dedupeKey: 'rule-1:file-created:a.txt',
        sourceEventId: 'evt-1',
        now: base,
      );
      final second = suppressor.submit(
        dedupeKey: 'rule-1:file-created:a.txt',
        sourceEventId: 'evt-2',
        now: base.add(const Duration(minutes: 3)),
      );
      expect(first.decision, SuppressionDecision.allowed);
      expect(second.decision, SuppressionDecision.suppressed);
      expect(
        second.sourceEventId,
        'evt-2',
        reason: 'audit carries the RAW event identity',
      );
    });

    test('same logical event outside window is allowed again', () {
      final suppressor = DuplicateTriggerSuppressor(
        window: const Duration(minutes: 10),
      );
      suppressor.submit(dedupeKey: 'k', sourceEventId: 'evt-1', now: base);
      final later = suppressor.submit(
        dedupeKey: 'k',
        sourceEventId: 'evt-2',
        now: base.add(const Duration(minutes: 10)),
      );
      expect(later.decision, SuppressionDecision.allowed);
    });

    test('distinct logical events never suppress each other', () {
      final suppressor = DuplicateTriggerSuppressor(
        window: const Duration(minutes: 10),
      );
      final a = suppressor.submit(
        dedupeKey: 'workflow-A',
        sourceEventId: 'evt-1',
        now: base,
      );
      final b = suppressor.submit(
        dedupeKey: 'workflow-B',
        sourceEventId: 'evt-2',
        now: base.add(const Duration(seconds: 1)),
      );
      expect(a.decision, SuppressionDecision.allowed);
      expect(b.decision, SuppressionDecision.allowed);
    });
  });

  group('107.21 — localization parity (en/id regression)', () {
    late Map<String, dynamic> en;
    late Map<String, dynamic> id;

    setUp(() {
      en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      id =
          jsonDecode(File('lib/l10n/app_id.arb').readAsStringSync())
              as Map<String, dynamic>;
    });

    List<String> messageKeys(Map<String, dynamic> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toList();

    test('en and id expose the exact same message key set', () {
      expect(messageKeys(id).toSet(), equals(messageKeys(en).toSet()));
    });

    test('no raw keys surfaced as values in either locale', () {
      final locales = <String, Map<String, dynamic>>{'en': en, 'id': id};
      for (final arb in locales.entries) {
        for (final entry in arb.value.entries) {
          if (entry.key.startsWith('@')) continue;
          final value = entry.value;
          if (value is String) {
            expect(
              value.trim(),
              isNotEmpty,
              reason: '${arb.key}:${entry.key} has an empty value',
            );
            expect(
              value,
              isNot(entry.key),
              reason: '${arb.key}:${entry.key} surfaces its raw key',
            );
          }
        }
      }
    });
  });
}
