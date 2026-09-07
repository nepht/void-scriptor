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

  // Regression bug-hunt-run128 BUG-2 (REAL BUG, Medium): delete-all
  // keystroke (konten kosong) dilempar ArgumentError oleh journal.stage()
  // dan lolos tanpa tertangkap melalui rantai onDraftChanged yang
  // fire-and-forget di layar. Secara rutin memicu uncaught async exception
  // pada jalur terpanas pengguna dan melompati penjadwalan autosave.
  // Kontrak yang benar: konten kosong adalah transisi state — draf pending
  // kosong boleh dijadwalkan dan di-persist, journal durable TIDAK
  // di-stage (kosong bukan draf yang perlu dipulihkan), tanpa lemparan.
  test('blank delete-all keystroke is a state transition, not an error '
      '(bug-hunt-run128 BUG-2)', () async {
    final persisted = <String, String>{};
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(milliseconds: 10),
      persist: (sceneId, content) async => persisted[sceneId] = content,
      journal: journal,
    );

    // Delete-all: select-all + delete mengirim '' ke onChanged.
    await coordinator.onDraftChanged(sceneId: 'scene-a', content: '');

    // Tidak ada uncaught ArgumentError; autosave dijadwalkan dan draf
    // kosong TETAP di-persist (konsisten dengan persist normal).
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(persisted['scene-a'], '');

    // Journal durable tidak di-stage untuk konten kosong (tidak ada
    // yang perlu dipulihkan), tapi kekosongan tidak merusak state.
    expect(await journal.pendingEntries(), isEmpty);
    await coordinator.dispose();
  });

  // BUG-2 companion: kegagalan journal.stage() (disk penuh/permission)
  // TIDAK boleh lolos sebagai uncaught async error melalui rantai
  // fire-and-forget. Kontrak: kegagalan dilaporkan via onPersistError
  // (layar menampilkan banner 'Gagal menyimpan draf'), draf tetap pending,
  // autosave tetap dijadwalkan, dan draf valid sebelumnya di journal
  // tidak tersentuh. Pembersihan .tmp tersendat adalah best-effort
  // senyap (failure-injection test journal yang ada sudah memverifikasi
  // bahwa draf valid lama tetap dipulihkan melewatinya).
  test('journal stage failure is reported, never escapes uncaught '
      '(bug-hunt-run128 BUG-2)', () async {
    // Draf valid sebelumnya di journal.
    await journal.stage(sceneId: 'scene-a', content: 'Draf valid lama.');
    // Buat target .tmp jadi direktori → stage() gagal deterministik
    // (FileSystemException, pola failure-injection journal).
    await Directory('${journalDir.path}/scene-a.json.tmp').create();
    var persistCalled = 0;
    Object? reportedError;
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(milliseconds: 10),
      persist: (sceneId, content) async => persistCalled++,
      journal: journal,
      onPersistError: (sceneId, content, error) => reportedError = error,
    );

    // onDraftChanged selesai TANPA melempar meski journal gagal.
    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'Draf.');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(reportedError, isA<FileSystemException>());
    expect(persistCalled, 1, reason: 'autosave tetap dijadwalkan');
    // Draf valid lama tidak tersentuh oleh kegagalan stage.
    expect(
      (await journal.pendingEntries()).map((e) => e.content),
      contains('Draf valid lama.'),
    );
    // Best-effort cleanup senyap: penghapusan .tmp gagal tanpa efek.
    expect(
      Directory('${journalDir.path}/scene-a.json.tmp').existsSync(),
      isTrue,
    );
    await coordinator.dispose();
  });

  // Regression bug-hunt-run128 BUG-8 (REAL BUG, Medium): konten yang
  // diketik SAAT save in-flight untuk scene yang sama sebelumnya hilang
  // diam-diam — acknowledge butuh-konten menghapus entri journal v2, dan
  // clear-pending butuh-konten membuang draf v2 di memori.
  test('content typed during an in-flight save of the SAME scene survives '
      '(bug-hunt-run128 BUG-8)', () async {
    final persisted = <String, String>{};
    final first = Completer<void>();
    final coordinator = DurableAutosaveCoordinator(
      // Debounce sangat panjang: satu-satunya save v2 terjadi lewat
      // saveNow eksplisit, jadi asersi antara tidak balapan dengan timer.
      debounceDelay: const Duration(seconds: 30),
      persist: (sceneId, content) async {
        persisted[sceneId] = content;
        if (content == 'v1') await first.future;
      },
      journal: journal,
    );

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'v1');
    final flushing = coordinator.saveNow();
    // Persis saat persist v1 berjalan, pengguna mengetik v2 di scene sama.
    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'v2');
    first.complete();
    await flushing;

    // Setelah save v1 selesai: journal durable HARUS masih berisi v2
    // (acknowledge content-aware) — v2 belum pernah di-persist.
    final afterFirst = await journal.pendingEntries();
    expect(
      afterFirst.map((e) => e.content),
      contains('v2'),
      reason:
          'acknowledge butuh-konten menjatuhkan entri v2 yang belum '
          'pernah di-persist (silent loss)',
    );

    // v2 harus tetap tersimpan pada flush berikutnya, lalu journal bersih.
    await coordinator.saveNow();
    expect(persisted['scene-a'], 'v2');
    expect(await journal.pendingEntries(), isEmpty);
    await coordinator.dispose();
  });
}
