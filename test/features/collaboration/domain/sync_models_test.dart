import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';

void main() {
  test('SyncStatus defaults to idle', () {
    const status = SyncStatus();
    expect(status.state, SyncState.idle);
    expect(status.lastSyncAt, isNull);
    expect(status.message, isNull);
  });

  test('SyncStatus.syncing carries timestamp', () {
    final now = DateTime.utc(2026, 8, 16);
    final status = SyncStatus.syncing(startedAt: now);
    expect(status.state, SyncState.syncing);
    expect(status.startedAt, now);
  });

  test('SyncChangeSet exposes base/ours/theirs and changed keys', () {
    const change = SyncChangeSet(
      base: {'a': '1', 'b': '2'},
      ours: {'a': '1x', 'b': '2'},
      theirs: {'a': '1y', 'b': '2'},
    );
    expect(change.changedKeys, {'a'});
    expect(change.isConflictOn('a'), isTrue);
    expect(change.isConflictOn('b'), isFalse);
  });

  test('SyncChangeSet no conflict when only one side changed', () {
    const change = SyncChangeSet(
      base: {'a': '1'},
      ours: {'a': '1x'},
      theirs: {'a': '1'},
    );
    expect(change.changedKeys, {'a'});
    expect(change.isConflictOn('a'), isFalse);
  });

  test('SyncResult reports applied, total, and conflicts', () {
    const result = SyncResult(
      state: SyncState.synced,
      applied: 3,
      total: 5,
      conflictKeys: {'a'},
    );
    expect(result.applied, 3);
    expect(result.total, 5);
    expect(result.hasConflicts, isTrue);
    expect(result.complete, isFalse);
  });
}
