// vs-hunt-20260912-autosave BUG-2 (Referee: REAL, Critical) — sisi KOORDINATOR.
//
// onDraftChanged lama await jurnal SEBELUM memasang _pending dan melaporkan
// onPersistError TANPA mengecek apakah kontennya masih draf aktif; caller
// layar fire-and-forget (story_workspace_screen.dart:322), sehingga edit
// lama yang stage-nya selesai belakangan dapat (a) menimpa pending dengan
// konten lama dan (b) memunculkan banner error untuk teks yang sudah
// digantikan — membingungkan indikator "Gagal menyimpan draf" (kontrak
// no-silent-loss kelas ini, baris 10-18).
//
// Kontrak perbaikan (HANYA di koordinator; file jurnal dimiliki eksekutor
// lain untuk BUG-1/sisi-jurnal BUG-2 — lihat diff sibling yang berjalan):
// 1. State pending dipasang SEKETIKA (sinkron, sebelum await apa pun);
//    panggilan terakhir selalu menang berapa pun urutan penyelesaian I/O;
// 2. onPersistError cuman dipanggil bila panggilan itu masih menjadi draf
//    AKTIF saat kegagalan terjadi (guard generasi + scene + konten);
// 3. Debounce tetap dijadwalkan SETELAH stage jurnal tuntas (kontrak
//    run128 BUG-2 / 145.30 "journal before schedule" dipertahankan).
//
// deterministic interleaving: jurnal CLOSED => stage() melempar StateError
// dengan cepat, antrean microtask membuat urutan kedua panggilan terbukti.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/application/durable_autosave_coordinator.dart';

void main() {
  late Directory root;
  late Directory journalDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('run255-pending-order-');
    journalDir = Directory('${root.path}/journal');
    await journalDir.create(recursive: true);
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
  });

  test('pending state is set synchronously: a superseded keystroke does not '
      'report an error for the replaced draft (BUG-2)', () async {
    final journal = DurableDraftJournal(dir: journalDir);
    await journal.close(); // stage() apa pun -> StateError terantre

    final reported = <String>[];
    final persistOrder = <String>[];
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(days: 1),
      persist: (sceneId, content) async {
        persistOrder.add(content);
      },
      journal: journal,
      onPersistError: (sceneId, content, error) => reported.add(content),
    );

    // Dua fire-and-forget persis pola layar: 'lama' lalu 'baru' (sinkron,
    // sebelum microtask call1 stage-error resume).
    final older = coordinator.onDraftChanged(
      sceneId: 'scene-a',
      content: 'lama',
    );
    final newer = coordinator.onDraftChanged(
      sceneId: 'scene-a',
      content: 'baru',
    );
    await older;
    await newer;

    // Kode lama: KEDUA kegagalan dilaporkan (pending sempat jatuh ke
    // 'lama' lalu 'baru' -> banner error basi). Kode baru: hanya yang
    // masih aktif ('baru') yang boleh melapor.
    expect(
      reported,
      ['baru'],
      reason:
          'BUG-2: kegagalan stage untuk konten yang sudah digantikan tidak '
          'boleh dilaporkan sebagai error draf aktif',
    );

    // Pending draf akhir HARUS konten panggilan terakhir.
    await coordinator.saveNow();
    expect(persistOrder, [
      'baru',
    ], reason: 'draf aktif = keystroke terakhir, bukan stage lama');
    await coordinator.dispose();
  });

  test('a failure for the ACTIVE draft is still reported (run128 BUG-2 '
      'contract preserved)', () async {
    final journal = DurableDraftJournal(dir: journalDir);
    await journal.close();

    final reported = <Object>[];
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(days: 1),
      persist: (sceneId, content) async {},
      journal: journal,
      onPersistError: (sceneId, content, error) => reported.add(content),
    );

    await coordinator.onDraftChanged(sceneId: 'scene-a', content: 'aktif');
    expect(reported, ['aktif'], reason: 'error draf aktif wajib terlihat');
    // Autosave tetap dijadwalkan meski stage gagal (no silent loss:
    // persist tetap dicoba).
    await coordinator.saveNow();
    await coordinator.dispose();
  });

  test('empty-content transition stages nothing and reports nothing', () async {
    final journal = DurableDraftJournal(dir: journalDir);
    await journal.close();
    final reported = <Object>[];
    final coordinator = DurableAutosaveCoordinator(
      debounceDelay: const Duration(days: 1),
      persist: (sceneId, content) async {},
      journal: journal,
      onPersistError: (sceneId, content, error) => reported.add(content),
    );
    await coordinator.onDraftChanged(sceneId: 'scene-a', content: '   ');
    expect(reported, isEmpty); // kosong = transisi state, bukan error
    await coordinator.dispose();
  });
}
