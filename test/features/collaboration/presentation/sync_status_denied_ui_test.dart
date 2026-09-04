import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/application/authority_guarded_cloud_sync_service.dart';
import 'package:void_scriptor/features/collaboration/application/cloud_sync_service.dart';
import 'package:void_scriptor/features/collaboration/application/sync_authority_conflict_journal.dart';
import 'package:void_scriptor/features/collaboration/application/sync_authority_store.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_authority_policy.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';
import 'package:void_scriptor/features/collaboration/presentation/sync_status_indicator.dart';

/// UI evidence for the Sprint 145.32 single-sync-authority rule: the exact
/// states the runtime guard produces on a denied write (SyncState.error when
/// no journal is attached, SyncState.conflict when the conflict journal parks
/// the change) must be visible in the SyncStatusIndicator with the
/// user-readable warning as its tooltip.
void main() {
  testWidgets('denied sync surfaces the guard error state in the UI', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('vs_denied_ui_error_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final authority = PersistedSyncAuthority(
      store: SyncAuthorityStore(rootDirectory: dir),
    );
    final cloud = AuthorityGuardedCloudSyncService(
      delegate: InMemoryCloudSyncService(),
      authority: authority,
      kind: SyncAuthority.cloud,
    );

    // Real async (file I/O in the authority store) cannot run inside the
    // testWidgets fake-async zone: run the seeded claim and the guarded
    // sync via runAsync.
    final granted = await tester.runAsync(
      () => authority.claim('p1', SyncAuthority.externalFolder),
    );
    expect(granted!.allowed, isTrue);
    final result = await tester.runAsync(
      () => cloud.sync(projectId: 'p1', local: const {'a': '1'}),
    );

    expect(result, isNotNull, reason: 'the guard must always return a result');
    final denied = result!;
    expect(denied.state, SyncState.error);
    expect(denied.applied, 0);
    expect(denied.message, contains('cannot own one live project'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncStatusIndicator(
            status: SyncStatus(state: denied.state, message: denied.message),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.byTooltip(denied.message!),
      findsOneWidget,
      reason: 'the user-readable denial warning must be the UI tooltip',
    );
  });

  testWidgets('journal-parked denial surfaces the conflict state in the UI', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('vs_denied_ui_conflict_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final authority = PersistedSyncAuthority(
      store: SyncAuthorityStore(rootDirectory: dir),
    );
    final journal = SyncAuthorityConflictJournal(rootDirectory: dir);
    final cloud = AuthorityGuardedCloudSyncService(
      delegate: InMemoryCloudSyncService(),
      authority: authority,
      kind: SyncAuthority.cloud,
      conflictJournal: journal,
    );

    // Real async (file I/O in the authority store and the journal) cannot
    // run inside the testWidgets fake-async zone: run the seeded claim and
    // the guarded sync via runAsync.
    final granted = await tester.runAsync(
      () => authority.claim('p1', SyncAuthority.externalFolder),
    );
    expect(granted!.allowed, isTrue);
    final result = await tester.runAsync(
      () => cloud.sync(projectId: 'p1', local: const {'a': '1'}),
    );

    expect(result, isNotNull, reason: 'the guard must always return a result');
    final denied = result!;
    expect(denied.state, SyncState.conflict);
    expect(denied.applied, 0);
    expect(denied.message, contains('cannot own one live project'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncStatusIndicator(
            status: SyncStatus(state: denied.state, message: denied.message),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.byTooltip(denied.message!), findsOneWidget);
  });
}
