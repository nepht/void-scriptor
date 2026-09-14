import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/restore_staging_journal.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

/// 145.42 / 145.34 — restore dua-fase. Kontrak lama menulis live
/// manifest/database dengan `writeAsBytes` dan mengganti direktori dengan
/// delete+copy: hard-kill di tengah jendela itu meninggalkan area torn TANPA
/// residu yang bisa disembuhkan, dan `RestoreCrashRecovery` membersihkan
/// artefak `.tmp` yang tidak pernah diproduksi writer mana pun (heal tanpa
/// produsen, pitfall #15). Restore kini men-stage payload cadangan ke
/// staging terverifikasi + jurnal `recovery/restore-staging.json` SEBELUM
/// satu byte live pun berubah; jurnal yang selamat dari kill digulirkan
/// maju pada pemulihan berikutnya.
Future<Map<String, List<int>>> payload(Directory root) async => {
  await for (final entry in root.list(recursive: true, followLinks: false))
    if (entry is File)
      entry.path.substring(root.path.length): await entry.readAsBytes(),
};

Future<ProjectPackage> seedPackage(
  Directory root, {
  required String name,
}) async {
  final package = await ProjectPackageService(
    rootDirectory: root,
  ).create(name: name);
  final workspaces = Directory('${package.root.path}/workspaces');
  await workspaces.create(recursive: true);
  await File(
    '${package.assetsDirectory.path}/portrait.txt',
  ).writeAsString('live portrait');
  await File('${workspaces.path}/novel.json').writeAsString('{"live":true}');
  return package;
}

Future<void> copyTree(Directory source, Directory target) async {
  await target.create(recursive: true);
  await for (final entity in source.list(recursive: true)) {
    if (entity is! File) continue;
    final dest = File(
      '${target.path}${entity.path.substring(source.path.length)}',
    );
    await dest.parent.create(recursive: true);
    await entity.copy(dest.path);
  }
}

void main() {
  test(
    'failure at the staging-complete seam leaves every live area byte-intact '
    'and consumes all staging artifacts and the journal',
    () async {
      final root = await Directory.systemTemp.createTemp('restore-2phase-');
      addTearDown(() => root.delete(recursive: true));
      final package = await seedPackage(root, name: 'Two phase');
      final service = ProjectBackupService();
      final backup = await service.create(package: package, type: 'manual');
      // Live evolves AFTER the backup.
      final portrait = File('${package.assetsDirectory.path}/portrait.txt');
      await portrait.writeAsString('newer portrait');
      final workspace = File('${package.root.path}/workspaces/novel.json');
      await workspace.writeAsString('{"newer":true}');
      final assetsBefore = await payload(package.assetsDirectory);
      final workspacesBefore = await payload(
        Directory('${package.root.path}/workspaces'),
      );
      final manifestBefore = await package.manifestFile.readAsBytes();
      final databaseBefore = await package.databaseFile.readAsBytes();

      service.onStagingCompleteForTesting = () async {
        throw const FileSystemException('injected kill at staging seam');
      };
      await expectLater(
        service.restore(package: package, backup: backup),
        throwsA(isA<FileSystemException>()),
      );
      service.onStagingCompleteForTesting = null;

      expect(
        await payload(package.assetsDirectory),
        assetsBefore,
        reason:
            'a throw after staging but before placement must not touch '
            'a single live byte',
      );
      expect(
        await payload(Directory('${package.root.path}/workspaces')),
        workspacesBefore,
      );
      expect(await package.manifestFile.readAsBytes(), manifestBefore);
      expect(await package.databaseFile.readAsBytes(), databaseBefore);
      expect(
        await RestoreStagingJournal.load(package),
        isNull,
        reason:
            'a failed restore must not leave a journal a later open '
            'could mistake for an interrupted placement',
      );
      expect(
        await Directory('${package.assetsDirectory.path}.tmp').exists(),
        isFalse,
        reason: 'staged assets are never authoritative; purge on unwind',
      );
      expect(
        await Directory('${package.root.path}/workspaces.tmp').exists(),
        isFalse,
      );
      expect(await File('${package.manifestFile.path}.tmp').exists(), isFalse);
      expect(await File('${package.databaseFile.path}.tmp').exists(), isFalse);
      // The emergency snapshot is deliberately retained.
      expect(
        await Directory(service.lastEmergencyBackupPath!).exists(),
        isTrue,
      );
    },
  );

  test(
    'a placement killed mid-swap is rolled forward from the verified journal '
    'on the next recovery and the journal is consumed',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'restore-2phase-heal-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await seedPackage(root, name: 'Interrupted swap');
      final service = ProjectBackupService();
      final backup = await service.create(package: package, type: 'manual');
      final assets = package.assetsDirectory;
      final portrait = File('${assets.path}/portrait.txt');
      await portrait.writeAsString('newer portrait');
      final workspaces = Directory('${package.root.path}/workspaces');
      final novel = File('${workspaces.path}/novel.json');
      await novel.writeAsString('{"newer":true}');

      // The honest reproduction of an OS kill inside the placement window is
      // the corpse the kernel leaves behind: journal + verified staging
      // present, live target already gone. A test-zone throw cannot model
      // "no finally ran", so the corpse is written directly from exactly
      // the artifacts production staging produces.
      final stagedAssets = Directory('${assets.path}.tmp');
      await copyTree(Directory('${backup.path}/assets'), stagedAssets);
      final stagedWorkspaces = Directory('${workspaces.path}.tmp');
      await copyTree(Directory('${backup.path}/workspaces'), stagedWorkspaces);
      await workspaces.delete(recursive: true);
      final journal = await RestoreStagingJournal.create(
        package,
        staged: {
          RestoreStagingJournal.assetsArea: stagedAssets,
          RestoreStagingJournal.workspacesArea: stagedWorkspaces,
        },
      );
      expect(await journal.journalFile.exists(), isTrue);

      final healed = await RestoreCrashRecovery.recover(package);

      expect(healed, greaterThanOrEqualTo(2));
      // Roll-forward: the verified staged payload becomes the live payload.
      expect(await portrait.readAsString(), 'live portrait');
      expect(await Directory(workspaces.path).exists(), isTrue);
      expect(await novel.readAsString(), '{"live":true}');
      expect(
        await Directory('${assets.path}.tmp').exists(),
        isFalse,
        reason: 'a rolled-forward staging directory is consumed',
      );
      expect(await Directory('${workspaces.path}.tmp').exists(), isFalse);
      expect(
        await RestoreStagingJournal.load(package),
        isNull,
        reason: 'a completed recovery consumes the journal',
      );
    },
  );

  test(
    'a staged copy that diverged from its journal fingerprint is never '
    'rolled forward: discarded as garbage while live content is kept',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'restore-2phase-diverge-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = await seedPackage(root, name: 'Divergent staging');
      final workspaces = Directory('${package.root.path}/workspaces');
      final novel = File('${workspaces.path}/novel.json');
      final liveBefore = await novel.readAsString();
      final staged = Directory('${workspaces.path}.tmp')
        ..createSync(recursive: true);
      await File('${staged.path}/novel.json').writeAsString('complete stage');
      await RestoreStagingJournal.create(
        package,
        staged: {RestoreStagingJournal.workspacesArea: staged},
      );
      // Corrupt the staged copy AFTER journaling: it no longer matches the
      // recorded fingerprint and cannot be trusted as a restore source.
      await File('${staged.path}/novel.json').writeAsString('torn');

      final healed = await RestoreCrashRecovery.recover(package);

      expect(healed, greaterThan(0));
      expect(
        await novel.readAsString(),
        liveBefore,
        reason:
            'a divergent staging directory must never overwrite live '
            'content; the existing payload is the only truth',
      );
      expect(
        await staged.exists(),
        isFalse,
        reason: 'provably-corrupt scratch is garbage, not evidence to keep',
      );
      expect(await RestoreStagingJournal.load(package), isNull);
    },
  );

  test('a successful restore consumes the journal and leaves no staging '
      'artifacts behind', () async {
    final root = await Directory.systemTemp.createTemp(
      'restore-2phase-success-',
    );
    addTearDown(() => root.delete(recursive: true));
    final package = await seedPackage(root, name: 'Clean success');
    final service = ProjectBackupService();
    final backup = await service.create(package: package, type: 'manual');
    final portrait = File('${package.assetsDirectory.path}/portrait.txt');
    await portrait.writeAsString('newer portrait');

    await service.restore(package: package, backup: backup);

    expect(await portrait.readAsString(), 'live portrait');
    expect(
      await RestoreStagingJournal.load(package),
      isNull,
      reason: 'a completed restore must not leave a journal behind',
    );
    expect(
      await Directory('${package.assetsDirectory.path}.tmp').exists(),
      isFalse,
    );
    expect(
      await Directory('${package.root.path}/workspaces.tmp').exists(),
      isFalse,
    );
    expect(await File('${package.manifestFile.path}.tmp').exists(), isFalse);
    expect(await File('${package.databaseFile.path}.tmp').exists(), isFalse);
  });
}
