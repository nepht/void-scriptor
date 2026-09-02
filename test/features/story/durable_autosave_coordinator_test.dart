import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';

void main() {
  late Directory tempRoot;
  late Directory journalDir;
  late DurableDraftJournal journal;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-ndc-');
    journalDir = Directory('${tempRoot.path}/recovery/draft-journal');
    await journalDir.create(recursive: true);
    journal = DurableDraftJournal(dir: journalDir);
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  test('draft change stages the journal before the debounce fires '
      '(no silent-loss window)', () async {
    var persisted = 0;
    final coordinator = DurableAutosaveCoordinator(
      // Margin lebar (500ms) supaya asersi "belum tersimpan" tidak kalah
      // balapan dengan IO nyata kecil saat membaca journal.
      debounceDelay: const Duration(milliseconds: 500),
      persist: (sceneId, content) async => persisted++,
      journal: journal,
    );

    await coordinator.onDraftChanged(
      sceneId: 'scene-a',
      content: 'Draf terbaru.',
    );

    // Segera setelah perubahan, entri harus sudah ada di journal durable
    // meskipun debounce autosave belum jalan (crash tidak kehilangan draf).
    final pendingEarly = await journal.pendingEntries();
    expect(pendingEarly, hasLength(1));
    expect(pendingEarly.single.content, 'Draf terbaru.');
    expect(persisted, 0);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(persisted, 1);
    expect(await journal.pendingEntries(), isEmpty);
    await coordinator.dispose();
  });

  test(
    'flush persists and acknowledges in order then clears the journal',
    () async {
      final order = <String>[];
      var saved = 0;
      final coordinator = DurableAutosaveCoordinator(
        debounceDelay: const Duration(seconds: 1),
        persist: (sceneId, content) async {
          order.add('persist:$sceneId');
          saved++;
        },
        journal: journal,
      );

      await coordinator.onDraftChanged(
        sceneId: 'scene-a',
        content: 'Konten A.',
      );
      await coordinator.saveNow();

      // persist dijalankan SEBELUM acknowledge (no silent loss: entri dihapus
      // hanya setelah konten tersimpan durable).
      expect(order, ['persist:scene-a']);
      expect(await journal.pendingEntries(), isEmpty);
      expect(saved, 1);
      await coordinator.dispose();
    },
  );

  test('dispose flushes a pending draft instead of dropping it', () async {
    var persisted = 0;
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(seconds: 30),
      persist: (sceneId, content) async => persisted++,
      journal: journal,
    );

    await coordinator.onDraftChanged(
      sceneId: 'scene-a',
      content: 'Belum debounce.',
    );

    // Debounce masih jauh; dispose harus mem-flush (bukan membatalkan timer
    // dan membuang draf seperti DebouncedAutosave lama).
    await coordinator.dispose();

    expect(persisted, 1);
    expect(await journal.pendingEntries(), isEmpty);
  });

  test('a change arriving while a save is in flight is retried after the '
      'first save completes', () async {
    final journal = DurableDraftJournal(dir: journalDir);
    final first = Completer<void>();
    final persistedScenes = <String>[];
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(milliseconds: 10),
      persist: (sceneId, content) async {
        persistedScenes.add(sceneId);
        if (sceneId == 'scene-a') await first.future;
      },
      journal: journal,
    );

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'A.');
    final flushing = coordinator.saveNow();
    // Persis saat persist A masih berjalan, pengguna menyunting scene B.
    await coordinator.onDraftChanged(sceneId: 'scene-b', content: 'B.');

    first.complete();
    await flushing;
    // Beri waktu timer retry (reschedule) untuk menyimpan B.
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(persistedScenes, ['scene-a', 'scene-b']);
    expect(await journal.pendingEntries(), isEmpty);
    await coordinator.dispose();
  });

  test('no work happens when the draft has not changed', () async {
    var persisted = 0;
    final coordinator = DurableAutosaveCoordinator(
      persist: (sceneId, content) async => persisted++,
    );
    await coordinator.dispose();
    expect(persisted, 0);
  });
}
