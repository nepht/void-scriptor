import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

/// Sprint 145.42 interrupted-import crash-window recovery: a process death
/// (kill / power loss) between the destination-collision stash rename and
/// import completion buries the user's original package under a hidden
/// `.import-backup-*` stash while the registry still points at the final
/// path. Recovery must restore the stash to its canonical location before
/// the registry reports the project as missing data.
void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s-import-');
  });
  tearDown(() => root.delete(recursive: true));

  String manifestId(Directory packageRoot) {
    final json = jsonDecode(
      File('${packageRoot.path}/manifest/project.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    return ProjectManifest.fromJson(json).id;
  }

  Directory stashFor(String projectId) {
    return Directory(
      '${root.path}/.$projectId.voidproject.import-backup-crashwindow',
    );
  }

  test(
    'crash between stash rename and import restores original on registry load',
    () async {
      final original = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Original');
      final id = manifestId(original.root);
      // Production lifecycle: the original was a registered project, so
      // its creation marker was already consumed by registration before
      // any import could target it.
      final now = DateTime.now().toUtc();
      await ProjectRegistryService(rootDirectory: root).upsert(
        ProjectModel(
          id: id,
          name: 'Original',
          description: '',
          createdAt: now,
          updatedAt: now,
          lastOpenedAt: now,
          localPath: original.root.path,
          version: '0.1.0',
        ),
      );

      // Simulate the crash window: the coordinator renamed the existing
      // package into the hidden stash, then the process died before the
      // import produced anything at the canonical path.
      final stash = stashFor(id);
      await original.root.rename(stash.path);
      expect(await original.root.exists(), isFalse);

      final projects = await ProjectRegistryService(
        rootDirectory: root,
      ).load();

      expect(
        await Directory('${root.path}/$id.voidproject').exists(),
        isTrue,
        reason: 'original package must be restored from the crash-window stash',
      );
      expect(await stash.exists(), isFalse, reason: 'stash must be consumed');
      expect(
        File(
          '${root.path}/$id.voidproject/manifest/project.json',
        ).readAsStringSync(),
        contains('Original'),
      );
      // The registered project stays visible across the crash window:
      // its registry entry survives and the restored package must NOT be
      // admitted a second time (its creation marker was consumed at
      // registration, before the crash window opened).
      expect(projects, hasLength(1));
      expect(projects.single.id, id);
    },
  );

  test(
    'leaves a crash-window stash in place when the canonical package exists',
    () async {
      final original = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Original');
      final id = manifestId(original.root);
      final stash = stashFor(id);
      await original.root.rename(stash.path);
      // The import had already completed: a canonical package now exists at
      // the final path. Recovery must not guess between the two copies.
      Directory('${root.path}/$id.voidproject').createSync();

      await ProjectRegistryService(rootDirectory: root).load();

      expect(await stash.exists(), isTrue,
          reason: 'ambiguous crash window must stay safe-by-default');
      expect(
        File('${stash.path}/manifest/project.json').readAsStringSync(),
        contains('Original'),
      );
    },
  );
}
