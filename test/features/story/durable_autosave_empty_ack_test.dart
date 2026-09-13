// vs-hunt-20260912-autosave BUG-4 (Referee: REAL, Medium).
//
// saveNow branch konten-kosong melakukan acknowledge BLIND (unconditional)
// setelah persist sukses. Saat _persist("") await, pengguna mengetik teks
// baru untuk scene yang SAMA -> stage jurnal terpasang; ack butuh menghapus
// entri yang belum pernah di-persist = hilangnya jaring pengaman durable
// (crash sebelum debounce berikutnya = teks hilang, exactly the silent loss
// the non-empty branch guards against with content-aware ack).
//
// Kontrak perbaikan: unconditional ack HANYA bila pending masih persis
// transisi kosong yang baru disimpan (tidak ada penggantian selama await);
// bila tergantikan, entri jurnal baru DIPERTAHANKAN dan autosave berikutnya
// yang menyimpannya. Kontrak run128 BUG-2 (delete-all lama tak boleh
// menghidupkan teks terhapus) tetap: tanpa penggantian, entri lama dihapus.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';

void main() {
  late Directory root;
  late Directory journalDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('run256b-empty-ack-');
    journalDir = Directory('${root.path}/journal');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
  });

  test('delete-all with no replacement still clears the stale entry '
      '(run128 BUG-2 contract preserved)', () async {
    final journal = DurableDraftJournal(dir: journalDir);
    final persisted = <String, String>{};
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(days: 1),
      persist: (sceneId, content) async => persisted[sceneId] = content,
      journal: journal,
    );

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'teks lama');
    await coordinator.saveNow();
    // Simulasi entri STALE warisan (bug-hunt-run128 BUG-2): jurnal masih
    // memuat teks lama sementara draf aktif kini kosong.
    await journal.stage(sceneId: 'scene-a', content: 'teks lama');
    expect(await journal.pendingEntries(), hasLength(1));

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: '');
    await coordinator.saveNow();
    expect(persisted['scene-a'], '');
    expect(
      await journal.pendingEntries(),
      isEmpty,
      reason: 'delete-all tanpa penggantian WAJIB menghapus entri lama',
    );
    await coordinator.dispose();
  });

  test('delete-all whose persist is interrupted by a newer keystroke keeps '
      'the newer journal entry (BUG-4)', () async {
    final journal = DurableDraftJournal(dir: journalDir);
    final gate = Completer<void>();
    final persisted = <String, String>{};
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(days: 1),
      persist: (sceneId, content) async {
        if (content.trim().isEmpty) await gate.future;
        persisted[sceneId] = content;
      },
      journal: journal,
    );

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'teks lama');
    await coordinator.saveNow();
    // Entri STALE 'teks lama' masih tertinggal di jurnal (kondisi nyata
    // saat save teks-lama belum sempat ack / persist baru berjalan).
    await journal.stage(sceneId: 'scene-a', content: 'teks lama');
    expect(await journal.pendingEntries(), hasLength(1));

    // Trigger delete-all; persist-nya tertahan.
    await coordinator.onDraftChanged(sceneId: 'scene-a', content: '');
    final emptyFlush = coordinator.saveNow();
    // SAAT await persist kosong berjalan, user mengetik teks baru:
    // stage jurnal 'terselamatkan' terpasang menggantikan pending.
    await coordinator.onDraftChanged(
      sceneId: 'scene-a',
      content: 'terselamatkan',
    );
    gate.complete();
    await emptyFlush;

    final pending = await journal.pendingEntries();
    expect(
      pending.map((e) => e.content),
      contains('terselamatkan'),
      reason:
          'BUG-4: ack unconditional pada cabang kosong menghapus entri '
          'yang digantikan selama persist await (silent loss)',
    );

    // Autosave berikutnya menyimpan teks baru lalu bersih.
    await coordinator.saveNow();
    expect(persisted['scene-a'], 'terselamatkan');
    expect(await journal.pendingEntries(), isEmpty);
    await coordinator.dispose();
  });
}
