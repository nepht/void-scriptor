import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_security.dart';

/// Sprint 103 / 103.20-103.21 — permission & privacy evaluation.
void main() {
  group('Permission evaluation (103.20)', () {
    test('deny-by-default: unlisted capability is refused', () {
      final result = WorkflowSecurityEvaluator.denyByDefault.evaluate(
        requiredCapabilities: const {'fs.write'},
        grantedCapabilities: const {},
      );
      expect(result.allowed, isFalse);
    });

    test('granted capability passes', () {
      final result = WorkflowSecurityEvaluator.denyByDefault.evaluate(
        requiredCapabilities: const {'fs.read'},
        grantedCapabilities: const {'fs.read'},
      );
      expect(result.allowed, isTrue);
    });

    test('escalation is never allowed (no extra grants mid-run)', () {
      final result = WorkflowSecurityEvaluator.denyByDefault.evaluate(
        requiredCapabilities: const {'fs.read', 'net.write'},
        grantedCapabilities: const {'fs.read', 'net.write', 'gpu.compute'},
      );
      expect(result.escalationRequested, isFalse);
      expect(result.granted, equals({'fs.read', 'net.write'}));
    });
  });

  group('Privacy evaluation (103.21)', () {
    test('local_only enforced by default policy', () {
      const policy = WorkflowPrivacyPolicy.strict;
      expect(policy.localOnly, isTrue);
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: policy,
        transfers: const [DataTransfer(kind: DataTransferKind.externalApi)],
      );
      expect(verdict.allowed, isFalse);
    });

    test('in-process transfer under local-only is allowed and unaudited', () {
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: WorkflowPrivacyPolicy.strict,
        transfers: const [DataTransfer(kind: DataTransferKind.inProcess)],
      );
      expect(verdict.allowed, isTrue);
      expect(verdict.auditedTransfers, isEmpty);
    });

    test('external transfer under permissive policy is audited', () {
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: const WorkflowPrivacyPolicy(
          localOnly: false,
          auditExternalTransfers: true,
        ),
        transfers: const [DataTransfer(kind: DataTransferKind.externalApi)],
      );
      expect(verdict.allowed, isTrue);
      expect(
        verdict.auditedTransfers.single.kind,
        DataTransferKind.externalApi,
      );
    });

    test('data minimization: undeclared data kinds are rejected', () {
      final verdict = WorkflowPrivacyEvaluator().evaluate(
        policy: const WorkflowPrivacyPolicy(
          localOnly: false,
          allowedDataKinds: {'asset.metadata'},
        ),
        transfers: const [
          DataTransfer(
            kind: DataTransferKind.inProcess,
            dataKind: 'story.text',
          ),
        ],
      );
      expect(verdict.allowed, isFalse);
      expect(verdict.violations.single, contains('data_minimization'));
    });
  });
}
