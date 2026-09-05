import 'dart:convert';
import 'dart:io';

import '../domain/project_model.dart';
import 'project_recovery_service.dart';
import 'project_paths.dart';

class ProjectRegistryService {
  ProjectRegistryService({Directory? rootDirectory, this.paths})
    : file = rootDirectory == null
          ? null
          : File('${rootDirectory.path}${Platform.pathSeparator}projects.json');

  final File? file;
  final ProjectPaths? paths;
  final ProjectRecoveryService _recovery = const ProjectRecoveryService();

  Future<File> get _registryFile async {
    final configuredPaths = paths;
    final configuredFile = file;
    if (configuredPaths != null) return configuredPaths.registry();
    if (configuredFile != null) return configuredFile;
    throw StateError('ProjectRegistryService requires rootDirectory or paths');
  }

  Future<List<ProjectModel>> load() async {
    final file = await _registryFile;
    // 145.42 power-loss window: pulihkan registry dari .bak sebelum
    // melaporkan daftar proyek kosong.
    await _recovery.recoverIfInterrupted(file);
    if (!await file.exists()) return const [];
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported project registry schema version: $schemaVersion',
      );
    }
    final projects = decoded['projects'] as List<dynamic>? ?? const [];
    return projects
        .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> save(List<ProjectModel> projects) async {
    final file = await _registryFile;
    await file.parent.create(recursive: true);
    final json = {
      'schemaVersion': 1,
      'projects': projects.map((project) => project.toJson()).toList(),
    };
    await _recovery.atomicWrite(
      target: file,
      content: '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }

  Future<void> upsert(ProjectModel project) async {
    final projects = [...await load()];
    final index = projects.indexWhere((item) => item.id == project.id);
    if (index == -1) {
      projects.add(project);
    } else {
      projects[index] = project;
    }
    await save(projects);
  }

  Future<void> remove(String projectId) async {
    await save((await load()).where((item) => item.id != projectId).toList());
  }
}
