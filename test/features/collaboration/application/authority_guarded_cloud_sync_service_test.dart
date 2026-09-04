import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/application/authority_guarded_cloud_sync_service.dart';
import 'package:void_scriptor/features/collaboration/application/cloud_sync_service.dart';
import 'package:void_scriptor/features/collaboration/application/sync_authority_conflict_journal.dart';
import 'package:void_scriptor/features/collaboration/application/sync_authority_store.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_authority_policy.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';

void main() {
  test(
    'push claims authority for its kind and delegates when allowed',
    () async {
      final dir = Directory.systemTemp.createTempSync('vs_sync_guard_ok_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final authority = PersistedSyncAuthority(
        store: SyncAuthorityStore(rootDirectory: dir),
      );
      final inner = InMemoryCloudSyncService();
      final cloud = AuthorityGuardedCloudSyncService(
        delegate: inner,
        authority: authority,
        kind: SyncAuthority.cloud,
      );

      await cloud.push(projectId: 'p1', state: const {'a': '1'});

      expect(await inner.pull('p1'), {'a': '1'});
    },
  );

  test(
    'push is denied when the other authority owns the live project',
    () async {
      final dir = Directory.systemTemp.createTempSync('vs_sync_guard_deny_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final authority = PersistedSyncAuthority(
        store: SyncAuthorityStore(rootDirectory: dir),
      );
      final granted = await authority.claim('p1', SyncAuthority.externalFolder);
      expect(granted.allowed, isTrue);
      final inner = InMemoryCloudSyncService();
      final cloud = AuthorityGuardedCloudSyncService(
        delegate: inner,
        authority: authority,
        kind: SyncAuthority.cloud,
      );

      await expectLater(
        cloud.push(projectId: 'p1', state: const {'a': '1'}),
        throwsA(
          isA<SyncAuthorityDeniedException>().having(
            (e) => e.message,
            'message',
            allOf(contains('cloud'), contains('external folder')),
          ),
        ),
      );
      expect(await inner.pull('p1'), isEmpty);
    },
  );

  test(
    'sync denial surfaces an error result with a user-readable warning',
    () async {
      final dir = Directory.systemTemp.createTempSync('vs_sync_guard_sync_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final authority = PersistedSyncAuthority(
        store: SyncAuthorityStore(rootDirectory: dir),
      );
      final granted = await authority.claim('p1', SyncAuthority.externalFolder);
      expect(granted.allowed, isTrue);
      final cloud = AuthorityGuardedCloudSyncService(
        delegate: InMemoryCloudSyncService(),
        authority: authority,
        kind: SyncAuthority.cloud,
      );

      final result = await cloud.sync(projectId: 'p1', local: const {'a': '1'});

      expect(result.state, SyncState.error);
      expect(result.applied, 0);
      expect(result.message, contains('cloud'));
      expect(result.message, contains('external folder'));
    },
  );

  test('sync delegates when the same authority is already claimed', () async {
    final dir = Directory.systemTemp.createTempSync('vs_sync_guard_same_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final authority = PersistedSyncAuthority(
      store: SyncAuthorityStore(rootDirectory: dir),
    );
    final granted = await authority.claim('p1', SyncAuthority.cloud);
    expect(granted.allowed, isTrue);
    final inner = InMemoryCloudSyncService();
    final cloud = AuthorityGuardedCloudSyncService(
      delegate: inner,
      authority: authority,
      kind: SyncAuthority.cloud,
    );

    final result = await cloud.sync(projectId: 'p1', local: const {'a': '1'});

    expect(result.state, SyncState.synced);
    expect(await inner.pull('p1'), {'a': '1'});
  });

  test('persisted ownership denies a fresh process-owned service', () async {
    final dir = Directory.systemTemp.createTempSync('vs_sync_guard_persist_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = SyncAuthorityStore(rootDirectory: dir);
    final firstAuthority = PersistedSyncAuthority(store: store);
    final first = AuthorityGuardedCloudSyncService(
      delegate: InMemoryCloudSyncService(),
      authority: firstAuthority,
      kind: SyncAuthority.cloud,
    );
    await first.push(projectId: 'p1', state: const {'a': '1'});

    final secondAuthority = PersistedSyncAuthority(store: store);
    await secondAuthority.restore('p1');
    final folderSync = AuthorityGuardedCloudSyncService(
      delegate: InMemoryCloudSyncService(),
      authority: secondAuthority,
      kind: SyncAuthority.externalFolder,
    );

    await expectLater(
      folderSync.push(projectId: 'p1', state: const {'b': '2'}),
      throwsA(isA<SyncAuthorityDeniedException>()),
    );
  });

  test('pull stays readable while ownership is denied', () async {
    final dir = Directory.systemTemp.createTempSync('vs_sync_guard_pull_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final authority = PersistedSyncAuthority(
      store: SyncAuthorityStore(rootDirectory: dir),
    );
    final granted = await authority.claim('p1', SyncAuthority.externalFolder);
    expect(granted.allowed, isTrue);
    final inner = InMemoryCloudSyncService();
    await inner.push(projectId: 'p1', state: const {'a': '1'});
    final cloud = AuthorityGuardedCloudSyncService(
      delegate: inner,
      authority: authority,
      kind: SyncAuthority.cloud,
    );

    expect(await cloud.pull('p1'), {'a': '1'});
  });

  test('denied sync parks local changes in the conflict journal', () async {
    final dir = Directory.systemTemp.createTempSync('vs_sync_guard_park_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final journalDir = Directory.systemTemp.createTempSync(
      'vs_sync_journal_park_',
    );
    addTearDown(() => journalDir.deleteSync(recursive: true));
    final authority = PersistedSyncAuthority(
      store: SyncAuthorityStore(rootDirectory: dir),
    );
    final granted = await authority.claim('p1', SyncAuthority.externalFolder);
    expect(granted.allowed, isTrue);
    final inner = InMemoryCloudSyncService();
    final cloud = AuthorityGuardedCloudSyncService(
      delegate: inner,
      authority: authority,
      kind: SyncAuthority.cloud,
      conflictJournal: SyncAuthorityConflictJournal(rootDirectory: journalDir),
    );

    final result = await cloud.sync(projectId: 'p1', local: const {'a': '1'});

    expect(result.state, SyncState.conflict);
    expect(result.applied, 0);
    expect(result.message, contains('preserved locally'));
    final parked = await SyncAuthorityConflictJournal(
      rootDirectory: journalDir,
    ).pending('p1');
    expect(parked, hasLength(1));
    expect(parked.single.local, {'a': '1'});
  });

  test(
    'drain applies parked changes after the authority conflict clears',
    () async {
      final dir = Directory.systemTemp.createTempSync('vs_sync_guard_drain_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final journalDir = Directory.systemTemp.createTempSync(
        'vs_sync_journal_drain_',
      );
      addTearDown(() => journalDir.deleteSync(recursive: true));
      final authority = PersistedSyncAuthority(
        store: SyncAuthorityStore(rootDirectory: dir),
      );
      final inner = InMemoryCloudSyncService();
      final journal = SyncAuthorityConflictJournal(rootDirectory: journalDir);
      final cloud = AuthorityGuardedCloudSyncService(
        delegate: inner,
        authority: authority,
        kind: SyncAuthority.cloud,
        conflictJournal: journal,
      );

      final owner = await authority.claim('p1', SyncAuthority.externalFolder);
      expect(owner.allowed, isTrue);
      final first = await cloud.sync(projectId: 'p1', local: const {'a': '1'});
      expect(first.state, SyncState.conflict);
      await authority.release('p1');
      final granted = await authority.claim('p1', SyncAuthority.cloud);
      expect(granted.allowed, isTrue);

      final outcome = await journal.drain(
        projectId: 'p1',
        remote: await inner.pull('p1'),
        apply: (merged) => inner.push(projectId: 'p1', state: merged),
      );

      expect(outcome.applied, 1);
      expect(outcome.remaining, 0);
      expect(await inner.pull('p1'), {'a': '1'});
    },
  );
}
