// vs-hunt-20260912-autosave BUG-1 (Referee: REAL BUG, Critical) — sisi JURNAL.
// Bug-hunt lama menyebut determinisme `.tmp` per scene (run128 BUG-1/3) tapi
// tidak pernah menutup tabrakan dua stage() paralel untuk scene yang sama:
// keduanya berbagi satu `<scene>.json.tmp`, sehingga sink writer kedua
// memotong file yang sedang ditulis/di-rename writer pertama. Probe HEAD
// sebelum fix: 7/15 putaran paralel (payload 300KB) melempar
// PathNotFoundException errno 2 pada rename — dan varian terburuknya (rename
// memindahkan sink setengah tulis) menghasilkan entri journal korup = draf
// pengguna TAK TERPULIHKAN (jalur terpanas: fire-and-forget dari layar).
//
// Kontrak perbaikan (HANDOFF_CRON_V4 A1; saran Referee: unique temp filename
// per panggilan):
// 1. stage() paralel untuk scene yang sama tidak ada yang melempar;
// 2. hasil akhir selalu tepat satu entri .json UTUH berisi salah satu versi;
// 3. tidak ada residu `.tmp` dari tabrakan itu sendiri;
// 4. artefak `.tmp` unik tetap dikenali sweep lama (suffix `.json.tmp`).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

/// Payload ~300 KB membuka lebar jendela tulis→rename pada HEAD rentan
/// (probe: 7/15 gagal); 10 putaran membuat RED praktis tak lolos. Setelah
/// fix, path temporer unik per panggilan membuat tabrakan mustahil sehingga
/// semua putaran hijau deterministik.
String _draft(String tag) => '${tag.substring(0, 1) * 300000} TAIL-$tag';

Future<void> _reset(Directory dir) async {
  for (final f in await dir.list().toList()) {
    if (f is File) await f.delete();
  }
}

void main() {
  late Directory root;
  late Directory dir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bug1-tmp-unique-');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    dir = Directory('${root.path}/journal');
    await dir.create(recursive: true);
  });

  test('concurrent stage() for the same scene never errors, corrupts, or '
      'leaves colliding .tmp residue (BUG-1)', () async {
    const rounds = 10;
    for (var round = 0; round < rounds; round++) {
      await _reset(dir);
      final journal = DurableDraftJournal(dir: dir);
      final v1 = _draft('A$round');
      final v2 = _draft('B$round');

      await Future.wait([
        journal.stage(sceneId: 'scene-a', content: v1),
        journal.stage(sceneId: 'scene-a', content: v2),
      ]);

      final pending = await journal.pendingEntries();
      expect(
        pending,
        hasLength(1),
        reason: 'round $round: exactly one recoverable entry',
      );
      expect(
        pending.single.isCorrupt,
        isFalse,
        reason: 'round $round: rename must never publish a half-written file',
      );
      expect(
        pending.single.content,
        anyOf(equals(v1), equals(v2)),
        reason: 'round $round: final is one whole version, never a splice',
      );
      final residues = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp'))
          .toList();
      expect(
        residues,
        isEmpty,
        reason: 'round $round: collision must not leave .tmp residue',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('parallel stages across scenes stay independent while same-scene '
      'writers never share a temp file (BUG-1)', () async {
    final journal = DurableDraftJournal(dir: dir);
    final a1 = _draft('A1');
    final a2 = _draft('A2');
    final b1 = _draft('B1');

    await Future.wait([
      journal.stage(sceneId: 'scene-a', content: a1),
      journal.stage(sceneId: 'scene-a', content: a2),
      journal.stage(sceneId: 'scene-b', content: b1),
    ]);

    final pending = await journal.pendingEntries();
    expect(pending, hasLength(2));
    final byScene = {for (final e in pending) e.sceneId: e};
    expect(byScene['scene-b']!.content, b1);
    expect(
      byScene['scene-a']!.content,
      anyOf(equals(a1), equals(a2)),
      reason: 'scene-a final = exactly one whole version',
    );
    expect(byScene.values.every((e) => !e.isCorrupt), isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a unique-suffixed .tmp orphan is still swept by the age-gated '
      'recovery sweep (run128 BUG-3 contract preserved)', () async {
    final journal = DurableDraftJournal(dir: dir);
    await journal.stage(sceneId: 'scene-ok', content: 'Draf valid utuh.');

    // Orphan dari pola penamaan baru (writer mati setelah flush, sebelum
    // rename) — suffix .json.tmp harus tetap dikenali sweep.
    final orphan = File('${dir.path}/scene-crash.abc123.7.json.tmp');
    await orphan.writeAsString('{"sceneId":"scene-crash","content":"potongan');
    await orphan.setLastModified(
      DateTime.now().subtract(const Duration(hours: 1)),
    );

    final pending = await journal.pendingEntries();
    expect(pending, hasLength(1));
    expect(pending.single.sceneId, 'scene-ok');
    expect(orphan.existsSync(), isFalse, reason: 'stale .tmp must be swept');
  });
}
