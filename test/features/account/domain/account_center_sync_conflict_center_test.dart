import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_sync_conflict_center.dart';

void main() {
  group('AccountCenterSyncConflictCenter', () {
    test('manifest preserves every canonical 115.23 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_sync_conflict_center.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.23');
      expect(manifest['acceptance'], <String>[
        'conflict_detection',
        'version_preview',
        'keep_local',
        'keep_remote',
        'merge_when_supported',
        'history',
        'backup_before_resolution',
      ]);
    });

    test('detects distinct local and remote versions with safe previews', () {
      final conflict = SyncConflict.detect(
        conflictId: ' conflict-1 ',
        sourceId: ' provider-1 ',
        itemId: ' chapter-1 ',
        local: SyncConflictVersion(
          versionId: ' local-v2 ',
          modifiedAt: DateTime.utc(2026, 9, 26, 1),
          preview: 'Local chapter preview',
        ),
        remote: SyncConflictVersion(
          versionId: ' remote-v3 ',
          modifiedAt: DateTime.utc(2026, 9, 26, 2),
          preview: 'Remote chapter preview',
        ),
        mergeSupported: true,
      );

      expect(conflict.conflictId, 'conflict-1');
      expect(conflict.sourceId, 'provider-1');
      expect(conflict.itemId, 'chapter-1');
      expect(conflict.local.versionId, 'local-v2');
      expect(conflict.remote.preview, 'Remote chapter preview');
      expect(conflict.status, SyncConflictStatus.unresolved);
    });

    test('rejects equal versions because they do not form a conflict', () {
      final version = SyncConflictVersion(
        versionId: 'same',
        modifiedAt: DateTime.utc(2026, 9, 26),
        preview: 'Same content',
      );

      expect(
        () => SyncConflict.detect(
          conflictId: 'conflict-1',
          sourceId: 'provider-1',
          itemId: 'chapter-1',
          local: version,
          remote: version,
          mergeSupported: false,
        ),
        throwsArgumentError,
      );
    });

    test('requires a completed backup before keep-local resolution', () {
      final center = AccountCenterSyncConflictCenter([
        _conflict(mergeSupported: false),
      ]);

      expect(
        () => center.resolve(
          conflictId: 'conflict-1',
          strategy: SyncConflictResolution.keepLocal,
          backup: ConflictBackupEvidence.pending(),
          resolvedAt: DateTime.utc(2026, 9, 26, 3),
        ),
        throwsStateError,
      );

      final resolved = center.resolve(
        conflictId: 'conflict-1',
        strategy: SyncConflictResolution.keepLocal,
        backup: ConflictBackupEvidence.completed(
          backupId: ' backup-1 ',
          completedAt: DateTime.utc(2026, 9, 26, 2, 59),
        ),
        resolvedAt: DateTime.utc(2026, 9, 26, 3),
      );

      expect(resolved.conflicts.single.status, SyncConflictStatus.resolved);
      expect(
        resolved.conflicts.single.resolution,
        SyncConflictResolution.keepLocal,
      );
      expect(resolved.history.single.backupId, 'backup-1');
      expect(resolved.history.single.selectedVersionId, 'local-v2');
    });

    test('supports keep-remote and records immutable resolution history', () {
      final center = AccountCenterSyncConflictCenter([
        _conflict(mergeSupported: false),
      ]);
      final resolved = center.resolve(
        conflictId: 'conflict-1',
        strategy: SyncConflictResolution.keepRemote,
        backup: ConflictBackupEvidence.completed(
          backupId: 'backup-1',
          completedAt: DateTime.utc(2026, 9, 26, 2),
        ),
        resolvedAt: DateTime.utc(2026, 9, 26, 3),
      );

      expect(resolved.history.single.selectedVersionId, 'remote-v3');
      expect(
        () => resolved.history.add(resolved.history.single),
        throwsUnsupportedError,
      );
    });

    test(
      'allows merge only when supported and a merged version is supplied',
      () {
        final unsupported = AccountCenterSyncConflictCenter([
          _conflict(mergeSupported: false),
        ]);
        final backup = ConflictBackupEvidence.completed(
          backupId: 'backup-1',
          completedAt: DateTime.utc(2026, 9, 26, 2),
        );

        expect(
          () => unsupported.resolve(
            conflictId: 'conflict-1',
            strategy: SyncConflictResolution.merge,
            backup: backup,
            mergedVersion: SyncConflictVersion(
              versionId: 'merged-v4',
              modifiedAt: DateTime.utc(2026, 9, 26, 3),
              preview: 'Merged preview',
            ),
            resolvedAt: DateTime.utc(2026, 9, 26, 3),
          ),
          throwsStateError,
        );

        final supported = AccountCenterSyncConflictCenter([
          _conflict(mergeSupported: true),
        ]);
        expect(
          () => supported.resolve(
            conflictId: 'conflict-1',
            strategy: SyncConflictResolution.merge,
            backup: backup,
            resolvedAt: DateTime.utc(2026, 9, 26, 3),
          ),
          throwsArgumentError,
        );

        final resolved = supported.resolve(
          conflictId: 'conflict-1',
          strategy: SyncConflictResolution.merge,
          backup: backup,
          mergedVersion: SyncConflictVersion(
            versionId: 'merged-v4',
            modifiedAt: DateTime.utc(2026, 9, 26, 3),
            preview: 'Merged preview',
          ),
          resolvedAt: DateTime.utc(2026, 9, 26, 3),
        );
        expect(resolved.history.single.selectedVersionId, 'merged-v4');
      },
    );

    test(
      'safe fallback leaves unknown and already-resolved conflicts unchanged',
      () {
        final center = AccountCenterSyncConflictCenter([
          _conflict(mergeSupported: false),
        ]);
        final backup = ConflictBackupEvidence.completed(
          backupId: 'backup-1',
          completedAt: DateTime.utc(2026, 9, 26, 2),
        );

        expect(
          center.safeFallback(conflictId: 'missing').status,
          SyncConflictFallbackStatus.notFound,
        );

        final resolved = center.resolve(
          conflictId: 'conflict-1',
          strategy: SyncConflictResolution.keepLocal,
          backup: backup,
          resolvedAt: DateTime.utc(2026, 9, 26, 3),
        );
        expect(
          resolved.safeFallback(conflictId: 'conflict-1').status,
          SyncConflictFallbackStatus.alreadyResolved,
        );
        expect(resolved.history, hasLength(1));
      },
    );
  });
}

SyncConflict _conflict({required bool mergeSupported}) {
  return SyncConflict.detect(
    conflictId: 'conflict-1',
    sourceId: 'provider-1',
    itemId: 'chapter-1',
    local: SyncConflictVersion(
      versionId: 'local-v2',
      modifiedAt: DateTime.utc(2026, 9, 26, 1),
      preview: 'Local preview',
    ),
    remote: SyncConflictVersion(
      versionId: 'remote-v3',
      modifiedAt: DateTime.utc(2026, 9, 26, 2),
      preview: 'Remote preview',
    ),
    mergeSupported: mergeSupported,
  );
}
