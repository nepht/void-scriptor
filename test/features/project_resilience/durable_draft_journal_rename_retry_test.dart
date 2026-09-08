import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

/// Temuan rerun146: autosave scene gagal dengan PathAccessException errno 32
/// pada rename `draft-journal/<sceneId>.json.tmp` di `DurableDraftJournal.stage`
/// (`temp.rename(...)`); retry manual selalu berhasil — ciri kegagalan
/// transien Windows ERROR_SHARING_VIOLATION (errno 32) / ERROR_ACCESS_DENIED
/// (errno 5) ketika handle eksternal sesaat (antivirus/indexer/sync client)
/// memegang file tanpa FILE_SHARE_DELETE sehingga MoveFileEx gagal.
///
/// Reproduksi deterministik di sini menahan handle pembaca Dart pada file
/// final `.json` (sisi target rename) — site MoveFileEx yang sama dengan
/// temuan field: `temp.rename()` gagal errno 5/32. Dart membuka file tanpa
/// FILE_SHARE_DELETE, jadi rename penimpaan file tersebut gagal deterministik.
///
/// POSIX melepas rename atas file yang sedang terbuka (unlink semantics),
/// sehingga uji mekanisme hanya bermakna di Windows; di runner lain mereka
/// di-skip dengan alasan eksplisit.
void main() {
  test(
    'stage survives a transient external handle on the final json during rename (run146)',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-run146-dst-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory(p.join(root.path, 'novel-b'))
        ..createSync(recursive: true);
      final journal = DurableDraftJournal(dir: dir);

      await journal.stage(sceneId: 'scene-b', content: 'versi 1');
      final finalPath = p.join(dir.path, 'scene-b.json');
      final raf = await File(finalPath).open(mode: FileMode.read);
      // Handle dilepas ~100ms kemudian: ladder retry 10+20+40+80ms harus
      // menemukan jendela setelah handle lepas dan rename berhasil.
      final release = () async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await raf.close();
      }();
      try {
        await journal.stage(sceneId: 'scene-b', content: 'versi 2');
      } finally {
        await release;
      }

      final pending = await journal.pendingEntries();
      expect(pending, hasLength(1));
      expect(pending.single.content, 'versi 2');
    },
    skip: !Platform.isWindows
        ? 'mekanisme sharing violation rename hanya ada di Windows'
        : null,
  );

  test(
    'stage still fails loudly when the handle outlives the bounded retry ladder',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-run146-stk-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory(p.join(root.path, 'novel-c'))
        ..createSync(recursive: true);
      final journal = DurableDraftJournal(dir: dir);

      await journal.stage(sceneId: 'scene-stuck', content: 'versi 1');
      final finalPath = p.join(dir.path, 'scene-stuck.json');
      final raf = await File(finalPath).open(mode: FileMode.read);
      try {
        // Handle tidak pernah dilepas: retry harus terbatas, lalu kegagalan
        // dilempar ulang (no silent-fabrication); onPersistError lapisan UI
        // tetap menampilkan kegagalan persisten seperti sebelumnya.
        await expectLater(
          journal.stage(sceneId: 'scene-stuck', content: 'versi 2'),
          throwsA(
            isA<FileSystemException>().having(
              (error) => error.osError?.errorCode,
              'osError.errorCode',
              anyOf(5, 32),
            ),
          ),
        );
        // Tidak ada pemulihan palsu: konten final tidak pernah ditimpa.
        expect(await File(finalPath).readAsString(), contains('versi 1'));
      } finally {
        await raf.close();
      }
    },
    skip: !Platform.isWindows
        ? 'mekanisme sharing violation rename hanya ada di Windows'
        : null,
  );
}
