// Bug-hunt-run128 BUG-3 (Referee: REAL BUG, Low): file `<scene>.json.tmp`
// yang selesai ditulis namun mati sebelum rename() (crash/power-loss di
// jendela tulis) menjadi orphan selamanya - `pendingEntries()` mengabaikan
// semua `.tmp`, `acknowledge()` hanya menghapus `<scene>.json`, dan tidak
// ada sweep di lib/. Pertumbuhannya lambat tapi tidak terbatas dan tidak
// pernah dipulihkan ruangnya.
//
// Kontrak slice ini (145.30 hygiene, no-silent-loss tetap utama):
// 1. `.tmp` STALE (umur melewati ambang jauh di atas jendela tulis
//    milidetik) disapu best-effort di jalur baca pemulihan
//    `pendingEntries()`;
// 2. `.tmp` SEGAR (writer hidup di tengah jendela tulis) TIDAK PERNAH
//    disapu - menyapu tulisan in-progress akan melanggar no-silent-loss;
// 3. File final `.json` (valid maupun korup) tidak tersentuh sweep.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

void main() {
  test('stale .tmp orphan from a crashed writer is swept at recovery read '
      '(bug-hunt-run128 BUG-3)', () async {
    final root = await Directory.systemTemp.createTemp('hermes-bug3-sweep-');
    addTearDown(() => root.delete(recursive: true));
    final dir = Directory('${root.path}/journal');
    await dir.create(recursive: true);

    final journal = DurableDraftJournal(dir: dir);
    await journal.stage(sceneId: 'scene-ok', content: 'Draf valid utuh.');

    // Simulasi crash setelah flush namun sebelum rename: orphan .tmp
    // dari sesi sebelumnya (mtime dibackdate melewati ambang sweep).
    final orphan = File('${dir.path}/scene-crash.json.tmp');
    await orphan.writeAsString(
      '{"sceneId":"scene-crash","content":"selesai ditulis, gagal rename"}',
    );
    await orphan.setLastModified(
      DateTime.now().subtract(const Duration(hours: 1)),
    );

    final pending = await journal.pendingEntries();

    // Entri final valid tetap terpulihkan (sweep tidak menyentuh .json).
    expect(pending.map((e) => e.sceneId), contains('scene-ok'));
    expect(pending, hasLength(1));
    // BUG-3: orphan stale disapu, tidak lagi menumpuk selamanya.
    expect(
      orphan.existsSync(),
      isFalse,
      reason: 'BUG-3: .tmp stale harus disapu di jalur baca pemulihan',
    );
  });

  test(
    'fresh in-flight .tmp is never swept (live writer window protected)',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-bug3-fresh-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      await dir.create(recursive: true);

      final journal = DurableDraftJournal(dir: dir);
      await journal.stage(sceneId: 'scene-ok', content: 'Draf valid utuh.');

      // .tmp segar dari writer hidup (umur jendela tulis ~milidetik):
      // TIDAK boleh disapu, karena stage() yang sedang berjalan akan
      // kehilangan tulisannya (no-silent-loss).
      final fresh = File('${dir.path}/scene-live.json.tmp');
      await fresh.writeAsString('{"sceneId":"scene-live","content":"menulis"}');

      final pending = await journal.pendingEntries();

      expect(
        fresh.existsSync(),
        isTrue,
        reason: 'jendela tulis writer hidup tidak boleh disapu',
      );
      // .tmp tidak pernah menjadi sumber entri; hanya entri final yang
      // terpulihkan.
      expect(pending, hasLength(1));
      expect(pending.single.sceneId, 'scene-ok');
    },
  );
}
