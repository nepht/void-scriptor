import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_paths.dart';

class ProjectFileService {
  ProjectFileService({ProjectPaths? paths, Directory? rootDirectory})
    : _paths = paths ?? ProjectPaths(rootDirectory: rootDirectory);

  final ProjectPaths _paths;

  static const requiredFolders = [
    'assets',
    'assets/characters',
    'assets/wardrobe',
    'assets/weapons',
    'assets/creatures',
    'assets/vehicles',
    'assets/environments',
    'assets/audio',
    'assets/references',
    'story',
    'environments',
    'thumbnails',
    'exports',
    'cache',
    'backups',
    'recovery',
  ];

  Future<Directory> createStructure(String projectId) async {
    final directory = await _paths.project(projectId);
    await directory.create(recursive: true);
    for (final folder in requiredFolders) {
      await Directory(p.join(directory.path, folder)).create(recursive: true);
    }
    return directory;
  }
}
