import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide LayoutPreset;
import 'package:void_scriptor/features/workspace_layout/application/layout_preset_repository.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_model.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_preset.dart';

void main() {
  test('schema version is 50', () {
    expect(ProjectDatabase.currentSchemaVersion, 50);
  });

  test('layout_presets and project_layout_states roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    await db.initialize();
    addTearDown(() => db.close());

    // layout_presets
    await db
        .into(db.layoutPresets)
        .insert(
          LayoutPresetsCompanion.insert(
            id: 'preset-1',
            projectId: 'p1',
            name: 'Wide',
            json: '{"leftWidth":300}',
          ),
        );
    final presets = await db.select(db.layoutPresets).get();
    expect(presets.single.name, 'Wide');

    // project_layout_states
    await db
        .into(db.projectLayoutStates)
        .insert(
          ProjectLayoutStatesCompanion.insert(
            projectId: 'p1',
            json: '{"splitRatio":0.6}',
          ),
        );
    final states = await db.select(db.projectLayoutStates).get();
    expect(states.single.json, '{"splitRatio":0.6}');
  });

  group('DriftLayoutPresetRepository', () {
    late ProjectDatabase db;
    late DriftLayoutPresetRepository repo;

    setUp(() async {
      db = ProjectDatabase(NativeDatabase.memory());
      await db.initialize();
      repo = DriftLayoutPresetRepository(db);
    });

    tearDown(() => db.close());

    test('save + list + delete roundtrip', () async {
      const preset = LayoutPreset(
        name: 'Narrow',
        layout: PanelLayout(
          leftWidth: 200,
          rightWidth: 250,
          leftCollapsed: true,
          rightCollapsed: false,
          splitRatio: 0.5,
        ),
      );

      await repo.save('p1', preset);
      final list = await repo.list('p1');
      expect(list.length, 1);
      expect(list.single.name, 'Narrow');
      expect(list.single.layout.leftWidth, 200);

      await repo.delete('p1', 'Narrow');
      expect(await repo.list('p1'), isEmpty);
    });

    test('persist + restore active layout', () async {
      const layout = PanelLayout(
        leftWidth: 220,
        rightWidth: 290,
        leftCollapsed: false,
        rightCollapsed: true,
        splitRatio: 0.4,
      );

      await repo.persist('p1', layout);
      final restored = await repo.restore('p1');
      expect(restored, layout);
    });

    test('restore returns null when nothing persisted', () async {
      expect(await repo.restore('unknown-project'), isNull);
    });
  });
}
