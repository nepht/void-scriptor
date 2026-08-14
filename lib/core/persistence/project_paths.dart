import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class ProjectPaths {
  ProjectPaths({
    Directory? rootDirectory,
    Future<String> Function()? documentsPath,
    Future<String?> Function()? supportPath,
  }) : _rootOverride = rootDirectory,
       _documentsPathOverride = documentsPath,
       _supportPathOverride = supportPath;

  final Directory? _rootOverride;
  final Future<String> Function()? _documentsPathOverride;
  final Future<String?> Function()? _supportPathOverride;

  Future<Directory> root() async {
    final override = _rootOverride;
    if (override != null) {
      await override.create(recursive: true);
      return override;
    }

    final candidates = <String?>[
      await _documentsPath(),
      await _supportPath(),
      p.join(Directory.systemTemp.path, 'VoidScriptor', 'Projects'),
    ];
    Object? lastError;
    for (final candidate in candidates) {
      if (candidate == null || candidate.isEmpty) continue;
      final directory = Directory(
        p.join(candidate, 'VoidScriptor', 'Projects'),
      );
      try {
        await directory.create(recursive: true);
        return directory;
      } on FileSystemException catch (error) {
        lastError = error;
      }
    }
    throw StateError('Unable to create a writable project root: $lastError');
  }

  Future<String> _documentsPath() async {
    final override = _documentsPathOverride;
    if (override != null) return override();
    try {
      return (await getApplicationDocumentsDirectory()).path;
    } catch (_) {
      return '';
    }
  }

  Future<String?> _supportPath() async {
    final override = _supportPathOverride;
    if (override != null) return override();
    try {
      return (await getApplicationSupportDirectory()).path;
    } catch (_) {
      return null;
    }
  }

  Future<Directory> project(String projectId) async =>
      Directory(p.join((await root()).path, '$projectId.voidproject'));

  Future<File> manifest(String projectId) async =>
      File(p.join((await project(projectId)).path, 'manifest', 'project.json'));

  Future<File> database(String projectId) async =>
      File(p.join((await project(projectId)).path, 'database', 'project.db'));

  Future<File> registry() async => File(
    p.join(
      _rootOverride == null ? (await root()).parent.path : (await root()).path,
      'projects.json',
    ),
  );
}
