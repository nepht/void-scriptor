import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_cross_storage_sync_backup_certification.dart';

void main() {
  test('accepts the complete local certification contract', () {
    final contract = CrossStorageSyncBackupCertification(
      queue: 'durable',
      retryResume: 'bounded-resumable',
      conflictResolution: 'explicit-review',
      encryptedBackup: 'local-key-vault',
      restore: 'clean-install-verified',
      workspaceBoundaries: const ['novel', 'character'],
      largeAssets: 'streamed-and-checksummed',
      limitations: const ['live-provider-sync-deferred'],
    );

    expect(contract.isComplete, isTrue);
    expect(contract.toJson(), containsPair('queue', 'durable'));
    expect(
      contract.toJson(),
      containsPair('workspace_boundaries', ['novel', 'character']),
    );
  });

  test('fails closed when a required output is empty or unknown', () {
    expect(
      () => CrossStorageSyncBackupCertification(
        queue: '',
        retryResume: 'bounded-resumable',
        conflictResolution: 'explicit-review',
        encryptedBackup: 'local-key-vault',
        restore: 'clean-install-verified',
        workspaceBoundaries: const ['novel'],
        largeAssets: 'streamed-and-checksummed',
        limitations: const ['live-provider-sync-deferred'],
      ),
      throwsArgumentError,
    );

    expect(
      () => CrossStorageSyncBackupCertification.fromJson({
        'queue': 'durable',
        'retry_resume': 'bounded-resumable',
        'conflict_resolution': 'explicit-review',
        'encrypted_backup': 'local-key-vault',
        'restore': 'clean-install-verified',
        'workspace_boundaries': ['novel'],
        'large_assets': 'streamed-and-checksummed',
        'limitations': ['live-provider-sync-deferred'],
        'unexpected': true,
      }),
      throwsArgumentError,
    );
  });
}
