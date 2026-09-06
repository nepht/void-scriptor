import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-s24-recovery-'),
  );
  tearDown(() => root.delete(recursive: true));

  test('session lock detects crash and releases on clean close', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Recovery');
    final lock = ProjectSessionLock(package);
    await lock.acquire();
    expect(await lock.hasCrashMarker, isTrue);
    await lock.release();
    expect(await lock.hasCrashMarker, isFalse);
  });

  test(
    'backup restore, cache clear, and trash restore preserve project safety',
    () async {
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Recovery');
      final source = File('${package.assetsDirectory.path}/images/file.txt')
        ..parent.createSync(recursive: true);
      await source.writeAsString('before');
      final workspaceSource = File(
        '${package.root.path}/workspaces/novels/novel-1/drafts/chapter.md',
      )..parent.createSync(recursive: true);
      await workspaceSource.writeAsString('workspace-before');
      final backup = await ProjectBackupService().create(
        package: package,
        type: 'manual',
      );
      await source.writeAsString('after');
      await workspaceSource.writeAsString('workspace-after');
      await ProjectBackupService().restore(package: package, backup: backup);
      expect(await source.readAsString(), 'before');
      expect(await workspaceSource.readAsString(), 'workspace-before');

      final backupDatabase = File(p.join(backup.path, 'project.db'));
      await backupDatabase.writeAsBytes(<int>[0, 1, 2, 3]);
      expect(
        () => ProjectBackupService().restore(package: package, backup: backup),
        throwsA(isA<BackupIntegrityException>()),
      );

      await File('${package.cacheDirectory.path}/temp').writeAsString('cache');

      await ProjectCacheService(package).clear();
      expect(
        await Directory('${package.cacheDirectory.path}/temp').exists(),
        isFalse,
      );
      final trashed = await ProjectTrashService(package).moveToTrash(source);
      expect(await source.exists(), isFalse);
      final metadata =
          jsonDecode(
                await File(
                  p.join(
                    package.trashDirectory.path,
                    '${p.basenameWithoutExtension(trashed.path)}.json',
                  ),
                ).readAsString(),
              )
              as Map<String, dynamic>;
      expect(metadata['originalPath'], 'assets/images/file.txt');
      expect(metadata['trashPath'], startsWith('trash/files/'));
      await ProjectTrashService(package).restore(trashed, source.path);
      expect(await source.exists(), isTrue);
    },
  );

  test('backup integrity rejects a tampered workspace file', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Workspace Integrity');
    final source = File(
      p.join(
        package.root.path,
        'workspaces',
        'novels',
        'novel-1',
        'drafts',
        'chapter.md',
      ),
    );
    await source.parent.create(recursive: true);
    await source.writeAsString('trusted');
    final backup = await ProjectBackupService().create(
      package: package,
      type: 'migration',
    );
    await File(
      p.join(
        backup.path,
        'workspaces',
        'novels',
        'novel-1',
        'drafts',
        'chapter.md',
      ),
    ).writeAsString('tampered');

    await expectLater(
      ProjectBackupService().restore(package: package, backup: backup),
      throwsA(
        isA<BackupIntegrityException>().having(
          (error) => error.message,
          'message',
          'Workspace backup checksum mismatch',
        ),
      ),
    );
  });
}
