import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/portable_project_service.dart';

/// 145.33 evidence-closure (test-only, PASS-first): proves transactional
/// import behavior and registry-state rollback on the live engine without
/// touching any production code.
void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s33-txn-');
  });
  tearDown(() => root.delete(recursive: true));

  ProjectManifest readManifest(Directory packageRoot) {
    final json =
        jsonDecode(
              File(
                '${packageRoot.path}/manifest/project.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    return ProjectManifest.fromJson(json);
  }

  ProjectModel modelFor(ProjectPackage package) {
    final m = readManifest(package.root);
    return ProjectModel(
      id: m.id,
      name: m.name,
      description: m.description,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
      lastOpenedAt: m.updatedAt,
      localPath: package.root.path,
      version: m.projectVersion,
      tags: m.tags,
    );
  }

  test(
    'import failure after extraction rolls back registry state and package directory',
    () async {
      final realPackage = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Real');
      final manifest = readManifest(realPackage.root);
      final archive = await PortableProjectExporter().exportPortable(
        realPackage,
      );

      // Pre-condition: registry contains exactly the real project.
      final registry = ProjectRegistryService(rootDirectory: root);
      await registry.upsert(modelFor(realPackage));
      expect((await registry.load()).single.id, manifest.id);

      // Registry whose upsert always fails AFTER the coordinator has already
      // extracted the imported package to disk (post-extraction failure).
      final failingRegistry = _FailingUpsertRegistry(
        ProjectRegistryService(rootDirectory: root),
      );

      await expectLater(
        PortableProjectImportCoordinator(
          registry: failingRegistry,
        ).importAndRegister(archive, destination: root, asCopy: true),
        throwsA(isA<RegistryWriteFailure>()),
      );

      // Rollback proven: only the real package directory remains on disk.
      final packageDirs = root
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.endsWith('.voidproject'))
          .toList();
      expect(packageDirs.length, 1);
      expect(
        packageDirs.single.path.endsWith('${manifest.id}.voidproject'),
        isTrue,
      );

      // Rollback proven: registry still holds exactly the pre-import state.
      final projects = await registry.load();
      expect(projects.length, 1);
      expect(projects.single.id, manifest.id);
    },
  );

  test(
    'registry upsert preserves pre-existing projects when importing a copy',
    () async {
      final firstPackage = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'First');
      final secondPackage = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Second');

      final firstManifest = readManifest(firstPackage.root);
      final archive = await PortableProjectExporter().exportPortable(
        firstPackage,
      );
      final registry = ProjectRegistryService(rootDirectory: root);
      await registry.upsert(modelFor(firstPackage));
      await registry.upsert(modelFor(secondPackage));
      expect((await registry.load()).length, 2);

      final imported = await PortableProjectImportCoordinator(
        registry: registry,
      ).importAndRegister(archive, destination: root, asCopy: true);

      final projects = await registry.load();
      expect(projects.length, 3);
      expect(projects.where((p) => p.id == firstManifest.id), isNotEmpty);
      expect(
        projects.where((p) => p.id == readManifest(secondPackage.root).id),
        isNotEmpty,
      );
      expect(projects.where((p) => p.id == imported.projectId), isNotEmpty);
    },
  );
}

class RegistryWriteFailure implements Exception {
  const RegistryWriteFailure();
}

class _FailingUpsertRegistry implements ProjectRegistryService {
  _FailingUpsertRegistry(this._inner);

  final ProjectRegistryService _inner;

  @override
  Future<List<ProjectModel>> load() => _inner.load();

  @override
  Future<void> upsert(ProjectModel project) async {
    throw const RegistryWriteFailure();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
