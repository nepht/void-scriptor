import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/project_package/project_package.dart';
import '../../../core/project_package/void_project_format.dart';
import '../../../database/project/project_database.dart';

class ProjectSessionLock {
  ProjectSessionLock(this.package);
  final ProjectPackage package;
  Future<void> acquire({String? appVersion}) async {
    if (await package.sessionFile.exists()) {
      throw StateError('Project has an active or stale session');
    }
    await package.sessionFile.writeAsString(
      jsonEncode({
        'sessionId': const Uuid().v4(),
        'projectId': package.projectId,
        'openedAt': DateTime.now().toUtc().toIso8601String(),
        'appVersion': appVersion ?? VoidProjectFormat.applicationVersion,
      }),
    );
  }

  Future<void> release() async {
    if (await package.sessionFile.exists()) await package.sessionFile.delete();
  }

  Future<bool> get hasCrashMarker async => package.sessionFile.exists();
}

class ProjectBackupService {
  Future<Directory> create({
    required ProjectPackage package,
    required String type,
    String note = '',
  }) async {
    final id = const Uuid().v4();
    final target = Directory(p.join(package.backupDirectory.path, id));
    await target.create(recursive: true);
    await File(
      p.join(target.path, 'project.json'),
    ).writeAsBytes(await package.manifestFile.readAsBytes());
    await File(
      p.join(target.path, 'project.db'),
    ).writeAsBytes(await package.databaseFile.readAsBytes());
    await File(p.join(target.path, 'backup.json')).writeAsString(
      jsonEncode({
        'id': id,
        'projectId': package.projectId,
        'type': type,
        'schemaVersion': ProjectDatabase.currentSchemaVersion,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'note': note,
      }),
    );
    return target;
  }

  Future<void> restore({
    required ProjectPackage package,
    required Directory backup,
  }) async {
    final emergency = await create(
      package: package,
      type: 'pre-restore',
      note: 'Emergency backup before restore',
    );
    try {
      await package.manifestFile.writeAsBytes(
        await File(p.join(backup.path, 'project.json')).readAsBytes(),
      );
      await package.databaseFile.writeAsBytes(
        await File(p.join(backup.path, 'project.db')).readAsBytes(),
      );
    } catch (_) {
      await package.manifestFile.writeAsBytes(
        await File(p.join(emergency.path, 'project.json')).readAsBytes(),
      );
      await package.databaseFile.writeAsBytes(
        await File(p.join(emergency.path, 'project.db')).readAsBytes(),
      );
      rethrow;
    }
  }
}

class ProjectCacheService {
  const ProjectCacheService(this.package);
  final ProjectPackage package;
  Future<void> clear() async {
    if (!await package.cacheDirectory.exists()) return;
    await for (final entity in package.cacheDirectory.list()) {
      await entity.delete(recursive: true);
    }
  }
}

class ProjectTrashService {
  const ProjectTrashService(this.package);
  final ProjectPackage package;
  Future<File> moveToTrash(File source, {String? entityId}) async {
    final sourceAbsolute = p.normalize(p.absolute(source.path));
    final packageRoot = p.normalize(p.absolute(package.root.path));
    if (!p.isWithin(packageRoot, sourceAbsolute)) {
      throw ArgumentError.value(
        source.path,
        'source',
        'must be inside project',
      );
    }
    final id = const Uuid().v4();
    final target = File(
      p.join(
        package.trashDirectory.path,
        'files',
        '$id${p.extension(source.path)}',
      ),
    );
    await target.parent.create(recursive: true);
    await source.rename(target.path);
    await File(p.join(package.trashDirectory.path, '$id.json')).writeAsString(
      jsonEncode({
        'id': id,
        'originalPath': p
            .relative(sourceAbsolute, from: packageRoot)
            .replaceAll('\\', '/'),
        'trashPath': p
            .relative(target.path, from: packageRoot)
            .replaceAll('\\', '/'),
        'entityId': entityId,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return target;
  }

  Future<void> restore(File trashed, String originalPath) async {
    final target = File(originalPath);
    await target.parent.create(recursive: true);
    await trashed.rename(target.path);
  }
}
