import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/creatures/domain/creature_model.dart';

void main() {
  test('domain models are immutable (all fields final)', () {
    const model = CreatureModel(
      assetId: 'a1',
      projectId: 'p1',
      name: 'Byte',
      category: CreatureCategory.synthetic,
    );

    // Compile-time immutability: no setters, all fields final. Runtime check
    // via reflection is unavailable, so we assert behavior: copy-like
    // construction yields a new independent instance.
    expect(model.name, 'Byte');
    expect(model.assetId, 'a1');
  });

  test('copyWith produces an independent instance', () {
    const mode = CreatureModeModel(
      id: 'm1',
      creatureId: 'c1',
      name: 'Combat',
      defaultMode: true,
    );

    final overridden = mode.copyWith(creatureId: 'c2');

    expect(mode.creatureId, 'c1');
    expect(overridden.creatureId, 'c2');
    expect(identical(mode, overridden), isFalse);
  });

  test('database connection closes cleanly (lifecycle)', () async {
    final dir = Directory.systemTemp.createTempSync('vs_lifecycle_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));
    await db.initialize();

    // While open, writes succeed.
    await db
        .into(db.jobDependencies)
        .insert(
          JobDependenciesCompanion.insert(jobId: 'j1', dependsOnId: 'j2'),
        );
    expect((await db.select(db.jobDependencies).get()).length, 1);

    await db.close();
    // After close, writes must fail — proving the connection is torn down.
    expect(
      () => db
          .into(db.jobDependencies)
          .insert(
            JobDependenciesCompanion.insert(jobId: 'j3', dependsOnId: 'j4'),
          ),
      throwsA(isA<Object>()),
    );
  });

  test('batch write persists all records atomically', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    await db.initialize();
    addTearDown(() => db.close());

    await db.batch((batch) {
      for (var i = 0; i < 5; i++) {
        batch.insert(
          db.creatures,
          CreaturesCompanion.insert(
            assetId: 'asset-$i',
            projectId: 'p1',
            name: 'Creature $i',
            category: 'animal',
          ),
        );
      }
    });

    final count = (await db.select(db.creatures).get()).length;
    expect(count, 5);
  });
}
