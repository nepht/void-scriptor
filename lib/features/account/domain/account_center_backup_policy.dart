/// Sprint 115.22 — Backup Policies & Destinations.
///
/// Provider-agnostic metadata contract. It does not perform a backup or claim
/// live destination, encryption, verification, or restore-test success.
library;

import 'account_center_workspace_boundary_contract.dart';

enum BackupScheduleKind { manual, daily }

enum BackupEncryption { none, aes256 }

enum BackupDestinationKind { local, removable, cloud }

enum BackupDestinationAvailability { available, unavailable, unknown }

enum BackupCheckStatus { pending, passed, failed }

final class BackupSchedule {
  BackupSchedule.manual() : kind = BackupScheduleKind.manual, hourUtc = null;

  BackupSchedule.daily({required int hourUtc})
    : kind = BackupScheduleKind.daily,
      hourUtc = _validHour(hourUtc);

  final BackupScheduleKind kind;
  final int? hourUtc;

  static int _validHour(int value) {
    if (value < 0 || value > 23) {
      throw ArgumentError.value(value, 'hourUtc');
    }
    return value;
  }
}

final class BackupRetention {
  BackupRetention({required int maxCopies})
    : maxCopies = _positive(maxCopies, 'maxCopies');

  final int maxCopies;

  static int _positive(int value, String field) {
    if (value <= 0) throw ArgumentError.value(value, field);
    return value;
  }
}

final class BackupDestination {
  BackupDestination({
    required String destinationId,
    required this.kind,
    required this.availability,
  }) : destinationId = _required(destinationId);

  final String destinationId;
  final BackupDestinationKind kind;
  final BackupDestinationAvailability availability;

  bool get isAvailable =>
      availability == BackupDestinationAvailability.available;

  static String _required(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, 'destinationId');
    return normalized;
  }
}

final class AccountCenterBackupPolicy {
  AccountCenterBackupPolicy({
    required String policyId,
    required this.schedule,
    required this.retention,
    required this.encryption,
    required this.destination,
    required this.workspaceBoundary,
  }) : policyId = _required(policyId, 'policyId');

  final String policyId;
  final BackupSchedule schedule;
  final BackupRetention retention;
  final BackupEncryption encryption;
  final BackupDestination destination;
  final AccountBackupBoundary workspaceBoundary;

  bool get canRun =>
      encryption != BackupEncryption.none && destination.isAvailable;

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }
}

final class BackupCheckResult {
  BackupCheckResult._({
    required this.status,
    required this.checkedAt,
    required this.evidenceId,
  });

  factory BackupCheckResult.pending() => BackupCheckResult._(
    status: BackupCheckStatus.pending,
    checkedAt: null,
    evidenceId: null,
  );

  factory BackupCheckResult.passed({
    required DateTime checkedAt,
    required String evidenceId,
  }) => BackupCheckResult._(
    status: BackupCheckStatus.passed,
    checkedAt: checkedAt.toUtc(),
    evidenceId: AccountCenterBackupPolicy._required(evidenceId, 'evidenceId'),
  );

  factory BackupCheckResult.failed({
    required DateTime checkedAt,
    required String evidenceId,
  }) => BackupCheckResult._(
    status: BackupCheckStatus.failed,
    checkedAt: checkedAt.toUtc(),
    evidenceId: AccountCenterBackupPolicy._required(evidenceId, 'evidenceId'),
  );

  final BackupCheckStatus status;
  final DateTime? checkedAt;
  final String? evidenceId;

  bool get passed => status == BackupCheckStatus.passed;
}

final class BackupPolicyEvidence {
  const BackupPolicyEvidence({
    required this.verification,
    required this.restoreTest,
  });

  factory BackupPolicyEvidence.pending() => BackupPolicyEvidence(
    verification: BackupCheckResult.pending(),
    restoreTest: BackupCheckResult.pending(),
  );

  final BackupCheckResult verification;
  final BackupCheckResult restoreTest;

  bool get isVerified => verification.passed;
  bool get hasPassingRestoreTest => restoreTest.passed;
}
