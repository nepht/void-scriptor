// Reference bulk import (menu "terapkan semua" item C1, 2026-09-08): gambar
// referensi per karakter -> tabel references (galeri multi-gambar per aset),
// bukan menimpa thumbnail. Kontrak: salinan ke assets/references/<assetId>/,
// idempoten via content hash, gambar pertama (urut nama) primary + priority
// tertinggi, folder tak cocok/kosong dilaporkan seperti bulk thumbnail.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/references/application/reference_bulk_importer.dart';

void main() {
  late Directory tempRoot;
  late Directory assetsDir;
  late ProjectDatabase database;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('bulk-ref-');
    assetsDir = Directory('${tempRoot.path}/assets');
    final dbPath = '${tempRoot.path}/project.db';
    await ProjectDatabaseService().create(dbPath);
    database = await ProjectDatabaseService().open(dbPath);
  });

  tearDown(() async {
    await database.close();
    try {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> seedAsset(String id, String name) async {
    await database.assetDao.createStandaloneAsset(
      id: id,
      projectId: 'p',
      name: name,
      type: 'creature',
      now: DateTime.utc(2026, 9, 8),
    );
  }

  Future<Directory> folder(String name) async {
    final dir = Directory('${tempRoot.path}/images/$name');
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> writeImage(Directory dir, String fileName) async {
    final bytes = [1, 2, 3, ...fileName.codeUnits];
    File('${dir.path}/$fileName').writeAsBytesSync(bytes);
  }

  test('imports every image of a matched folder as references with primary '
      'first and copies them into the package', () async {
    await seedAsset('a-aurivy', 'Aurivy');
    final dir = await folder('Aurivy');
    await writeImage(dir, 'a-first.png');
    await writeImage(dir, 'b-second.jpg');
    await writeImage(dir, 'c-third.webp');
    await folder('face'); // tidak cocok ke aset mana pun

    final summary = await ReferenceBulkImporter(
      database: database,
      assetsDirectory: assetsDir,
      projectId: 'p',
    ).importFromFolder(root: Directory('${tempRoot.path}/images'));

    expect(summary.importedPerAsset.keys, ['a-aurivy']);
    expect(summary.importedPerAsset['a-aurivy'], 3);
    final refs = await database.referenceDao.list(
      projectId: 'p',
      ownerAssetId: 'a-aurivy',
    );
    expect(refs.length, 3);
    expect(
      refs.first.primaryReference,
      isTrue,
      reason: 'gambar pertama urut nama menjadi primary',
    );
    expect(refs.first.priority, greaterThan(refs.last.priority));
    expect(refs.every((r) => r.enabled), isTrue);
    for (final ref in refs) {
      expect(
        ref.filePath,
        startsWith(assetsDir.path),
        reason: 'salinan wajib berada di dalam paket',
      );
      expect(File(ref.filePath).existsSync(), isTrue);
    }
    expect(refs.map((r) => r.type), everyElement('style'));
    expect(summary.unmatchedFolders, ['face']);
  });

  test('re-import is idempotent by content hash', () async {
    await seedAsset('a-aurivy', 'Aurivy');
    final dir = await folder('Aurivy');
    await writeImage(dir, 'a-first.png');

    await ReferenceBulkImporter(
      database: database,
      assetsDirectory: assetsDir,
      projectId: 'p',
    ).importFromFolder(root: Directory('${tempRoot.path}/images'));
    final second = await ReferenceBulkImporter(
      database: database,
      assetsDirectory: assetsDir,
      projectId: 'p',
    ).importFromFolder(root: Directory('${tempRoot.path}/images'));

    expect(
      second.importedPerAsset,
      isEmpty,
      reason: 'hash sama tidak boleh menduplikasi baris',
    );
    final refs = await database.referenceDao.list(
      projectId: 'p',
      ownerAssetId: 'a-aurivy',
    );
    expect(refs.length, 1);
  });

  test('word-order and prefix matching reuse the thumbnail matcher', () async {
    await seedAsset('a-father', 'Father Qowner');
    final dir = await folder('QOWNER FATHER');
    await writeImage(dir, 'r1.png');
    await writeImage(dir, 'r2.png');

    final summary = await ReferenceBulkImporter(
      database: database,
      assetsDirectory: assetsDir,
      projectId: 'p',
    ).importFromFolder(root: Directory('${tempRoot.path}/images'));

    expect(summary.importedPerAsset.keys, ['a-father']);
    expect(summary.importedPerAsset['a-father'], 2);
  });

  test('multiple folders pointing at one asset import only the strongest and '
      'leave exactly one primary', () async {
    await seedAsset('a-aurivy', 'Aurivy');
    final exact = await folder('Aurivy');
    await writeImage(exact, 'a-exact1.png');
    await writeImage(exact, 'b-exact2.png');
    final weakPrefix = await folder('Aurivy Mother');
    await writeImage(weakPrefix, 'weak.png');

    final summary = await ReferenceBulkImporter(
      database: database,
      assetsDirectory: assetsDir,
      projectId: 'p',
    ).importFromFolder(root: Directory('${tempRoot.path}/images'));

    expect(summary.importedPerAsset, {'a-aurivy': 2});
    expect(summary.outcompetedFolders, {'Aurivy Mother': 'a-aurivy'});
    final refs = await database.referenceDao.list(
      projectId: 'p',
      ownerAssetId: 'a-aurivy',
    );
    expect(refs.length, 2);
    expect(
      refs.where((r) => r.primaryReference).length,
      1,
      reason: 'primary ganda melanggar integritas galeri',
    );
  });
}
