// Bug-hunt-run128 BUG-1 (Referee: REAL BUG, Medium): pendingEntries()
// menelan entri journal <scene>.json final yang korup/truncated secara
// diam-diam (on FormatException continue) padahal file final itu satu-satunya
// salinan draf unsaved. Kontrak no-silent-loss 145.30: entri korup HARUS
// ter-surface (isCorrupt: true) agar panel DRAFT RECOVERY menampilkannya,
// bukan dibuang tanpa sinyal.
//
// Sesuai saran Referee: yang di-skip senyap HANYA .json.tmp (artefak
// tulis-in-progress); .json final korup di-surface.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

void main() {
  test(
    'truncated final journal entry is surfaced as corrupt, not silently dropped',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hermes-bug1-journal-',
      );
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      await dir.create(recursive: true);

      // Entri valid dari sesi sebelumnya.
      final journal = DurableDraftJournal(dir: dir);
      await journal.stage(sceneId: 'scene-ok', content: 'Draf utuh.');

      // Simulasi crash/power-loss: file FINAL scene-a terpotong di tengah
      // penulisan (satu-satunya salinan draf yang belum tersimpan).
      await File('${dir.path}/scene-a.json').writeAsString(
        jsonEncode(<String, Object?>{
          'sceneId': 'scene-a',
          'content': 'Teks yang terpotong karena cra',
        }).substring(0, 60),
      );

      final pending = await journal.pendingEntries();

      // Draf utuh tetap terpulihkan.
      expect(pending.map((e) => e.sceneId), contains('scene-ok'));
      // Entri korup TIDAK hilang diam-diam: ter-surface dengan isCorrupt.
      final corrupt = pending.where((e) => e.sceneId == 'scene-a').toList();
      expect(corrupt, hasLength(1), reason: 'BUG-1: entri korup harus visible');
      expect(corrupt.single.isCorrupt, isTrue);
      expect(corrupt.single.content, isEmpty);
    },
  );

  test(
    'structurally invalid final entry (valid JSON, missing fields) is also surfaced',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-bug1-jb-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      await dir.create(recursive: true);

      // JSON valid tetapi field sceneId/content hilang (korup semantik):
      // tidak dapat dipulihkan, tetapi tidak boleh hilang tanpa sinyal.
      await File('${dir.path}/scene-b.json').writeAsString('{"stagedAt": "x"}');

      final pending = await DurableDraftJournal(dir: dir).pendingEntries();

      expect(pending, hasLength(1));
      expect(pending.single.isCorrupt, isTrue);
      // sceneId diperkirakan dari nama file ketika isi tidak terbaca.
      expect(pending.single.sceneId, 'scene-b');
    },
  );

  test(
    'type-corrupt final entries do not abort the whole recovery listing (BUG-8 run197)',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-bug8-jt-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      await dir.create(recursive: true);
      final journal = DurableDraftJournal(dir: dir);

      // Sibling sehat yang HARUS tetap terpulihkan.
      await journal.stage(sceneId: 'scene-ok', content: 'Draf utuh.');

      // JSON valid tetapi tipe field salah: `as String?` melempar TypeError
      // (bukan FormatException). Satu file seperti ini tidak boleh
      // membutakan seluruh listing pemulihan (no silent loss).
      await File('${dir.path}/scene-int-id.json').writeAsString(
        jsonEncode(<String, Object?>{'sceneId': 123, 'content': 'teks'}),
      );
      // stagedAt non-String: melempar TypeError pada `as String? ?? ''`.
      await File('${dir.path}/scene-int-staged.json').writeAsString(
        jsonEncode(<String, Object?>{
          'sceneId': 'scene-int-staged',
          'content': 'teks',
          'stagedAt': 42,
        }),
      );
      // Root JSON bukan Map: TypeError pada `as Map<String, dynamic>`.
      await File('${dir.path}/scene-array.json').writeAsString('[1, 2, 3]');

      final pending = await journal.pendingEntries();

      // Listing tidak gagal: seluruh entri ter-surface.
      expect(
        pending.map((e) => e.sceneId),
        containsAll(<String>[
          'scene-ok',
          'scene-int-id',
          'scene-int-staged',
          'scene-array',
        ]),
      );
      // Sibling sehat tetap valid.
      final ok = pending.singleWhere((e) => e.sceneId == 'scene-ok');
      expect(ok.isCorrupt, isFalse);
      expect(ok.content, 'Draf utuh.');
      // Setiap entri korup tipe di-surface sebagai corrupt, tidak hilang.
      for (final id in const [
        'scene-int-id',
        'scene-int-staged',
        'scene-array',
      ]) {
        final entry = pending.singleWhere((e) => e.sceneId == id);
        expect(
          entry.isCorrupt,
          isTrue,
          reason: '$id harus visible sebagai korup',
        );
      }
    },
  );

  test('in-progress .tmp artifacts are never recovery sources', () async {
    final root = await Directory.systemTemp.createTemp('hermes-bug1-jc-');
    addTearDown(() => root.delete(recursive: true));
    final dir = Directory('${root.path}/journal');
    await dir.create(recursive: true);

    await File(
      '${dir.path}/scene-tmp.json.tmp',
    ).writeAsString('{"sceneId":"scene-tmp","content":"setengah jadi"}');

    final pending = await DurableDraftJournal(dir: dir).pendingEntries();

    expect(pending, isEmpty);
  });

  test(
    'valid entries are unaffected: no isCorrupt flag on decodable entries',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-bug1-jd-');
      addTearDown(() => root.delete(recursive: true));
      final dir = Directory('${root.path}/journal');
      await dir.create(recursive: true);
      final journal = DurableDraftJournal(dir: dir);
      await journal.stage(sceneId: 'scene-ok', content: 'Draf normal.');

      final pending = await journal.pendingEntries();

      expect(pending, hasLength(1));
      expect(pending.single.isCorrupt, isFalse);
      expect(pending.single.content, 'Draf normal.');
    },
  );
}
