import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';

void main() {
  test('interrupted stage leaves a tmp orphan that must not mask the last '
      'valid draft (no silent loss on pending replay)', () async {
    final root = await Directory.systemTemp.createTemp('hermes-s30-fail-');
    addTearDown(() => root.delete(recursive: true));
    final dir = Directory('${root.path}/novel-1');
    await dir.create(recursive: true);

    final journal = DurableDraftJournal(dir: dir);
    await journal.stage(sceneId: 'scene-a', content: 'Draf valid pertama.');

    // Simulasi crash setelah flush namun sebelum rename: tinggalkan
    // file <scene>.json.tmp setengah jadi di direktori.
    final orphan = File('${dir.path}/scene-a.json.tmp');
    await orphan.writeAsString('{"sceneId":"scene-a","content":"potongan');

    // pendingEntries harus mengabaikan .tmp dan tetap memulihkan draf
    // valid terakhir - file .tmp tidak boleh menutupinya.
    final pending = await journal.pendingEntries();
    expect(pending, hasLength(1));
    expect(pending.single.sceneId, 'scene-a');
    expect(pending.single.content, 'Draf valid pertama.');
  });

  test('stage propagates a write failure and keeps the previous valid draft '
      'recoverable', () async {
    final root = await Directory.systemTemp.createTemp('hermes-s30-fail2-');
    addTearDown(() => root.delete(recursive: true));
    final dir = Directory('${root.path}/novel-2');
    await dir.create(recursive: true);

    final journal = DurableDraftJournal(dir: dir);
    await journal.stage(sceneId: 'scene-a', content: 'Versi tersimpan.');

    // Simulasi disk/permission failure secara deterministik lintas
    // platform: jadikan path target .tmp sebuah direktori sehingga
    // openWrite pada path itu gagal (FileSystemException).
    await Directory('${dir.path}/scene-a.json.tmp').create();

    await expectLater(
      journal.stage(sceneId: 'scene-a', content: 'Versi gagal tulis.'),
      throwsA(isA<FileSystemException>()),
    );

    // Versi lama harus tetap bisa dipulihkan - failure tidak menghapus
    // atau menimpa draf yang sebelumnya valid.
    final pending = await journal.pendingEntries();
    expect(pending, hasLength(1));
    expect(pending.single.content, 'Versi tersimpan.');
  });
}
