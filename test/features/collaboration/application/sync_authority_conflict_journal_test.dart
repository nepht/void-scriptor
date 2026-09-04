import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/collaboration/application/sync_authority_conflict_journal.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_authority_policy.dart';
import 'package:void_scriptor/features/collaboration/domain/sync_models.dart';

void main() {
  late Directory tempDir;
  late SyncAuthorityConflictJournal journal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_authority_journal');
    journal = SyncAuthorityConflictJournal(rootDirectory: tempDir);
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // Best-effort cleanup; temp dirs are removed by the OS eventually.
    }
  });

  test(
    'park keeps denied local changes and reports a conflict state',
    () async {
      final local = <String, Object?>{'title': 'Arc One', 'wordCount': 1200};

      final result = await journal.park(
        projectId: 'proj-1',
        authority: SyncAuthority.externalFolder,
        reason: 'cloud owns the live project',
        local: local,
      );

      expect(result.state, SyncState.conflict);
      expect(result.applied, 0);
      expect(result.total, local.length);
      expect(result.hasConflicts, isTrue);
      expect(result.message, contains('cloud'));
      expect(result.message, contains('preserved locally'));

      final entries = await journal.pending('proj-1');
      expect(entries, hasLength(1));
      expect(entries.single.local, local);
      expect(entries.single.authority, SyncAuthority.externalFolder);
      expect(entries.single.reason, contains('cloud'));
    },
  );

  test(
    'parked changes survive a journal restart with no silent loss',
    () async {
      await journal.park(
        projectId: 'proj-1',
        authority: SyncAuthority.externalFolder,
        reason: 'cloud owns the live project',
        local: <String, Object?>{'title': 'Arc One'},
      );

      final reopened = SyncAuthorityConflictJournal(rootDirectory: tempDir);
      final entries = await reopened.pending('proj-1');

      expect(entries, hasLength(1));
      expect(entries.single.local, <String, Object?>{'title': 'Arc One'});
    },
  );

  test(
    'drain merges parked changes once the authority conflict is gone',
    () async {
      await journal.park(
        projectId: 'proj-1',
        authority: SyncAuthority.externalFolder,
        reason: 'cloud owns the live project',
        local: <String, Object?>{'title': 'Arc One', 'note': 'draft'},
      );

      final appliedMerges = <Map<String, Object?>>[];
      final outcome = await journal.drain(
        projectId: 'proj-1',
        remote: <String, Object?>{'title': 'Arc One', 'wordCount': 900},
        apply: (merged) async => appliedMerges.add(merged),
      );

      expect(outcome.applied, 1);
      expect(outcome.remaining, 0);
      expect(outcome.conflictKeys, isEmpty);
      expect(appliedMerges.single, <String, Object?>{
        'title': 'Arc One',
        'note': 'draft',
        'wordCount': 900,
      });
      expect(await journal.pending('proj-1'), isEmpty);
    },
  );

  test(
    'drain keeps entries pending when remote diverged on the same key',
    () async {
      await journal.park(
        projectId: 'proj-1',
        authority: SyncAuthority.externalFolder,
        reason: 'cloud owns the live project',
        local: <String, Object?>{'title': 'Mine'},
      );

      final appliedMerges = <Map<String, Object?>>[];
      final outcome = await journal.drain(
        projectId: 'proj-1',
        remote: <String, Object?>{'title': 'Theirs'},
        apply: (merged) async => appliedMerges.add(merged),
      );

      expect(outcome.applied, 0);
      expect(outcome.conflictKeys, <String>{'title'});
      expect(outcome.remaining, 1);
      expect(appliedMerges, isEmpty);
      expect(await journal.pending('proj-1'), hasLength(1));
    },
  );

  test(
    'corrupt journal entries are quarantined, never silently dropped',
    () async {
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}'
        'sync_authority_journal_proj-9.jsonl',
      );
      await file.writeAsString(
        '{not json\n'
        '{"schema":1,"id":"a","projectId":"proj-9","authority":"cloud",'
        '"reason":"r","local":{"k":1},'
        '"createdAt":"2026-09-04T00:00:00.000Z"}',
      );

      final entries = await journal.pending('proj-9');

      expect(entries, hasLength(1));
      expect(entries.single.local, <String, Object?>{'k': 1});
      expect(await journal.quarantined('proj-9'), 1);
      expect(await file.readAsString(), contains('{not json'));
    },
  );
}
