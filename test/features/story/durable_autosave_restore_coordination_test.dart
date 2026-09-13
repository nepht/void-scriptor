// vs-hunt-20260912-autosave BUG-5 (Referee: REAL, Critical) — bukti regresi
// untuk `DurableAutosaveCoordinator.aroundExternalDraftWrite` (implementasi
// sibling di working tree; test ini menutup gap "belum diuji perilaku").
//
// restoreSceneDraftSnapshot MENGGANTIKAN konten draf dari luar jalur
// autosave. Tanpa koordinasi, draf yang masih menunggu debounce menimpa
// hasil restore secara diam-diam pada tick berikutnya (pending basi menang
// atas teks yang baru dipulihkan = silent loss arah sebaliknya).
//
// Kontrak yang dijamin:
// 1. pending scene SAMA di-flush SEBELUM write eksternal berjalan, sehingga
//    teks pengguna masuk DB lebih dulu (bahan cadangan pra-restore);
// 2. suntingan BARU yang datang selama write berjalan TIDAK dibuang —
//    itu intensi pengguna pasca-restore;
// 3. bila flush GAGAL (persist error), pending basi dibuang TANPA
//    acknowledge jurnal: entri jurnal adalah satu-satunya salinan teks itu
//    dan panel recovery tetap harus menampilkannya.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';

void main() {
  late Directory tempRoot;
  late Directory journalDir;
  late DurableDraftJournal journal;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('hermes-restore-coord-');
    journalDir = Directory('${tempRoot.path}/recovery/draft-journal');
    await journalDir.create(recursive: true);
    journal = DurableDraftJournal(dir: journalDir);
  });

  tearDown(() async {
    await journal.close();
    await tempRoot.delete(recursive: true);
  });

  // Debounce 5 menit: hanya flush eksplisit/aroundExternalDraftWrite yang
  // boleh memicu persist di dalam test.
  const noAutoDebounce = Duration(minutes: 5);

  test(
    'restore flushes the pending draft of the same scene BEFORE the write',
    () async {
      final order = <String>[];
      final db = <String, String>{};
      final coordinator = DurableAutosaveCoordinator(
        debounceDelay: noAutoDebounce,
        persist: (sceneId, content) async {
          order.add('persist:$content');
          db[sceneId] = content;
        },
        journal: journal,
      );

      await coordinator.onDraftChanged(
        sceneId: 'scene-1',
        content: 'teks-user',
      );
      final restored = await coordinator.aroundExternalDraftWrite(
        'scene-1',
        () async {
          order.add('restore-sees:${db['scene-1'] ?? '-'}');
          db['scene-1'] = 'teks-snapshot';
          return db['scene-1']!;
        },
      );

      // Urutan ketat: persist teks-user selesai SEBELUM restore membacakan DB.
      expect(order, ['persist:teks-user', 'restore-sees:teks-user']);
      expect(restored, 'teks-snapshot');
      // Pending terflush + ter-ack: tidak ada tulis susulan yang menimpa
      // hasil restore, dan jurnal bersih.
      expect(await journal.pendingEntries(), isEmpty);
      order.clear();
      await coordinator.saveNow();
      expect(order, isEmpty);
      expect(db['scene-1'], 'teks-snapshot');
      await coordinator.dispose();
    },
  );

  test(
    'edit typed WHILE the restore write runs survives as fresh pending',
    () async {
      final db = <String, String>{};
      final coordinator = DurableAutosaveCoordinator(
        debounceDelay: noAutoDebounce,
        persist: (sceneId, content) async {
          db[sceneId] = content;
        },
        journal: journal,
      );

      await coordinator.onDraftChanged(
        sceneId: 'scene-1',
        content: 'teks-user',
      );
      final result = await coordinator.aroundExternalDraftWrite(
        'scene-1',
        () async {
          // Suntingan datang SAAT write eksternal berjalan (pasca-restore).
          await coordinator.onDraftChanged(
            sceneId: 'scene-1',
            content: 'suntingan-baru',
          );
          return 'teks-snapshot';
        },
      );
      expect(result, 'teks-snapshot');
      // Flush lama sudah masuk DB; suntingan baru TIDAK boleh dibuang oleh
      // jalur pembuangan pending basi — ia tetap pending dan tersimpan nanti.
      expect(db['scene-1'], 'teks-user');
      await coordinator.saveNow();
      expect(db['scene-1'], 'suntingan-baru');
      await coordinator.dispose();
    },
  );

  test('failed flush discards stale pending WITHOUT acking the journal '
      '(the staged text stays recoverable)', () async {
    final persistErrors = <String>[];
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: noAutoDebounce,
      persist: (sceneId, content) async {
        throw const FileSystemException('disk penuh');
      },
      journal: journal,
      onPersistError: (sceneId, content, error) => persistErrors.add(content),
    );

    await coordinator.onDraftChanged(
      sceneId: 'scene-1',
      content: 'teks-hanya-di-jurnal',
    );
    final result = await coordinator.aroundExternalDraftWrite(
      'scene-1',
      () async => 'teks-snapshot',
    );

    expect(result, 'teks-snapshot');
    // Persist gagal → laporan error terdengar (BUKAN silent), pending basi
    // dibuang setelah write, dan entri jurnal TETAP ADA sebagai satu-\
    // satunya salinan teks user.
    expect(persistErrors, ['teks-hanya-di-jurnal']);
    final pending = await journal.pendingEntries();
    expect(pending, hasLength(1));
    expect(pending.single.content, 'teks-hanya-di-jurnal');
    // Pending sudah dilepas: flush susulan tidak menulis apa pun lagi.
    persistErrors.clear();
    await coordinator.saveNow();
    expect(persistErrors, isEmpty);
    await coordinator.dispose();
  });

  test(
    'restore of a DIFFERENT scene leaves the active pending untouched',
    () async {
      final db = <String, String>{};
      final coordinator = DurableAutosaveCoordinator(
        debounceDelay: noAutoDebounce,
        persist: (sceneId, content) async {
          db[sceneId] = content;
        },
        journal: journal,
      );

      await coordinator.onDraftChanged(sceneId: 'scene-1', content: 'teks-A');
      final result = await coordinator.aroundExternalDraftWrite(
        'scene-9',
        () async => 'teks-snapshot-9',
      );
      expect(result, 'teks-snapshot-9');
      // Tidak ada flush lintas-scene: pending scene-1 tetap utuh dan
      // tersimpan normal pada flush berikutnya.
      expect(db, isEmpty);
      await coordinator.saveNow();
      expect(db['scene-1'], 'teks-A');
      await coordinator.dispose();
    },
  );
}
