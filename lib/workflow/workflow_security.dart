/// Sprint 103 / 103.20-103.21 — permission and privacy evaluation.
///
/// Permissions: deny-by-default; escalation is structurally impossible
/// (evaluate() only intersects requested vs granted sets).
library;

/// Privacy: local-only enforcement, external transfers audited,
/// data minimization via declared data kinds.

enum DataTransferKind { inProcess, externalApi }

class DataTransfer {
  const DataTransfer({required this.kind, this.dataKind});

  final DataTransferKind kind;

  /// Declared category of the payload (data minimization contract).
  final String? dataKind;
}

class WorkflowPermissionVerdict {
  const WorkflowPermissionVerdict({
    required this.allowed,
    required this.granted,
    required this.escalationRequested,
    required this.denied,
  });

  final bool allowed;
  final Set<String> granted;
  final bool escalationRequested;
  final Set<String> denied;
}

class WorkflowSecurityEvaluator {
  const WorkflowSecurityEvaluator({this.requireUserConfirmation = false});

  final bool requireUserConfirmation;

  static const WorkflowSecurityEvaluator denyByDefault =
      WorkflowSecurityEvaluator();

  /// Only the intersection of requested ∩ granted is ever allowed.
  WorkflowPermissionVerdict evaluate({
    required Set<String> requiredCapabilities,
    required Set<String> grantedCapabilities,
  }) {
    final granted = requiredCapabilities.intersection(grantedCapabilities);
    final denied = requiredCapabilities.difference(grantedCapabilities);
    return WorkflowPermissionVerdict(
      allowed: denied.isEmpty,
      granted: granted,
      denied: denied,
      // Escalation never happens inside evaluation; extra grants are ignored.
      escalationRequested: false,
    );
  }
}

class WorkflowPrivacyPolicy {
  const WorkflowPrivacyPolicy({
    required this.localOnly,
    this.auditExternalTransfers = true,
    this.allowedDataKinds = const {},
  });

  static const WorkflowPrivacyPolicy strict = WorkflowPrivacyPolicy(
    localOnly: true,
    auditExternalTransfers: true,
  );

  final bool localOnly;
  final bool auditExternalTransfers;
  final Set<String> allowedDataKinds;
}

class WorkflowPrivacyVerdict {
  WorkflowPrivacyVerdict({
    required List<DataTransfer> auditedTransfers,
    required List<String> violations,
  }) : auditedTransfers = List.of(auditedTransfers),
       violations = List.of(violations);

  final List<DataTransfer> auditedTransfers;
  final List<String> violations;

  bool get allowed => violations.isEmpty;
}

class WorkflowPrivacyEvaluator {
  WorkflowPrivacyVerdict evaluate({
    required WorkflowPrivacyPolicy policy,
    required List<DataTransfer> transfers,
  }) {
    final audited = <DataTransfer>[];
    final violations = <String>[];
    for (final t in transfers) {
      if (policy.localOnly && t.kind != DataTransferKind.inProcess) {
        violations.add('local_only_violation: ${t.kind.name} transfer blocked');
        continue;
      }
      if (t.kind == DataTransferKind.externalApi &&
          policy.auditExternalTransfers) {
        audited.add(t);
      }
      if (policy.allowedDataKinds.isNotEmpty &&
          !policy.allowedDataKinds.contains(t.dataKind)) {
        violations.add(
          'data_minimization_violation: undeclared dataKind '
          '${t.dataKind ?? '<null>'}',
        );
      }
    }
    return WorkflowPrivacyVerdict(
      auditedTransfers: audited,
      violations: violations,
    );
  }
}
