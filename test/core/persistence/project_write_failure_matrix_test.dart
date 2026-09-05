import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';

// 145.42 data-safety failure matrix (ADR-0003 #1): disk-full dan
// permission-loss pada jalur tulis produksi registry/manifest
// (ProjectRecoveryService.atomicWrite). Simulasi host-akurat TANPA
// mengisi drive nyata atau mengubah permission sistem:
// - disk-full ditiru dengan menempatkan DIRECTORY di path staging
//   `<target>.tmp` sehingga penulisan staging gagal deterministik
//   (PathAccessException) seperti kehabisan ruang tulis.
// - permission-loss ditiru dengan menempatkan DIRECTORY di path target
//   atau backup sehingga rename pemulihan ditolak (Access denied).
// Kontrak Core yang diuji: konten lama tidak hilang, kegagalan terlihat
// keras (bukan daftar proyek kosong diam-diam), staging yang gagal tidak
// meninggalkan sampah permanen, dan retry setelah hambatan hilang
// berhasil tanpa kehilangan data.
void main() {
  group('project write failure matrix (disk full / permission loss)', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('vs-14542-failmatrix-');
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
      'disk-full pada staging registry mempertahankan isi registry lama',
      () async {
        final paths = ProjectPaths(rootDirectory: root);
        final registry = ProjectRegistryService(paths: paths);
        await registry.upsert(model('durable-1'));

        final registryFile = await paths.registry();
        final blockedStaging = Directory('${registryFile.path}.tmp');
        await blockedStaging.create();

        await expectLater(
          registry.upsert(model('durable-2')),
          throwsA(isA<FileSystemException>()),
        );

        final projects = await registry.load();
        expect(projects.map((p) => p.id), contains('durable-1'));
        expect(projects.map((p) => p.id), isNot(contains('durable-2')));
      },
    );

    test(
      'permission-loss pada backup registry menjaga target lama utuh',
      () async {
        final paths = ProjectPaths(rootDirectory: root);
        final registry = ProjectRegistryService(paths: paths);
        await registry.upsert(model('durable-3'));

        final registryFile = await paths.registry();
        final blockedBackup = Directory('${registryFile.path}.bak');
        await blockedBackup.create();

        await expectLater(
          registry.upsert(model('durable-4')),
          throwsA(isA<FileSystemException>()),
        );

        final projects = await registry.load();
        expect(projects.map((p) => p.id), contains('durable-3'));
        expect(projects.map((p) => p.id), isNot(contains('durable-4')));

        await blockedBackup.delete();
        await registry.upsert(model('durable-4'));
        final afterRetry = await registry.load();
        expect(
          afterRetry.map((p) => p.id),
          containsAll(<String>['durable-3', 'durable-4']),
        );
      },
    );

    test(
      'staging terpotong (truncated) tidak pernah dipercaya atau merusak target',
      () async {
        final paths = ProjectPaths(rootDirectory: root);
        final registry = ProjectRegistryService(paths: paths);
        await registry.upsert(model('durable-5'));

        final registryFile = await paths.registry();
        final truncatedStaging = File('${registryFile.path}.tmp');
        await truncatedStaging.writeAsString(
          '{"schemaVersion":1,"trunc',
          flush: true,
        );

        await registry.upsert(model('durable-6'));

        final projects = await registry.load();
        expect(
          projects.map((p) => p.id),
          containsAll(<String>['durable-5', 'durable-6']),
        );
        expect(
          await truncatedStaging.exists(),
          isFalse,
          reason:
              'atomicWrite yang sukses merename staging, tidak menyisakan file',
        );
      },
    );

    test(
      'disk-full pada staging manifest mempertahankan manifest lama',
      () async {
        final paths = ProjectPaths(rootDirectory: root);
        final service = ProjectManifestService(paths: paths);
        final original = ProjectManifest(
          schemaVersion: 1,
          id: 'manifest-survivor',
          name: 'Proyek manifest',
          description: '',
          projectVersion: '0.1.0',
          createdAt: DateTime(2026, 9, 5),
          updatedAt: DateTime(2026, 9, 5),
          appVersion: 'test',
        );
        await service.write(original);

        final manifestFile = await paths.manifest('manifest-survivor');
        final blockedStaging = Directory('${manifestFile.path}.tmp');
        await blockedStaging.create();

        final blocked = ProjectManifest(
          schemaVersion: 1,
          id: 'manifest-survivor',
          name: 'Proyek manifest (blokir)',
          description: '',
          projectVersion: '0.1.0',
          createdAt: DateTime(2026, 9, 5),
          updatedAt: DateTime(2026, 9, 5),
          appVersion: 'test',
        );
        await expectLater(
          service.write(blocked),
          throwsA(isA<FileSystemException>()),
        );

        final restored = await service.read('manifest-survivor');
        expect(restored.name, 'Proyek manifest');

        await blockedStaging.delete();
        final updated = ProjectManifest(
          schemaVersion: 1,
          id: 'manifest-survivor',
          name: 'Proyek manifest (revisi)',
          description: '',
          projectVersion: '0.1.0',
          createdAt: DateTime(2026, 9, 5),
          updatedAt: DateTime(2026, 9, 6),
          appVersion: 'test',
        );
        await service.write(updated);
        expect(
          (await service.read('manifest-survivor')).name,
          'Proyek manifest (revisi)',
        );
      },
    );
  });
}
