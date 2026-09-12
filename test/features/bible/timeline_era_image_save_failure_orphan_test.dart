import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/bible/application/bible_timeline_repository.dart';
import 'package:void_scriptor/features/bible/application/timeline_era_image_importer.dart';
import 'package:void_scriptor/features/bible/domain/timeline_era.dart';

/// vs-hunt-20260913-importer BUG-3 (Medium, Referee REAL):
/// [TimelineEraImageImporter.importFromFile] menyalin berkas ke namespace
/// `era_images` SEBELUM `repo.saveEra`; bila save gagal, salinan tertinggal
/// yatim sementara baris era tetap menunjuk keadaan lama. Pola cacat dan fix
/// sama dengan faction importer (vs-hunt-20260913-bible BUG-4 / commit
/// 2a55bd7). Injeksi kegagalan: trigger BEFORE INSERT RAISE(ABORT) — SELECT
/// tetap jalan, insert/update gagal. Fixture temporer, bukan data user.
void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  test('era image importer removes the copied file when the era save fails '
      '(vs-hunt-20260913-importer BUG-3)', () async {
    final dir = await Directory.systemTemp.createTemp('era-orphan-');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));
    addTearDown(db.close);

    final repo = BibleTimelineRepository(db);
    await repo.saveEra(
      const TimelineEraModel(
        id: 'era-orphan-1',
        projectId: 'project-1',
        name: 'Fractured Age',
        orderIndex: 0,
        imagePath: 'C:/pkg/assets/era_images/old.png',
      ),
    );

    final source = File(p.join(dir.path, 'art.png'))
      ..writeAsBytesSync(pngBytes);
    final assetsDir = Directory(p.join(dir.path, 'assets'))
      ..createSync(recursive: true);

    // Era bisa dibaca (lolos validasi listErasById), insert apa pun gagal
    // sehingga saveEra (insertOnConflictUpdate) melempar.
    await db.customStatement(
      'CREATE TRIGGER inject_era_save_failure BEFORE INSERT ON timeline_eras '
      "BEGIN SELECT RAISE(ABORT, 'injected save failure'); END",
    );

    Object? thrown;
    try {
      await TimelineEraImageImporter(
        database: db,
        assetsDirectory: assetsDir,
      ).importFromFile(eraId: 'era-orphan-1', sourcePath: source.path);
    } catch (error) {
      thrown = error;
    }
    expect(
      thrown,
      isNotNull,
      reason: 'save failure harus tetap menggagalkan import',
    );

    final leftovers = Directory(
      p.join(assetsDir.path, 'era_images'),
    ).listSync(recursive: true).whereType<File>().toList();
    expect(
      leftovers,
      isEmpty,
      reason:
          'salinan gagal-save harus dihapus rollback, bukan yatim: '
          '${leftovers.map((f) => f.path).toList()}',
    );

    // Baris era tetap menunjuk state lama.
    final rows = await repo.listErasById('era-orphan-1');
    expect(rows.single.imagePath, 'C:/pkg/assets/era_images/old.png');
  });
}
