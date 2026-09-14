import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/import_claim.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/restore_staging_journal.dart'
    show fileDigest;
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

/// 145.42 interrupted-import — claim-sentinel rule tests (in-process).
///
/// The import coordinator writes a hidden `.import-claim-<projectId>.json`
/// BEFORE the destination-collision stash rename and releases it only after
/// the import fully succeeds or fully rolls back. While a claim exists and
/// its named stash is still on disk, the import never reached its final
/// discard, so ANY content sitting at the canonical package path is provably
/// in-progress scratch from that dead attempt — not an ambiguous completed
/// package. Recovery must quarantine the scratch (rename, never destroy) and
/// restore the user's original instead of leaving it buried forever.
/// Without a claim, the pre-existing safe-by-default rule stands: recovery
/// never guesses between two copies.
void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s-claim-');
  });
  tearDown(() => root.delete(recursive: true));

  String manifestId(Directory packageRoot) {
    final json =
        jsonDecode(
              File(
                '${packageRoot.path}/manifest/project.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    return ProjectManifest.fromJson(json).id;
  }

  Future<ProjectPackage> registeredOriginal() async {
    final original = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Claim Original');
    final now = DateTime.now().toUtc();
    await ProjectRegistryService(rootDirectory: root).upsert(
      ProjectModel(
        id: manifestId(original.root),
        name: 'Claim Original',
        description: '',
        createdAt: now,
        updatedAt: now,
        lastOpenedAt: now,
        localPath: original.root.path,
        version: '0.1.0',
      ),
    );
    return original;
  }

  Directory stashFor(String projectId) =>
      Directory('${root.path}/.$projectId.voidproject.import-backup-claimwin');

  List<String> scratchDirs(String projectId) {
    return root.listSync().whereType<Directory>().map((d) => d.path).where((
      path,
    ) {
      final name = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
      return name.startsWith('.import-scratch-$projectId');
    }).toList();
  }

  test(
    'claim-present scratch canonical is quarantined so the stash restores',
    () async {
      final original = await registeredOriginal();
      final id = manifestId(original.root);
      final stash = stashFor(id);
      await original.root.rename(stash.path);
      final originalDigest = await fileDigest(
        File('${stash.path}/manifest/project.json'),
      );
      // Crash window: extraction had created a partial package at the
      // canonical path while the claim naming this stash is still live.
      final corpse = Directory('${root.path}/$id.voidproject');
      await corpse.create(recursive: true);
      final scratchFile = File('${corpse.path}/assets/partial.bin');
      await scratchFile.parent.create(recursive: true);
      await scratchFile.writeAsString('junk');
      final claim = await ImportClaim.create(
        destination: root,
        projectId: id,
        stashPath: stash.path,
      );
      // Simulate the process that wrote the claim having DIED: recovery in
      // a later process only acts on claims nobody owns in-process.
      claim.disposeLocalOwnership();

      final projects = await ProjectRegistryService(rootDirectory: root).load();

      final restored = Directory('${root.path}/$id.voidproject');
      expect(
        File('${restored.path}/manifest/project.json').existsSync(),
        isTrue,
        reason: 'original package must reclaim the canonical path',
      );
      expect(
        await fileDigest(File('${restored.path}/manifest/project.json')),
        originalDigest,
        reason: 'the restored package must be byte-identical to the stash',
      );
      expect(
        File('${restored.path}/assets/partial.bin').existsSync(),
        isFalse,
        reason: 'extraction scratch must never block stash restoration',
      );
      expect(stash.existsSync(), isFalse, reason: 'stash must be consumed');
      expect(
        ImportClaim.fileFor(destination: root, projectId: id).existsSync(),
        isFalse,
        reason: 'a completed restoration consumes its claim',
      );
      // Non-destructive: the quarantined scratch survives somewhere hidden.
      expect(
        scratchDirs(id),
        hasLength(1),
        reason: 'scratch is renamed aside, never deleted',
      );
      expect(projects, hasLength(1));
      expect(projects.single.id, id);
    },
  );

  test(
    'an ambiguous canonical with no claim is still left untouched',
    () async {
      final original = await registeredOriginal();
      final id = manifestId(original.root);
      final stash = stashFor(id);
      await original.root.rename(stash.path);
      // The import had already completed and discarded its stash, then a
      // later package reoccupied the canonical path. Without a claim there
      // is no proof the canonical content is scratch (this also covers
      // stashes left by pre-claim builds), so recovery must not guess.
      Directory('${root.path}/$id.voidproject').createSync();

      await ProjectRegistryService(rootDirectory: root).load();

      expect(
        stash.existsSync(),
        isTrue,
        reason: 'claimless ambiguity must stay untouched',
      );
      expect(
        File('${stash.path}/manifest/project.json').readAsStringSync(),
        contains('Claim Original'),
      );
    },
  );

  test(
    'a stale claim whose stash no longer exists is swept without touching the package',
    () async {
      final original = await registeredOriginal();
      final id = manifestId(original.root);
      // Import completed and discarded the stash, but the process died
      // before releasing the claim sentinel.
      final claim = await ImportClaim.create(
        destination: root,
        projectId: id,
        stashPath: '${root.path}/.$id.voidproject.import-backup-gone',
      );
      claim.disposeLocalOwnership();

      await ProjectRegistryService(rootDirectory: root).load();

      expect(
        ImportClaim.fileFor(destination: root, projectId: id).existsSync(),
        isFalse,
        reason: 'a claim naming a vanished stash must not linger',
      );
      expect(
        Directory('${root.path}/$id.voidproject').existsSync(),
        isTrue,
        reason: 'the sweep must never touch the live package',
      );
      expect(scratchDirs(id), isEmpty);
    },
  );

  test(
    'an active in-process claim is never recovered underneath its live import',
    () async {
      final original = await registeredOriginal();
      final id = manifestId(original.root);
      final stash = stashFor(id);
      await original.root.rename(stash.path);
      Directory('${root.path}/$id.voidproject').createSync(recursive: true);
      await ImportClaim.create(
        destination: root,
        projectId: id,
        stashPath: stash.path,
      );
      ImportClaim.markActive(id);
      addTearDown(() => ImportClaim.clearActive(id));

      await ProjectRegistryService(rootDirectory: root).load();

      expect(
        Directory('${root.path}/$id.voidproject').existsSync(),
        isTrue,
        reason: 'a live extraction must keep its destination',
      );
      expect(stash.existsSync(), isTrue, reason: 'live import owns its stash');
      expect(
        ImportClaim.fileFor(destination: root, projectId: id).existsSync(),
        isTrue,
        reason: 'the active claim must survive this listing',
      );
    },
  );
}
