import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/application/asset_thumbnail_importer.dart';

void main() {
  late ProjectDatabase database;
  late Directory packageRoot;
  late Directory sourceDir;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
    addTearDown(database.close);

    packageRoot = await Directory.systemTemp.createTemp('thumb-import-pkg-');
    addTearDown(() => packageRoot.delete(recursive: true));
    sourceDir = await Directory.systemTemp.createTemp('thumb-import-src-');
    addTearDown(() => sourceDir.delete(recursive: true));

    await database.assetDao.createStandaloneAsset(
      id: 'character-1',
      projectId: 'project-1',
      name: 'Aurivy',
      type: 'creature',
      now: DateTime(2026),
    );
  });

  test(
    'imports a local image into the package and sets thumbnailPath',
    () async {
      final source = File('${sourceDir.path}/aurivy.png');
      await source.writeAsBytes([1, 2, 3, 4]);

      final importer = AssetThumbnailImporter(
        database: database,
        assetsDirectory: Directory('${packageRoot.path}/assets'),
      );
      final storedPath = await importer.importFromFile(
        assetId: 'character-1',
        sourcePath: source.path,
      );

      // File lands inside the package asset namespace, not the source dir.
      final stored = File(storedPath);
      expect(stored.existsSync(), isTrue);
      expect(stored.parent.path, contains('asset_thumbnails'));
      expect(stored.readAsBytesSync(), [1, 2, 3, 4]);

      final row = await database.assetDao.getById('character-1');
      expect(row?.thumbnailPath, storedPath);
    },
  );

  test('re-import replaces the stored file and the recorded path', () async {
    final first = File('${sourceDir.path}/v1.png');
    await first.writeAsBytes([1]);
    final second = File('${sourceDir.path}/v2.png');
    await second.writeAsBytes([9, 9, 9]);

    final importer = AssetThumbnailImporter(
      database: database,
      assetsDirectory: Directory('${packageRoot.path}/assets'),
    );
    final path1 = await importer.importFromFile(
      assetId: 'character-1',
      sourcePath: first.path,
    );
    final path2 = await importer.importFromFile(
      assetId: 'character-1',
      sourcePath: second.path,
    );

    expect(path2, isNot(path1));
    expect(
      File(path1).existsSync(),
      isFalse,
      reason: 'superseded thumbnail file must not linger in the package',
    );
    expect(File(path2).existsSync(), isTrue);

    final row = await database.assetDao.getById('character-1');
    expect(row?.thumbnailPath, path2);
  });

  test(
    'rejects a missing source file without touching the asset row',
    () async {
      final importer = AssetThumbnailImporter(
        database: database,
        assetsDirectory: Directory('${packageRoot.path}/assets'),
      );

      await expectLater(
        importer.importFromFile(
          assetId: 'character-1',
          sourcePath: '${sourceDir.path}/not-there.png',
        ),
        throwsStateError,
      );

      final row = await database.assetDao.getById('character-1');
      expect(row?.thumbnailPath, isNull);
    },
  );

  test('rejects unsupported extensions', () async {
    final source = File('${sourceDir.path}/payload.exe');
    await source.writeAsBytes([1]);

    final importer = AssetThumbnailImporter(
      database: database,
      assetsDirectory: Directory('${packageRoot.path}/assets'),
    );

    await expectLater(
      importer.importFromFile(assetId: 'character-1', sourcePath: source.path),
      throwsArgumentError,
    );
    expect(
      File('${packageRoot.path}/assets/asset_thumbnails').existsSync(),
      isFalse,
      reason: 'nothing may be staged for a rejected import',
    );
  });

  test('rejects unknown asset ids', () async {
    final source = File('${sourceDir.path}/aurivy.png');
    await source.writeAsBytes([1, 2]);

    final importer = AssetThumbnailImporter(
      database: database,
      assetsDirectory: Directory('${packageRoot.path}/assets'),
    );

    await expectLater(
      importer.importFromFile(assetId: 'ghost-asset', sourcePath: source.path),
      throwsStateError,
    );
  });
}
