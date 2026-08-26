import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_file_namespace.dart';

void main() {
  test(
    'creates an isolated workspace directory inside the project package',
    () async {
      final root = await Directory.systemTemp.createTemp('s109-workspace-fs-');
      addTearDown(() => root.delete(recursive: true));
      final package = ProjectPackage(
        projectId: 'project-1',
        root: Directory('${root.path}/project-1.voidproject'),
      );
      final namespace = WorkspaceFileNamespace(package);

      final workspace = await namespace.ensureWorkspace(
        'character-workspace-1',
      );
      expect(
        workspace.path,
        '${package.root.path}/workspaces/character-workspace-1',
      );
      expect(await workspace.exists(), isTrue);
      expect(
        namespace.isInsideWorkspace(workspace.path, 'portrait.png'),
        isTrue,
      );
    },
  );

  test(
    'rejects traversal, absolute paths, and invalid workspace identifiers',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's109-workspace-security-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = ProjectPackage(projectId: 'project-1', root: root);
      final namespace = WorkspaceFileNamespace(package);

      expect(
        () => namespace.workspaceDirectory('../outside'),
        throwsArgumentError,
      );
      expect(
        () => namespace.workspaceDirectory('/tmp/outside'),
        throwsArgumentError,
      );
      expect(
        () => namespace.workspaceDirectory('workspace/child'),
        throwsArgumentError,
      );
      expect(
        () => namespace.file('workspace-1', '../escape.txt'),
        throwsArgumentError,
      );
      expect(
        () => namespace.file('workspace-1', '/tmp/escape.txt'),
        throwsArgumentError,
      );
    },
  );

  test('workspace file lifecycle cannot escape its workspace root', () async {
    final root = await Directory.systemTemp.createTemp(
      's109-workspace-lifecycle-',
    );
    addTearDown(() => root.delete(recursive: true));
    final package = ProjectPackage(projectId: 'project-1', root: root);
    final namespace = WorkspaceFileNamespace(package);

    final file = await namespace.createFile('novel-1', 'exports/novel.json');
    await file.writeAsString('{"id":"novel-1"}');

    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), contains('novel-1'));
    expect(
      file.path.startsWith('${package.root.path}/workspaces/novel-1/'),
      isTrue,
    );
  });

  test(
    'uses distinct persistence namespaces for Novel and Character',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'workspace-typed-namespace-',
      );
      addTearDown(() => root.delete(recursive: true));
      final package = ProjectPackage(
        projectId: 'project-1',
        root: Directory('${root.path}/project-1.voidproject'),
      );
      final namespace = WorkspaceFileNamespace(package);

      final novel = await namespace.createNovelFile(
        'novel-1',
        'drafts/chapter-1.md',
      );
      final character = await namespace.createCharacterFile(
        'character-1',
        'profile/identity.json',
      );

      expect(
        novel.path,
        contains('/workspaces/novels/novel-1/drafts/chapter-1.md'),
      );
      expect(
        character.path,
        contains('/workspaces/characters/character-1/profile/identity.json'),
      );
      expect(novel.path, isNot(startsWith(namespace.characterRoot.path)));
      expect(character.path, isNot(startsWith(namespace.novelRoot.path)));
    },
  );
}
