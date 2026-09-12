import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/application/asset_thumbnail_importer.dart';

/// vs-hunt-20260913-importer BUG-4 (Medium, Referee REAL):
/// [AssetThumbnailImporter.importFromFile] menyalin berkas ke namespace
/// `asset_thumbnails` SEBELUM `assetDao.setThumbnail`; bila update gagal,
/// salinan tertinggal yatim sementara baris aset tetap menunjuk thumbnail
/// lama. Pola cacat sama dengan faction/era importer; fix mengikuti
/// konvensi rollback yang sudah ada (try/catch delete + rethrow).
/// Injeksi: trigger BEFORE UPDATE ON assets RAISE(ABORT) — SELECT lolos,
/// setThumbnail melempar. Fixture temporer, bukan data user.
void main() {
  test('thumbnail importer removes the copied file when the row update fails '
      '(vs-hunt-20260913-importer BUG-4)', () async {
    final dir = await Directory.systemTemp.createTemp('thumb-orphan-');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    final database = ProjectDatabase(
      NativeDatabase(File(p.join(dir.path, 'project.db'))),
    );
    addTearDown(database.close);

    await database.assetDao.createStandaloneAsset(
      id: 'asset-orphan-1',
      projectId: 'project-1',
      name: 'Quiet Lantern',
      type: 'creature',
      now: DateTime(2026),
    );

    final sourceDir = Directory(p.join(dir.path, 'src'))
      ..createSync(recursive: true);
    final source = File(p.join(sourceDir.path, 'lantern.png'))
      ..writeAsBytesSync([1, 2, 3, 4]);
    final assetsDir = Directory(p.join(dir.path, 'assets'))
      ..createSync(recursive: true);

    await database.customStatement(
      'CREATE TRIGGER inject_thumb_update_failure BEFORE UPDATE ON assets '
      "BEGIN SELECT RAISE(ABORT, 'injected update failure'); END",
    );

    Object? thrown;
    try {
      await AssetThumbnailImporter(
        database: database,
        assetsDirectory: assetsDir,
      ).importFromFile(assetId: 'asset-orphan-1', sourcePath: source.path);
    } catch (error) {
      thrown = error;
    }
    expect(
      thrown,
      isNotNull,
      reason: 'setThumbnail failure harus tetap menggagalkan import',
    );

    final leftovers = Directory(
      p.join(assetsDir.path, 'asset_thumbnails'),
    ).listSync(recursive: true).whereType<File>().toList();
    expect(
      leftovers,
      isEmpty,
      reason:
          'salinan gagal-update harus dihapus rollback, bukan yatim: '
          '${leftovers.map((f) => f.path).toList()}',
    );

    // Baris aset tetap tanpa thumbnail (keadaan lama utuh).
    final row = await database.assetDao.getById('asset-orphan-1');
    expect(row?.thumbnailPath, isNull);
  });
}
