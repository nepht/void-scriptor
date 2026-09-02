import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import '../../../core/project_package/project_package.dart';
import '../../../database/project/project_database.dart';
import '../../../database/project/tables/project_resilience.dart';

part 'project_resilience_repository.g.dart';

enum ProjectFileLocation { internal, external, missing }

class ProjectFileReference {
  const ProjectFileReference({
    required this.path,
    required this.location,
    this.contentHash,
  });
  final String path;
  final ProjectFileLocation location;
  final String? contentHash;
}

class ProjectIntegrityReport {
  const ProjectIntegrityReport({
    required this.manifestValid,
    required this.databaseValid,
    required this.missingFiles,
    required this.externalFiles,
    required this.orphanFiles,
  });
  final bool manifestValid;
  final bool databaseValid;
  final int missingFiles;
  final int externalFiles;
  final int orphanFiles;
  bool get portable =>
      manifestValid && databaseValid && missingFiles == 0 && externalFiles == 0;
}

class BackupRetentionPolicy {
  const BackupRetentionPolicy({this.maxAutomatic = 20, this.maxManual = 50});
  final int maxAutomatic;
  final int maxManual;
}

@DriftAccessor(
  tables: [
    ExternalFiles,
    ProjectBackups,
    CacheEntries,
    TrashEntries,
    ProjectMigrationHistory,
  ],
)
class ProjectResilienceRepository extends DatabaseAccessor<ProjectDatabase>
    with _$ProjectResilienceRepositoryMixin {
  ProjectResilienceRepository(super.attachedDatabase);

  Future<void> addExternal(ExternalFilesCompanion value) =>
      into(externalFiles).insert(value);
  Future<List<ExternalFile>> externalFor(String projectId) => (select(
    externalFiles,
  )..where((t) => t.projectId.equals(projectId))).get();
  Future<void> markExternalAvailable(String id, bool value) =>
      (update(externalFiles)..where((t) => t.id.equals(id))).write(
        ExternalFilesCompanion(available: Value(value)),
      );
  Future<void> addBackup(ProjectBackupsCompanion value) =>
      into(projectBackups).insert(value);
  Future<void> removeBackup(String id) =>
      (delete(projectBackups)..where((t) => t.id.equals(id))).go();
  Future<List<ProjectBackup>> backupsFor(String projectId) =>
      (select(projectBackups)
            ..where((t) => t.projectId.equals(projectId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
  Future<void> addCache(CacheEntriesCompanion value) =>
      into(cacheEntries).insertOnConflictUpdate(value);
  Future<void> clearCache() => delete(cacheEntries).go();
  Future<void> addTrash(TrashEntriesCompanion value) =>
      into(trashEntries).insert(value);
  Future<List<TrashEntry>> trash() => select(trashEntries).get();
  Future<void> addMigration(ProjectMigrationHistoryCompanion value) =>
      into(projectMigrationHistory).insert(value);
}

class ProjectFileReferenceService {
  const ProjectFileReferenceService(this.package);
  final ProjectPackage package;

  ProjectFileReference resolve(String storedPath) {
    final normalized = storedPath.replaceAll('\\', '/');
    if (p.isAbsolute(storedPath)) {
      final file = File(storedPath);
      return ProjectFileReference(
        path: storedPath,
        location: file.existsSync()
            ? ProjectFileLocation.external
            : ProjectFileLocation.missing,
      );
    }
    final file = File(package.resolve(normalized));
    return ProjectFileReference(
      path: normalized,
      location: file.existsSync()
          ? ProjectFileLocation.internal
          : ProjectFileLocation.missing,
    );
  }

  String? toRelative(String candidate) {
    final absolute = p.normalize(p.absolute(candidate));
    final root = p.normalize(p.absolute(package.root.path));
    if (p.isWithin(root, absolute) || absolute == root) {
      return p.relative(absolute, from: root).replaceAll('\\', '/');
    }
    return null;
  }

  Future<String> hash(File file) async =>
      sha256.convert(await file.readAsBytes()).toString();
}
