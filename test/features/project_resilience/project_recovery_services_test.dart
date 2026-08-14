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
      final backup = await ProjectBackupService().create(
        package: package,
        type: 'manual',
      );
      await source.writeAsString('after');
      await ProjectBackupService().restore(package: package, backup: backup);
      expect(await source.readAsString(), 'after');
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
}
