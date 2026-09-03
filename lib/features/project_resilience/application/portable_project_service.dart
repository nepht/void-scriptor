import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/project_package/project_package.dart';
import '../../../core/persistence/project_manifest.dart';
import '../../../core/persistence/project_registry_service.dart';
import '../../../database/project/project_database_service.dart';
import '../../projects/domain/project_model.dart';

class ArchiveManifest {
  const ArchiveManifest({
    required this.projectId,
    required this.sourceSchemaVersion,
    required this.checksum,
  });
  final String projectId;
  final int sourceSchemaVersion;
  final String checksum;
  Map<String, dynamic> toJson() => {
    'format': 'voidproject-archive',
    'version': 1,
    'projectId': projectId,
    'sourceSchemaVersion': sourceSchemaVersion,
    'checksum': checksum,
  };
}

/// Canonical SHA-256 integrity contract for .voidproject archives.
///
/// The checksum covers every archive entry except the archive metadata file
/// itself, ordered by entry name so the value is deterministic across
/// platforms. Import verifies this value before extracting anything.
class ArchiveIntegrity {
  static const String manifestEntryName = 'voidproject.archive.json';

  static String computeContentChecksum(Archive archive) {
    final builder = BytesBuilder(copy: false);
    final entries = archive.where((f) => f.isFile).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final entry in entries) {
      if (entry.name == manifestEntryName) continue;
      final bytes = entry.readBytes();
      if (bytes == null) continue;
      builder.add(utf8.encode(entry.name));
      builder.add(bytes);
    }
    return sha256.convert(builder.toBytes()).toString();
  }

  /// Computes the same content checksum directly over an on-disk directory,
  /// using POSIX-relative entry names. Used by the exporter before zipping so
  /// no re-encode round-trip can change the byte content.
  static Future<String> computeDirectoryChecksum(Directory root) async {
    final builder = BytesBuilder(copy: false);
    final backslash = String.fromCharCodes([92]);
    final files = <String>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) {
        files.add(
          p.relative(entity.path, from: root.path).replaceAll(backslash, '/'),
        );
      }
    }
    files.sort();
    for (final relative in files) {
      if (relative == manifestEntryName) continue;
      final bytes = await File(p.join(root.path, relative)).readAsBytes();
      builder.add(utf8.encode(relative));
      builder.add(bytes);
    }
    return sha256.convert(builder.toBytes()).toString();
  }

  static bool verify(Archive archive) {
    final metaEntry = archive.find(manifestEntryName);
    if (metaEntry == null) return false;
    final metaBytes = metaEntry.readBytes();
    if (metaBytes == null) return false;
    final Map<String, dynamic> meta;
    try {
      meta = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;
    } on FormatException {
      return false;
    }
    final declared = meta['checksum'];
    if (declared is! String || declared.isEmpty) return false;
    return computeContentChecksum(archive) == declared;
  }

  static String empty() => '';
}

class PortableProjectExporter {
  Future<File> exportPortable(
    ProjectPackage package, {
    Directory? destination,
  }) async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await package.manifestFile.readAsString())
          as Map<String, dynamic>,
    );
    final temp = await Directory.systemTemp.createTemp('voidproject-export-');
    try {
      await _copy(
        package.manifestDirectory,
        Directory(p.join(temp.path, 'manifest')),
      );
      await _copy(
        package.databaseDirectory,
        Directory(p.join(temp.path, 'database')),
      );
      await _copy(
        package.assetsDirectory,
        Directory(p.join(temp.path, 'assets')),
      );
      final checksum = await ArchiveIntegrity.computeDirectoryChecksum(temp);
      final archiveMeta = File(p.join(temp.path, 'voidproject.archive.json'));
      await archiveMeta.writeAsString(
        jsonEncode(
          ArchiveManifest(
            projectId: package.projectId,
            sourceSchemaVersion: manifest.schemaVersion,
            checksum: checksum,
          ).toJson(),
        ),
      );
      final outDir = destination ?? package.exportDirectory;
      await outDir.create(recursive: true);
      final output = File(
        p.join(outDir.path, '${package.projectId}.voidproject'),
      );
      await ZipFileEncoder().zipDirectory(temp, filename: output.path);
      final decoded = ZipDecoder().decodeBytes(
        await output.readAsBytes(),
        verify: true,
      );
      if (decoded.find('manifest/project.json') == null ||
          decoded.find('database/project.db') == null) {
        throw StateError('Portable archive verification failed');
      }
      return output;
    } finally {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    }
  }

  Future<void> _copy(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relative = p.relative(entity.path, from: source.path);
      final destination = p.join(target.path, relative);
      if (entity is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entity is File) {
        await File(destination).parent.create(recursive: true);
        await entity.copy(destination);
      }
    }
  }
}

class PortableProjectImporter {
  Future<ProjectPackage> importArchive(
    File archive, {
    required Directory destination,
    bool asCopy = false,
  }) async {
    final decoded = ZipDecoder().decodeBytes(
      await archive.readAsBytes(),
      verify: true,
    );
    final manifestEntry = decoded.find('manifest/project.json');
    final dbEntry = decoded.find('database/project.db');
    if (manifestEntry == null || dbEntry == null) {
      throw const FormatException('Invalid voidproject archive');
    }
    if (!ArchiveIntegrity.verify(decoded)) {
      throw const FormatException('Archive checksum mismatch');
    }
    final manifest = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(manifestEntry.readBytes()!))
          as Map<String, dynamic>,
    );
    final id = asCopy ? const Uuid().v4() : manifest.id;
    final package = ProjectPackage(
      projectId: id,
      root: Directory(p.join(destination.path, '$id.voidproject')),
    );
    try {
      for (final entry in decoded) {
        if (!entry.isFile || entry.name == 'voidproject.archive.json') {
          continue;
        }
        final relative = p.posix.normalize(entry.name);
        if (relative == '..' || relative.startsWith('../')) {
          throw const FormatException('Archive path escapes package');
        }
        final output = File(package.resolve(relative));
        await output.parent.create(recursive: true);
        await output.writeAsBytes(entry.readBytes()!);
      }
      if (asCopy) {
        final rewritten = ProjectManifest(
          schemaVersion: manifest.schemaVersion,
          id: id,
          name: '${manifest.name} (Copy)',
          description: manifest.description,
          projectVersion: manifest.projectVersion,
          createdAt: manifest.createdAt,
          updatedAt: manifest.updatedAt,
          appVersion: manifest.appVersion,
          tags: manifest.tags,
          databaseFilename: manifest.databaseFilename,
        );
        await package.manifestFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(rewritten.toJson()),
        );
        await _rewriteDatabaseProjectId(package, manifest.id, id);
      }
      return package;
    } catch (_) {
      if (await package.root.exists()) {
        await package.root.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _rewriteDatabaseProjectId(
    ProjectPackage package,
    String oldId,
    String newId,
  ) async {
    final database = await ProjectDatabaseService().open(
      package.databaseFile.path,
    );
    try {
      final tables = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      for (final row in tables) {
        final table = row.data['name'] as String;
        final columns = await database
            .customSelect('PRAGMA table_info("$table")')
            .get();
        if (columns.any((column) => column.data['name'] == 'project_id')) {
          await database.customStatement(
            'UPDATE "$table" SET project_id = ? WHERE project_id = ?',
            [newId, oldId],
          );
        }
      }
    } finally {
      await database.close();
    }
  }
}

class PortableProjectImportCoordinator {
  PortableProjectImportCoordinator({
    required this.registry,
    PortableProjectImporter? importer,
  }) : importer = importer ?? PortableProjectImporter();

  final ProjectRegistryService registry;
  final PortableProjectImporter importer;

  Future<ProjectPackage> importAndRegister(
    File archive, {
    required Directory destination,
    bool asCopy = false,
  }) async {
    final package = await importer.importArchive(
      archive,
      destination: destination,
      asCopy: asCopy,
    );
    try {
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await package.manifestFile.readAsString())
            as Map<String, dynamic>,
      );
      final now = DateTime.now().toUtc();
      await registry.upsert(
        ProjectModel(
          id: manifest.id,
          name: manifest.name,
          description: manifest.description,
          createdAt: manifest.createdAt,
          updatedAt: manifest.updatedAt,
          lastOpenedAt: now,
          localPath: package.root.path,
          version: manifest.projectVersion,
          tags: manifest.tags,
        ),
      );
      return package;
    } catch (_) {
      if (await package.root.exists()) {
        await package.root.delete(recursive: true);
      }
      rethrow;
    }
  }
}
