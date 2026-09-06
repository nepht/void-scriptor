import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  test('schema v53 includes job_dependencies table', () async {
    final dir = Directory.systemTemp.createTempSync('vs_jobdep_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));

    await db
        .into(db.jobDependencies)
        .insert(
          JobDependenciesCompanion.insert(
            jobId: 'parent-1',
            dependsOnId: 'child-1',
          ),
        );

    final rows = await db.select(db.jobDependencies).get();
    expect(rows.length, 1);
    expect(rows.single.jobId, 'parent-1');
    expect(rows.single.dependsOnId, 'child-1');

    await db.close();
  });

  test('schema version is 58', () {
    expect(ProjectDatabase.currentSchemaVersion, 59);
  });
}
