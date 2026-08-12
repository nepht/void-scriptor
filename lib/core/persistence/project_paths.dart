import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class ProjectPaths {
  ProjectPaths({Directory? rootDirectory}) : _rootOverride = rootDirectory;

  final Directory? _rootOverride;

  Future<Directory> root() async {
    final directory =
        _rootOverride ??
        Directory(p.join(await _documentsPath(), 'VoidScriptor', 'Projects'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> _documentsPath() async {
    try {
      return (await getApplicationDocumentsDirectory()).path;
    } catch (_) {
      return p.join(Directory.systemTemp.path, 'void-scriptor-test');
    }
  }

  Future<Directory> project(String projectId) async =>
      Directory(p.join((await root()).path, projectId));

  Future<File> manifest(String projectId) async =>
      File(p.join((await project(projectId)).path, 'project.json'));

  Future<File> database(String projectId) async =>
      File(p.join((await project(projectId)).path, 'project.db'));

  Future<File> registry() async => File(
    p.join(
      _rootOverride == null ? (await root()).parent.path : (await root()).path,
      'projects.json',
    ),
  );
}
