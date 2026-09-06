import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_security.dart';

/// Sprint 103 / 103.20-103.21 — permission (deny-by-default, audited) and
/// privacy (local-only, data-minimization) evaluation for workflows.
void main() {
  test('workflow execution is denied when either security gate fails', () {
    final permission = WorkflowSecurityEvaluator.denyByDefault.evaluate(
      requiredCapabilities: const {'project.read', 'network.write'},
      grantedCapabilities: const {'project.read'},
    );
    final privacy = WorkflowPrivacyEvaluator().evaluate(
      policy: WorkflowPrivacyPolicy.strict,
      transfers: const [
        DataTransfer(
          kind: DataTransferKind.externalApi,
          dataKind: 'story.text',
        ),
      ],
    );

    expect(permission.allowed && privacy.allowed, isFalse);
    expect(permission.denied, equals({'network.write'}));
    expect(permission.escalationRequested, isFalse);
    expect(privacy.violations, contains(contains('local_only_violation')));
  });

  test('explicit local capability and minimized data pass both gates', () {
    final permission = WorkflowSecurityEvaluator.denyByDefault.evaluate(
      requiredCapabilities: const {'project.read'},
      grantedCapabilities: const {'project.read'},
    );
    final privacy = WorkflowPrivacyEvaluator().evaluate(
      policy: const WorkflowPrivacyPolicy(
        localOnly: true,
        allowedDataKinds: {'project.metadata'},
      ),
      transfers: const [
        DataTransfer(
          kind: DataTransferKind.inProcess,
          dataKind: 'project.metadata',
        ),
      ],
    );

    expect(permission.allowed && privacy.allowed, isTrue);
    expect(privacy.auditedTransfers, isEmpty);
  });
}
