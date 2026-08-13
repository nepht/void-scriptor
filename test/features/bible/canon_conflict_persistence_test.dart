import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/bible/application/canon_conflict_repository.dart';
import 'package:void_scriptor/features/bible/domain/canon_conflict.dart';

void main() {
  test('canon conflicts persist and can be resolved with a note', () async {
    final root = await Directory.systemTemp.createTemp('s21-conflicts-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/project.db';
    final service = ProjectDatabaseService();
    await service.create(path);
    final first = await service.open(path);
    final repository = CanonConflictRepository(first);
    await repository.save(
      const CanonConflict(
        id: 'conflict-1',
        projectId: 'project-1',
        ruleId: 'rule-1',
        targetId: 'scene-18',
        message: 'Purple visual effect conflicts with Void Black.',
        severity: CanonConflictSeverity.error,
      ),
    );
    await repository.resolve('conflict-1', 'Intentional alternate timeline.');
    await first.close();

    final second = await service.open(path);
    addTearDown(second.close);
    final conflicts = await CanonConflictRepository(second).list('project-1');

    expect(second.schemaVersion, 24);
    expect(conflicts.single.resolved, isTrue);
    expect(conflicts.single.resolutionNote, 'Intentional alternate timeline.');
  });
}
