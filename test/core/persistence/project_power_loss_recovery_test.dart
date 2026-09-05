import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

void main() {
  // 145.42 data-safety failure matrix: power-loss window di
  // ProjectRecoveryService.atomicWrite. Kontrak Core: registry (projects.json)
  // dan manifest (project.json) tidak boleh hilang ketika proses mati di
  // antara rename target->.bak dan rename .tmp->target.
  group('core persistence power-loss recovery', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vs-14542-powloss-');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    ProjectModel model(String id) => ProjectModel(
      id: id,
      name: 'Proyek $id',
      description: '',
      createdAt: DateTime(2026, 9, 5),
      updatedAt: DateTime(2026, 9, 5),
      lastOpenedAt: DateTime(2026, 9, 5),
      localPath: root.path,
      version: '0.1.0',
    );

    test(
      'registry survivors are restored when the final rename was interrupted',
      () async {
        final paths = ProjectPaths(rootDirectory: root);
        final registry = ProjectRegistryService(paths: paths);
        await registry.upsert(model('survivor-1'));

        // Simulasi power-loss window: target sudah di-rename ke .bak, .tmp
        // sudah ditulis penuh, rename .tmp -> target belum terjadi.
        final registryFile = await paths.registry();
        final bak = File('${registryFile.path}.bak');
        final tmp = File('${registryFile.path}.tmp');
        await registryFile.rename(bak.path);
        await tmp.writeAsString('not-yet-renamed', flush: true);

        final survivors = await registry.load();
        expect(
          survivors,
          isNotEmpty,
          reason: 'registry lama harus tetap terbaca setelah crash window',
        );
        expect(survivors.first.id, 'survivor-1');
      },
    );

    test(
      'manifest survivors are restored when the final rename was interrupted',
      () async {
        final paths = ProjectPaths(rootDirectory: root);
        final service = ProjectManifestService(paths: paths);
        await service.write(
          ProjectManifest(
            schemaVersion: 1,
            id: 'survivor-2',
            name: 'Proyek crash window',
            description: '',
            projectVersion: '0.1.0',
            createdAt: DateTime(2026, 9, 5),
            updatedAt: DateTime(2026, 9, 5),
            appVersion: 'test',
          ),
        );

        final manifestFile = await paths.manifest('survivor-2');
        final bak = File('${manifestFile.path}.bak');
        final tmp = File('${manifestFile.path}.tmp');
        await manifestFile.rename(bak.path);
        await tmp.writeAsString('not-yet-renamed', flush: true);

        final restored = await service.read('survivor-2');
        expect(
          restored.id,
          'survivor-2',
          reason: 'manifest lama harus tetap terbaca setelah crash window',
        );
      },
    );
  });
}
