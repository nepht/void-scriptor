import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  test('background job persists and survives database reopen', () async {
    final root = await Directory.systemTemp.createTemp('s26-jobs-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}${Platform.pathSeparator}project.db';
    final service = ProjectDatabaseService();
    await service.create(path);
    final first = await service.open(path);
    addTearDown(first.close);

    expect(first.schemaVersion, 36);
    await first.backgroundJobDao.insertJob(
      BackgroundJobsCompanion.insert(
        id: 'job-export-1',
        projectId: 'project-1',
        type: 'export',
        label: 'Export project',
        status: 'queued',
        priority: 'high',
        createdAt: DateTime.utc(2026, 8, 15),
        payload: const Value('{"format":"voidproject"}'),
      ),
    );
    await first.close();

    final second = await service.open(path);
    addTearDown(second.close);
    final rows = await second.backgroundJobDao.listProjectJobs('project-1');
    expect(rows, hasLength(1));
    expect(rows.single.id, 'job-export-1');
    expect(rows.single.payload, '{"format":"voidproject"}');
  });
}
