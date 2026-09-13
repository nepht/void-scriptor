import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';

ProjectModel _project(String id) {
  final now = DateTime(2026, 1, 1);
  return ProjectModel(
    id: id,
    name: 'Void Universe',
    description: 'Main universe',
    createdAt: now,
    updatedAt: now,
    lastOpenedAt: now,
    localPath: '/tmp/$id',
    version: '0.1.0',
  );
}

void main() {
  test(
    'ProjectModel copyWith preserves fields and replaces selected values',
    () {
      final project = _project('project-1');
      final updated = project.copyWith(name: 'Neo Lyra', tags: ['story']);

      expect(updated.id, 'project-1');
      expect(updated.name, 'Neo Lyra');
      expect(updated.description, project.description);
      expect(updated.tags, ['story']);
    },
  );

  test(
    'ProjectLocalDataSource supports create, read, update, and delete',
    () async {
      final source = ProjectLocalDataSource();
      final project = _project('project-1');

      await source.createProject(project);
      expect(await source.getProject(project.id), project);
      expect((await source.getProjects()).length, 1);

      await source.updateProject(project.copyWith(name: 'Updated'));
      expect((await source.getProject(project.id))!.name, 'Updated');

      await source.deleteProject(project.id);
      expect(await source.getProject(project.id), isNull);
      expect(await source.getProjects(), isEmpty);
    },
  );

  test(
    'ProjectLocalDataSource updateProject upserts an unknown project in memory mode',
    () async {
      // vs-hunt-20260913-projects BUG-1: registry mode upserts, so the memory
      // fallback must not silently drop updates for ids it has never seen.
      final source = ProjectLocalDataSource();
      final project = _project('project-ghost');

      await source.updateProject(project);

      expect(await source.getProject('project-ghost'), project);
      expect(await source.getProjects(), hasLength(1));

      await source.updateProject(project.copyWith(name: 'Later'));
      expect(await source.getProjects(), hasLength(1));
      expect((await source.getProject('project-ghost'))!.name, 'Later');
    },
  );

  test('ProjectLocalDataSource keeps project ids unique', () async {
    final source = ProjectLocalDataSource();

    await source.createProject(_project('project-1'));
    await source.createProject(
      _project('project-1').copyWith(name: 'Replacement'),
    );

    expect(await source.getProjects(), hasLength(1));
    expect((await source.getProject('project-1'))?.name, 'Replacement');
  });
}
