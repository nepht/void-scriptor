import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/bible/application/faction_image_importer.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';

/// vs-hunt-20260913-bible BUG-4 (Low, Referee REAL conf High):
/// pada [FactionImageImporter.importFromFile], salinan berkas sudah written
/// sebelum `repo.save` — bila save gagal, salinan tertinggal sebagai yatim
/// di namespace `faction_images` sementara baris faksi tidak pernah menunjuknya.
/// Injeksi kegagalan: trigger BEFORE INSERT yang RAISE(ABORT) — SELECT tetap
/// jalan, hanya insert/update yang gagal. Fixture temporer, bukan data user.
void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  test('faction importer removes the copied file when the row save fails '
      '(vs-hunt-20260913-bible BUG-4)', () async {
    final dir = await Directory.systemTemp.createTemp('faction-orphan-');
    addTearDown(() async {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));
    addTearDown(db.close);

    final created = await const CreateFactionService().create(
      db,
      projectId: 'project-1',
      name: 'Broken Sigil',
    );

    final source = File(p.join(dir.path, 'sigil.png'))
      ..writeAsBytesSync(pngBytes);
    final assetsDir = Directory(p.join(dir.path, 'assets'))
      ..createSync(recursive: true);

    // Baris bisa dibaca (get lolos validasi), insert apa pun gagal.
    await db.customStatement(
      'CREATE TRIGGER inject_faction_save_failure BEFORE INSERT ON factions '
      'BEGIN SELECT RAISE(ABORT, \'injected save failure\'); END',
    );

    Object? thrown;
    try {
      await FactionImageImporter(
        database: db,
        assetsDirectory: assetsDir,
      ).importFromFile(assetId: created.assetId, sourcePath: source.path);
    } catch (error) {
      thrown = error;
    }
    expect(
      thrown,
      isNotNull,
      reason: 'save failure harus tetap menggagalkan import',
    );

    // Tidak ada berkas yatim yang tertinggal di namespace faction_images.
    final leftovers = Directory(
      p.join(assetsDir.path, 'faction_images'),
    ).listSync(recursive: true).whereType<File>().toList();
    expect(
      leftovers,
      isEmpty,
      reason:
          'salinan gagal-save harus dihapus rollback, bukan yatim: '
          '${leftovers.map((f) => f.path).toList()}',
    );

    // Baris faksi tetap menunjuk state lama (imagePath kosong).
    expect((await FactionRepository(db).get(created.assetId))!.imagePath, '');
  });
}
