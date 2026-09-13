// vs-hunt-20260912-autosave BUG-16 (Sisa C-block, run270).
//
// File jurnnal `<scene>.json` yang korup SELALU di-surface oleh
// pendingEntries() sebagai entri isCorrupt (kontrak no-silent-loss
// bug-hunt-run128 BUG-1), dan panel DRAFT RECOVERY menawarkan aksi
// "Buang" untuk entri itu. Aksi Buang memanggil acknowledge(sceneId)
// BLIND (content null = keputusan eksplisit pengguna).
//
// BUG-nya: acknowledge butakan catch "tidak terbaca/korup -> return"
// sehingga entri korup TIDAK PERNAH terhapus dari disk. UI menghapusnya
// dari daftar lokal, jadi entri hantu itu muncul kembali di sesi
// berikutnya — pengguna tidak pernah benar-benar bisa membuangnya, dan
// file residu menumpuk permanen di direktori journal.
//
// Kontrak perbaikan:
// 1. acknowledge BLIND (keputusan eksplisit pengguna) menghapus file
//    korup juga — pengguna sudah melihat peringatan dan memilih buang.
// 2. acknowledge CONTENT-AWARE (jalur autosave) tetap menolak menyentuh
//    file korup — tidak ada konten yang terbukti cocok, jadi entri
//    dipertahankan (jalur run257/BUG-6 tidak berubah).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

void main() {
  late Directory root;
  late Directory dir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-run270-corr-disc-');
    dir = Directory('${root.path}/journal');
    await dir.create(recursive: true);
    addTearDown(() async {
      try {
        await root.delete(recursive: true);
      } on FileSystemException {
        // Best-effort: file terkunci sesaat di Windows.
      }
    });
  });

  /// Tulis file final korup (JSON terpotong) seperti sisa crash window.
  Future<File> writeCorrupt(String sceneId) async {
    final file = File('${dir.path}/$sceneId.json');
    final full = jsonEncode(<String, Object?>{
      'sceneId': sceneId,
      'content': 'Teks yang terpotong karena crash saat menulis berkas',
      'stagedAt': DateTime(2026, 9, 13).toIso8601String(),
    });
    await file.writeAsString(full.substring(0, full.length ~/ 2));
    return file;
  }

  test(
    'blind acknowledge removes a corrupt journal file (user discard)',
    () async {
      final journal = DurableDraftJournal(dir: dir);
      final corruptFile = await writeCorrupt('scene-a');

      // Pra-kondisi: ter-surface sebagai korup (kontrak run128 BUG-1).
      final pending = await journal.pendingEntries();
      expect(pending.map((e) => e.sceneId), contains('scene-a'));
      expect(
        pending.firstWhere((e) => e.sceneId == 'scene-a').isCorrupt,
        isTrue,
      );

      // Aksi "Buang" dari panel: acknowledge blind (content null).
      await journal.acknowledge('scene-a');

      // RED: file korup masih ada di disk -> muncul lagi sesi depan.
      expect(
        await corruptFile.exists(),
        isFalse,
        reason:
            'keputusan eksplisit pengguna harus menghapus file korup; '
            'sebelumnya catch "korup -> return" membuat Buang tidak '
            'pernah efektif (entri hantu kembali setelah restart)',
      );
      final after = await journal.pendingEntries();
      expect(after.map((e) => e.sceneId), isNot(contains('scene-a')));
    },
  );

  test(
    'content-aware acknowledge still refuses to delete a corrupt file',
    () async {
      final journal = DurableDraftJournal(dir: dir);
      final corruptFile = await writeCorrupt('scene-b');

      // Jalur autosave: ack dengan konten — tidak ada kecocokan yang bisa
      // dibuktikan pada file tak terbaca, jadi entri WAJIB dipertahankan.
      await journal.acknowledge('scene-b', content: 'teks apa pun');

      expect(
        await corruptFile.exists(),
        isTrue,
        reason:
            'ack content-aware tidak boleh menghapus apa pun yang isinya '
            'tidak bisa diverifikasi (kontrak no-silent-loss tetap)',
      );
    },
  );

  test(
    'blind acknowledge of a valid entry is unchanged (regression pin)',
    () async {
      final journal = DurableDraftJournal(dir: dir);
      await journal.stage(sceneId: 'scene-ok', content: 'Draf utuh.');
      expect(await journal.pendingEntries(), hasLength(1));

      await journal.acknowledge('scene-ok');
      expect(await journal.pendingEntries(), isEmpty);
    },
  );
}
