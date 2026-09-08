// Bulk thumbnail import (menu #3 Choi, 2026-09-08): folder per karakter di
// D:\Gambar AI\My Character dipetakan ke aset existing; gambar pertama
// (urut nama) menjadi thumbnail aset tersebut. Sisa gambar dalam folder
// hanya dilaporkan; folder tanpa aset cocok dilaporkan unmatched; gambar
// lepas di root tidak bisa diatribusikan sehingga dihitung terpisah.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/assets/application/asset_thumbnail_bulk_importer.dart';
import 'package:void_scriptor/features/assets/application/asset_thumbnail_importer.dart';

void main() {
  late Directory tempRoot;
  late Directory assetsDir;
  late ProjectDatabase database;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('bulk-thumb-');
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
    File('${dir.path}/$fileName').writeAsBytesSync(const [1, 2, 3]);
  }

  test('matches folders to assets case-insensitively and applies the first '
      'image, reporting the rest', () async {
    await seedAsset('a-aurivy', 'Aurivy');
    await seedAsset('a-azrael', 'Azrael Noctis');
    await seedAsset('a-father', 'Father Qowner');
    await seedAsset('a-qowner', 'Qowner');

    final aurivy = await folder('Aurivy');
    await writeImage(aurivy, 'b-second.png');
    await writeImage(aurivy, 'a-first.jpg');
    await writeImage(aurivy, 'c-third.webp');
    final azrael = await folder('Azrael Noctis ( Demon Lord )');
    await writeImage(azrael, 'demon.png');
    final father = await folder('Father Qowner');
    await writeImage(father, 'father.jpeg');
    await folder('face'); // tidak ada aset "face"
    await folder('_contact_sheets'); // metadata, bukan karakter
    File('${tempRoot.path}/images/loose-uuid.png').writeAsBytesSync(const [9]);

    final summary = await AssetThumbnailBulkImporter(
      database: database,
      assetsDirectory: assetsDir,
    ).importFromFolder(root: Directory('${tempRoot.path}/images'));

    // Gambar pertama (urut nama) menjadi thumbnail; kontrak target
    // importer adalah <assetId>_<microstamp><ext> — extension-nyalah
    // yang membuktikan sumber mana yang terpilih.
    expect(summary.applied.keys.toSet(), {'a-aurivy', 'a-azrael', 'a-father'});
    expect(summary.applied['a-aurivy']!, endsWith('.jpg'));
    expect(summary.applied['a-azrael']!, endsWith('.png'));
    expect(summary.applied['a-father']!, endsWith('.jpeg'));

    // "Father Qowner" harus jatuh ke aset yang tepat, bukan "Qowner".
    final fatherAsset = await database.assetDao.getById('a-father');
    expect(fatherAsset!.thumbnailPath, summary.applied['a-father']);
    final qownerAsset = await database.assetDao.getById('a-qowner');
    expect(qownerAsset!.thumbnailPath, isNull);

    // File tersalin ke namespace thumbnail paket.
    final copied = File(summary.applied['a-aurivy']!);
    expect(await copied.exists(), isTrue);
    expect(await copied.length(), 3);
    expect(copied.parent.path, endsWith('asset_thumbnails'));

    // Pelaporan sisa.
    expect(summary.unmatchedFolders, ['face']);
    expect(summary.skippedRootImages, 1);
    expect(summary.extraImagesPerAsset['a-aurivy'], hasLength(2));
    expect(summary.extraImagesPerAsset.containsKey('a-azrael'), isFalse);
  });

  test(
    'a second run replaces the previous copy without leaving stale files',
    () async {
      await seedAsset('a-aurivy', 'Aurivy');
      final dir = await folder('Aurivy');
      await writeImage(dir, 'one.png');

      final importer = AssetThumbnailBulkImporter(
        database: database,
        assetsDirectory: assetsDir,
      );
      final first = await importer.importFromFolder(
        root: Directory('${tempRoot.path}/images'),
      );
      final firstPath = first.applied['a-aurivy']!;
      expect(firstPath, endsWith('.png'));

      await writeImage(dir, 'two.png');
      final second = await importer.importFromFolder(
        root: Directory('${tempRoot.path}/images'),
      );

      final secondPath = second.applied['a-aurivy']!;
      expect(secondPath, endsWith('.png'));
      expect(secondPath, isNot(firstPath));
      expect(await File(firstPath).exists(), isFalse);
      final thumbnails = await AssetThumbnailImporter(
        database: database,
        assetsDirectory: assetsDir,
      ).thumbnailDirectory().list().toList();
      expect(
        thumbnails.whereType<File>().length,
        1,
        reason: 're-import menggantikan salinan lama',
      );
    },
  );
}
