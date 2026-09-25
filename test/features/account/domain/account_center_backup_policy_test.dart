import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_backup_policy.dart';
import 'package:void_scriptor/features/account/domain/account_center_workspace_boundary_contract.dart';

void main() {
  group('AccountCenterBackupPolicy', () {
    test('manifest preserves every canonical 115.22 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_backup_policies_destinations.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.22');
      expect(manifest['acceptance'], <String>[
        'schedule',
        'retention',
        'encryption',
        'destination',
        'workspace_boundary',
        'verification',
        'restore_test',
      ]);
    });

    test('normalizes a scheduled encrypted workspace backup policy', () {
      final policy = AccountCenterBackupPolicy(
        policyId: ' policy-1 ',
        schedule: BackupSchedule.daily(hourUtc: 2),
        retention: BackupRetention(maxCopies: 14),
        encryption: BackupEncryption.aes256,
        destination: BackupDestination(
          destinationId: ' cloud-1 ',
          kind: BackupDestinationKind.cloud,
          availability: BackupDestinationAvailability.available,
        ),
        workspaceBoundary: AccountBackupBoundary.novelWorkspace,
      );

      expect(policy.policyId, 'policy-1');
      expect(policy.schedule.hourUtc, 2);
      expect(policy.retention.maxCopies, 14);
      expect(policy.destination.destinationId, 'cloud-1');
      expect(policy.canRun, isTrue);
    });

    test('fails closed for invalid retention, schedule, and destination', () {
      expect(() => BackupRetention(maxCopies: 0), throwsArgumentError);
      expect(() => BackupSchedule.daily(hourUtc: 24), throwsArgumentError);
      expect(
        () => BackupDestination(
          destinationId: ' ',
          kind: BackupDestinationKind.local,
          availability: BackupDestinationAvailability.available,
        ),
        throwsArgumentError,
      );
    });

    test(
      'requires encryption and an available destination before execution',
      () {
        final unencrypted = AccountCenterBackupPolicy(
          policyId: 'policy-1',
          schedule: BackupSchedule.manual(),
          retention: BackupRetention(maxCopies: 2),
          encryption: BackupEncryption.none,
          destination: BackupDestination(
            destinationId: 'local',
            kind: BackupDestinationKind.local,
            availability: BackupDestinationAvailability.available,
          ),
          workspaceBoundary: AccountBackupBoundary.accountGlobal,
        );
        final unavailable = AccountCenterBackupPolicy(
          policyId: 'policy-2',
          schedule: BackupSchedule.manual(),
          retention: BackupRetention(maxCopies: 2),
          encryption: BackupEncryption.aes256,
          destination: BackupDestination(
            destinationId: 'cloud',
            kind: BackupDestinationKind.cloud,
            availability: BackupDestinationAvailability.unavailable,
          ),
          workspaceBoundary: AccountBackupBoundary.accountGlobal,
        );

        expect(unencrypted.canRun, isFalse);
        expect(unavailable.canRun, isFalse);
      },
    );

    test(
      'records verification and restore tests without claiming live success',
      () {
        final verifiedAt = DateTime.utc(2026, 9, 26, 1);
        final restoredAt = DateTime.utc(2026, 9, 26, 2);
        final evidence = BackupPolicyEvidence(
          verification: BackupCheckResult.passed(
            checkedAt: verifiedAt,
            evidenceId: ' verify-1 ',
          ),
          restoreTest: BackupCheckResult.passed(
            checkedAt: restoredAt,
            evidenceId: ' restore-1 ',
          ),
        );

        expect(evidence.isVerified, isTrue);
        expect(evidence.hasPassingRestoreTest, isTrue);
        expect(evidence.verification.evidenceId, 'verify-1');
        expect(evidence.restoreTest.checkedAt, restoredAt);

        final pending = BackupPolicyEvidence.pending();
        expect(pending.isVerified, isFalse);
        expect(pending.hasPassingRestoreTest, isFalse);
      },
    );
  });
}
