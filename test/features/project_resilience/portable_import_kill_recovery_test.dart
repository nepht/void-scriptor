import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/project_model.dart';
import 'package:void_scriptor/core/persistence/import_claim.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';

import '../../support/real_dart_executable.dart';

/// 145.42 interrupted-import — hard process kill NYATA pada jendela stash
/// rename-vs-extract. Child Dart murni me-replay urutan produksi coordinator
/// (claim sentinel -> stash rename -> scratch ekstraksi) memakai kelas
/// produksi ImportClaim yang sama, lalu di-TerminateProcess oleh parent saat
/// child berada di tengah jendela ekstraksi. Rollback Dart in-process
/// terbukti tidak pernah berjalan; hanya pemulihan produksi lintas-proses
/// (ProjectRegistryService.load) yang wajib mengembalikan paket asli
/// pengguna dari corpse nyata — bukan simulasi throw in-process.
void main() {
  test('OS kill mid-extraction: claim sentinel drives restoration of the '
      'buried original package', () async {
    // Production shape: the import destination IS the projects root that
    // owns the registry, so the collision stash, its claim, and the
    // registered package all share one owner directory.
    final root = await Directory.systemTemp.createTemp('hermes-import-kill-');
    addTearDown(() => root.delete(recursive: true));

    final original = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Kill Harness Original');
    final manifest = ProjectManifest.fromJson(
      jsonDecode(
            File(
              '${original.root.path}/manifest/project.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>,
    );
    final id = manifest.id;
    final now = DateTime.now().toUtc();
    await ProjectRegistryService(rootDirectory: root).upsert(
      ProjectModel(
        id: id,
        name: 'Kill Harness Original',
        description: '',
        createdAt: now,
        updatedAt: now,
        lastOpenedAt: now,
        localPath: original.root.path,
        version: '0.1.0',
      ),
    );
    final originalManifestBytes = await File(
      '${original.root.path}/manifest/project.json',
    ).readAsBytes();

    final dartExe = await resolveRealDartExecutable();
    final childScript = File(
      'test/features/project_resilience/fixtures/import_kill_child.dart',
    );
    expect(
      await childScript.exists(),
      isTrue,
      reason: 'child script fixture must exist for the kill harness',
    );

    final process = await Process.start(dartExe, <String>[
      childScript.absolute.path,
      root.path,
      original.root.path,
      id,
    ], workingDirectory: Directory.current.path);
    final claimed = Completer<void>();
    final stashed = Completer<void>();
    final scratchWritten = Completer<void>();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final trimmed = line.trim();
          if (trimmed == 'CLAIMED' && !claimed.isCompleted) {
            claimed.complete();
          }
          if (trimmed == 'STASHED' && !stashed.isCompleted) {
            stashed.complete();
          }
          if (trimmed == 'SCRATCH_WRITTEN' && !scratchWritten.isCompleted) {
            scratchWritten.complete();
          }
        });
    final stderrText = StringBuffer();
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrText.writeln);

    await scratchWritten.future.timeout(const Duration(seconds: 60));
    // Child sits mid-extraction (never completes the import): kill it.
    final killed = process.kill();
    expect(killed, isTrue, reason: 'hard kill must succeed');
    final exitCode = await process.exitCode.timeout(
      const Duration(seconds: 15),
    );
    expect(
      exitCode,
      isNot(0),
      reason: 'hard-killed child must exit nonzero (stderr: $stderrText)',
    );
    expect(
      claimed.isCompleted && stashed.isCompleted,
      isTrue,
      reason: 'the killed window opened after claim + stash + scratch',
    );

    // Corpse preconditions: claim live on disk, original buried under the
    // stash, canonical path holds manifest-less extraction scratch.
    final claimFile = ImportClaim.fileFor(destination: root, projectId: id);
    expect(await claimFile.exists(), isTrue);
    final stash = Directory(
      '${root.path}/.$id.voidproject.import-backup-killharness',
    );
    expect(
      await stash.exists(),
      isTrue,
      reason: 'the killed import must have renamed the original to the stash',
    );
    final canonical = Directory('${root.path}/$id.voidproject');
    expect(
      await File('${canonical.path}/manifest/project.json').exists(),
      isFalse,
      reason: 'the corpse must be mid-extraction scratch, not a package',
    );

    // Production recovery: the registry load a new app session performs.
    final recovered = await ProjectRegistryService(rootDirectory: root).load();

    expect(
      recovered.map((project) => project.id),
      contains(id),
      reason: 'the registered project must stay visible after recovery',
    );
    final restoredManifest = File('${canonical.path}/manifest/project.json');
    expect(
      await restoredManifest.exists(),
      isTrue,
      reason: 'original package must reclaim the canonical path',
    );
    expect(
      await restoredManifest.readAsBytes(),
      equals(originalManifestBytes),
      reason: 'restored bytes must equal the pre-import original exactly',
    );
    expect(
      await File('${canonical.path}/assets/partial-1.bin').exists(),
      isFalse,
      reason: 'extraction scratch must not remain at the canonical path',
    );
    expect(
      await stash.exists(),
      isFalse,
      reason: 'the consumed stash must not linger',
    );
    expect(
      await claimFile.exists(),
      isFalse,
      reason: 'a completed restoration consumes its claim',
    );
    // Non-destructive quarantine of the dead scratch survives, hidden.
    final quarantined = root
        .listSync()
        .whereType<Directory>()
        .where((d) => _basename(d.path).startsWith('.import-scratch-$id'))
        .toList();
    expect(
      quarantined,
      hasLength(1),
      reason: 'scratch corpse is renamed aside, never deleted',
    );
    expect(
      await File('${quarantined.single.path}/assets/partial-1.bin').exists(),
      isTrue,
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}
