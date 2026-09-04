// Prioritas Core 2026-09-04 (kontrak Step 145.30 no-silent-loss):
// kegagalan persist autosave TIDAK boleh silent. Saat persist gagal
// (debounce atau flush dispose), koordinator wajib melaporkan kegagalan
// lewat onPersistError, mempertahankan draf pending + entri journal
// durable (dapat di-retry / dipulihkan), dan tidak melempar uncaught
// exception.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';

void main() {
  late Directory tempRoot;
  late Directory journalDir;
  late DurableDraftJournal journal;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-npe-');
    journalDir = Directory('${tempRoot.path}/recovery/draft-journal');
    await journalDir.create(recursive: true);
    journal = DurableDraftJournal(dir: journalDir);
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  test('persist failure reports onPersistError and keeps pending draft '
      'plus durable journal entry', () async {
    final failedScenes = <String>[];
    final coordinator = DurableAutosaveCoordinator(
      persist: (sceneId, content) async => throw StateError('disk penuh'),
      journal: journal,
      onPersistError: (sceneId, content, error) => failedScenes.add(sceneId),
    );

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'Draf A.');
    await coordinator.saveNow();

    expect(failedScenes, ['scene-a']);
    // No silent loss: draf tetap pending dan entri journal tetap ada.
    final pending = await journal.pendingEntries();
    expect(pending, hasLength(1));
    expect(pending.single.content, 'Draf A.');
    await coordinator.dispose();
  });

  test(
    'retry after a failure succeeds without a second error report',
    () async {
      var fail = true;
      var errorCount = 0;
      final coordinator = DurableAutosaveCoordinator(
        persist: (sceneId, content) async {
          if (fail) throw StateError('disk penuh');
        },
        journal: journal,
        onPersistError: (sceneId, content, error) => errorCount++,
      );

      await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'Draf A.');
      await coordinator.saveNow();
      expect(errorCount, 1);
      expect(await journal.pendingEntries(), hasLength(1));

      fail = false;
      await coordinator.saveNow();
      expect(errorCount, 1);
      expect(await journal.pendingEntries(), isEmpty);
      await coordinator.dispose();
    },
  );

  test('dispose flush keeps the failure visible instead of an uncaught '
      'error', () async {
    final failedScenes = <String>[];
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(seconds: 30),
      persist: (sceneId, content) async => throw StateError('gagal flush'),
      journal: journal,
      onPersistError: (sceneId, content, error) => failedScenes.add(sceneId),
    );

    await coordinator.onDraftChanged(sceneId: 'scene-b', content: 'Draf B.');
    await coordinator.dispose();

    expect(failedScenes, ['scene-b']);
    expect(await journal.pendingEntries(), hasLength(1));
  });
}
