// vs-hunt-20260913-importer BUG-5 (Low, Referee REAL): mid-batch failure di
// ReferenceBulkImporter menunggalkan salinan gambar yatim di namespace
// `assets/references/<assetId>/` karena writeAsBytes terjadi SEBELUM
// insertReference dan tidak ada rollback. Injeksi kegagalan: trigger
// BEFORE INSERT RAISE(ABORT) pada tabel references — SELECT tetap jalan,
// insert gagal. Fixture temporer, bukan data user. Pola fix mengikuti
// faction/timeline-era/thumbnail importer (2a55bd7 / 06a3a3f).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/references/application/reference_bulk_importer.dart';

void main() {
  test('bulk reference import removes copied files when the reference row '
      'insert fails (vs-hunt-20260913-importer BUG-5)', () async {
    final tempRoot = await Directory.systemTemp.createTemp('bulk-ref-orphan-');
    addTearDown(() async {
      try {
        await tempRoot.delete(recursive: true);
      } catch (_) {}
    });
    final assetsDir = Directory(p.join(tempRoot.path, 'assets'));
    final dbPath = p.join(tempRoot.path, 'project.db');
    await ProjectDatabaseService().create(dbPath);
    final database = await ProjectDatabaseService().open(dbPath);
    addTearDown(database.close);

    await database.assetDao.createStandaloneAsset(
      id: 'a-aurivy',
      projectId: 'p',
      name: 'Aurivy',
      type: 'creature',
      now: DateTime.utc(2026, 9, 13),
    );

    final imageFolder = Directory(p.join(tempRoot.path, 'images', 'Aurivy'))
      ..createSync(recursive: true);
    // Bytes meng-embed nama file agar hash tiap gambar berbeda (fixtur
    // derived-length pernah bertabrakan dan diam-diam kena dedup).
    for (final name in ['a-first.png', 'b-second.png']) {
      File(
        p.join(imageFolder.path, name),
      ).writeAsBytesSync([1, 2, 3, ...name.codeUnits]);
    }

    // Gambar bisa dibaca (byContentHash SELECT lolos); insert baris gagal.
    // Nama tabel `references` adalah reserved keyword SQLite — wajib quoted.
    await database.customStatement(
      'CREATE TRIGGER inject_reference_save_failure BEFORE INSERT ON '
      '"references" '
      "BEGIN SELECT RAISE(ABORT, 'injected reference insert failure'); END",
    );

    Object? thrown;
    try {
      await ReferenceBulkImporter(
        database: database,
        assetsDirectory: assetsDir,
        projectId: 'p',
      ).importFromFolder(root: Directory(p.join(tempRoot.path, 'images')));
    } catch (error) {
      thrown = error;
    }
    expect(
      thrown,
      isNotNull,
      reason: 'kegagalan insert harus tetap menggagalkan import',
    );

    final namespace = Directory(
      p.join(assetsDir.path, 'references', 'a-aurivy'),
    );
    final leftovers = namespace.existsSync()
        ? namespace.listSync(recursive: true).whereType<File>().toList()
        : const <File>[];
    expect(
      leftovers,
      isEmpty,
      reason:
          'salinan gagal-insert harus dihapus rollback, bukan yatim: '
          '$leftovers',
    );
  });
}
