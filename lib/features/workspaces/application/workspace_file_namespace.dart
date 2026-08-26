import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';

final class WorkspaceFileNamespace {
  WorkspaceFileNamespace(this.package);

  final ProjectPackage package;

  String get packageRoot => package.root.path;

  Directory get novelRoot =>
      Directory(p.join(package.root.path, 'workspaces', 'novels'));

  Directory get characterRoot =>
      Directory(p.join(package.root.path, 'workspaces', 'characters'));

  Directory novelDirectory(String novelWorkspaceId) =>
      _typedWorkspaceDirectory(novelRoot, novelWorkspaceId, 'novelWorkspaceId');

  Directory characterDirectory(String characterWorkspaceId) =>
      _typedWorkspaceDirectory(
        characterRoot,
        characterWorkspaceId,
        'characterWorkspaceId',
      );

  File novelFile(String novelWorkspaceId, String relativePath) =>
      File(_resolveInside(novelDirectory(novelWorkspaceId).path, relativePath));

  File characterFile(String characterWorkspaceId, String relativePath) => File(
    _resolveInside(characterDirectory(characterWorkspaceId).path, relativePath),
  );

  Future<File> createNovelFile(String novelWorkspaceId, String relativePath) =>
      _createTypedFile(novelFile(novelWorkspaceId, relativePath));

  Future<File> createCharacterFile(
    String characterWorkspaceId,
    String relativePath,
  ) => _createTypedFile(characterFile(characterWorkspaceId, relativePath));

  /// Legacy untyped namespace retained for package compatibility only.
  /// New Novel/Character flows must use the typed methods below.
  Directory workspaceDirectory(String workspaceId) {
    _validateIdentifier(workspaceId, field: 'workspaceId');
    return Directory(p.join(package.root.path, 'workspaces', workspaceId));
  }

  Future<Directory> ensureWorkspace(String workspaceId) async {
    final directory = workspaceDirectory(workspaceId);
    await directory.create(recursive: true);
    return directory;
  }

  File file(String workspaceId, String relativePath) {
    final workspace = workspaceDirectory(workspaceId);
    final resolved = _resolveInside(workspace.path, relativePath);
    return File(resolved);
  }

  Future<File> createFile(String workspaceId, String relativePath) async {
    final target = file(workspaceId, relativePath);
    await target.parent.create(recursive: true);
    return target;
  }

  Directory _typedWorkspaceDirectory(
    Directory root,
    String workspaceId,
    String field,
  ) {
    _validateIdentifier(workspaceId, field: field);
    return Directory(p.join(root.path, workspaceId));
  }

  Future<File> _createTypedFile(File target) async {
    await target.parent.create(recursive: true);
    return target;
  }

  bool isInsideWorkspace(String workspacePath, String relativePath) {
    final workspace = p.normalize(p.absolute(workspacePath));
    final resolved = _resolveInside(workspace, relativePath);
    final relative = p.relative(resolved, from: workspace);
    return relative != '..' && !relative.startsWith('..${p.separator}');
  }

  String _resolveInside(String workspacePath, String relativePath) {
    if (relativePath.trim().isEmpty || p.isAbsolute(relativePath)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must be a non-empty relative path',
      );
    }
    final workspace = p.normalize(p.absolute(workspacePath));
    final resolved = p.normalize(p.absolute(workspace, relativePath));
    final relative = p.relative(resolved, from: workspace);
    if (relative == '..' || relative.startsWith('..${p.separator}')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'escapes workspace root',
      );
    }
    return resolved;
  }

  static bool isValidWorkspaceIdentifier(String value) =>
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$').hasMatch(value);

  void _validateIdentifier(String value, {required String field}) {
    if (!isValidWorkspaceIdentifier(value)) {
      throw ArgumentError.value(
        value,
        field,
        'must be a safe workspace identifier',
      );
    }
  }
}
