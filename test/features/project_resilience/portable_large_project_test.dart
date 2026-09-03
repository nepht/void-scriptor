import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';

void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-s33-large-'),
  );
  tearDown(() => root.delete(recursive: true));

  const assetFileCount = 250;
  const workspaceFileCount = 60;
  const largeFileBytes = 256 * 1024;

  Future<ProjectPackageHolder> seedLargeProject() async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Large Project');
    // Banyak file aset kecil di beberapa subdirektori.
    for (var i = 0; i < assetFileCount; i++) {
      final dir = '${package.assetsDirectory.path}/images/batch-${i % 5}';
      await Directory(dir).create(recursive: true);
      await File('$dir/asset-$i.txt').writeAsString('asset-content-$i');
    }
    // Dua file besar (256 KiB masing-masing).
    final blob = Uint8List.fromList(List<int>.filled(largeFileBytes, 65));
    final mediaDir = Directory(
      '${package.assetsDirectory.path}/media',
    )..createSync(recursive: true);
    await File(
      '${mediaDir.path}/blob-a.bin',
    ).writeAsBytes(blob);
    await File(
      '${mediaDir.path}/blob-b.bin',
    ).writeAsBytes(blob);
    // Banyak file workspace.
    final namespace = WorkspaceFileNamespace(package);
    for (var i = 0; i < workspaceFileCount; i++) {
      final file = await namespace.createFile('novel-$i', 'drafts/chapter.json');
      await file.writeAsString('{"id":"novel-$i","draft":true}');
    }
    return ProjectPackageHolder(package);
  }

  test('exports a large project archive with every file present', () async {
    final holder = await seedLargeProject();
    final archive = await PortableProjectExporter().exportPortable(holder.package);
    expect(await archive.exists(), isTrue);
    final archiveBytes = await archive.readAsBytes();
    final decoded = ZipDecoder().decodeBytes(archiveBytes, verify: true);
    // Semua file yang di-seed harus hadir: 250 aset + 2 blob + 60 workspace
    // + manifest + database + meta archive.
    expect(
      decoded.files.length,
      greaterThanOrEqualTo(
        assetFileCount + workspaceFileCount + 2 + 3,
      ),
    );
    expect(decoded.find('manifest/project.json'), isNotNull);
    expect(decoded.find('database/project.db'), isNotNull);
    final metaEntry = decoded.find('voidproject.archive.json')!;
    final meta =
        jsonDecode(utf8.decode(metaEntry.readBytes()!)) as Map<String, dynamic>;
    expect(meta['checksum'], isNotEmpty);
    expect(
      ArchiveIntegrity.computeContentChecksum(decoded),
      meta['checksum'],
    );

    // Setiap aset dan workspace ikut terbawa.
    for (var i = 0; i < assetFileCount; i++) {
      expect(
        decoded.find('assets/images/batch-${i % 5}/asset-$i.txt'),
        isNotNull,
      );
    }
    expect(decoded.find('assets/media/blob-a.bin'), isNotNull);
    expect(decoded.find('assets/media/blob-b.bin'), isNotNull);
    for (var i = 0; i < workspaceFileCount; i++) {
      expect(
        decoded.find('workspaces/novel-$i/drafts/chapter.json'),
        isNotNull,
      );
    }
  });

  test('imports a large archive preserving structure and content', () async {
    final holder = await seedLargeProject();
    final archive = await PortableProjectExporter().exportPortable(holder.package);
    final imported = await PortableProjectImporter().importArchive(
      archive,
      destination: root,
      asCopy: true,
    );

    // Hitung file hasil ekstraksi: harus ≥ aset + workspace + manifest + db.
    var fileCount = 0;
    await for (final entity in imported.root.list(recursive: true)) {
      if (entity is File) fileCount++;
    }
    expect(fileCount, greaterThanOrEqualTo(assetFileCount + workspaceFileCount + 2));

    // Spot-check konten aset besar (round-trip byte-exact).
    final blob = await File(
      '${imported.root.path}/assets/media/blob-a.bin',
    ).readAsBytes();
    expect(blob.length, largeFileBytes);
    expect(blob.every((byte) => byte == 65), isTrue);

    // Spot-check konten workspace.
    expect(
      await File(
        '${imported.root.path}/workspaces/novel-0/drafts/chapter.json',
      ).readAsString(),
      '{"id":"novel-0","draft":true}',
    );
    expect(
      await File(
        '${imported.root.path}/workspaces/novel-59/drafts/chapter.json',
      ).readAsString(),
      '{"id":"novel-59","draft":true}',
    );
  });

  test('registers a relocated large project copy in the registry', () async {
    final holder = await seedLargeProject();
    final archive = await PortableProjectExporter().exportPortable(holder.package);
    final destination = Directory('${root.path}/registry-root');
    final registry = ProjectRegistryService(rootDirectory: destination);

    final imported = await PortableProjectImportCoordinator(
      registry: registry,
    ).importAndRegister(archive, destination: destination, asCopy: true);

    final projects = await registry.load();
    expect(projects.single.id, imported.projectId);
    expect(projects.single.localPath, imported.root.path);
    expect(imported.projectId, isNot(holder.package.projectId));

    // Project besar hasil import tetap berisi data lengkap.
    expect(
      await File(
        '${imported.root.path}/assets/images/batch-4/asset-249.txt',
      ).readAsString(),
      'asset-content-249',
    );
  });
}

class ProjectPackageHolder {
  ProjectPackageHolder(this.package);
  final ProjectPackage package;
}
