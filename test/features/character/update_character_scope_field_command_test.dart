import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/application/update_character_scope_field_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_scope_layers.dart';

/// Step 145.26 Character Scope Layers - scoped command integration slice.
/// Contract (core_mvp_scope_reset_spec.json character_model):
///   override_never_silently_mutates_canonical: true;
///   a scoped edit writes ONLY its owned layer, ONLY its owned field,
///   and never silently clears sibling fields in the same layer.
void main() {
  Future<(ProjectPaths, CharacterRepositoryImpl)> setup(String tag) async {
    final root = await Directory.systemTemp.createTemp('s26-scope-cmd-$tag-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final databaseFile = await paths.database('p1');
    await service.create(databaseFile.path);
    final database = await service.open(databaseFile.path);
    addTearDown(database.close);
    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: 'p1',
      paths: paths,
    );
    return (paths, repository);
  }

  test(
    'command writes only its owned field, preserving sibling fields',
    () async {
      final (_, repo) = await setup('write');
      final character = await repo.createCharacter(name: 'Qowner');
      final id = character.assetId;

      await repo.updateScopeState(
        id,
        CharacterScopeLayer.canonical,
        const CharacterScopeState(identity: 'identitas-kanon'),
      );
      await repo.updateScopeState(
        id,
        CharacterScopeLayer.novelSpecific,
        const CharacterScopeState(role: 'role-lama', arc: 'arc-lama'),
      );

      final command = UpdateCharacterScopeFieldCommand(
        id: 'scope-write-1',
        projectId: 'p1',
        repository: repo,
        characterId: id,
        targetLayer: CharacterScopeLayer.novelSpecific,
        field: 'ROLE',
        oldValue: 'role-lama',
        newValue: 'role-baru',
      );

      await command.execute();
      var states = await repo.getScopeStates(id);
      expect(states[CharacterScopeLayer.novelSpecific]!.role, 'role-baru');
      // sibling in the same layer is preserved
      expect(states[CharacterScopeLayer.novelSpecific]!.arc, 'arc-lama');
      // canonical layer untouched
      expect(
        states[CharacterScopeLayer.canonical]!.identity,
        'identitas-kanon',
      );
      expect(states[CharacterScopeLayer.canonical]!.role, isNull);

      await command.undo();
      states = await repo.getScopeStates(id);
      expect(states[CharacterScopeLayer.novelSpecific]!.role, 'role-lama');
      expect(states[CharacterScopeLayer.novelSpecific]!.arc, 'arc-lama');

      await command.redo();
      states = await repo.getScopeStates(id);
      expect(states[CharacterScopeLayer.novelSpecific]!.role, 'role-baru');
      expect(states[CharacterScopeLayer.novelSpecific]!.arc, 'arc-lama');
    },
  );

  test(
    'command rejects a field not owned by the layer before any write',
    () async {
      final (_, repo) = await setup('reject');
      final character = await repo.createCharacter(name: 'Qowner');
      final id = character.assetId;

      await repo.updateScopeState(
        id,
        CharacterScopeLayer.novelSpecific,
        const CharacterScopeState(role: 'role-lama', arc: 'arc-lama'),
      );

      final command = UpdateCharacterScopeFieldCommand(
        id: 'scope-reject-1',
        projectId: 'p1',
        repository: repo,
        characterId: id,
        targetLayer: CharacterScopeLayer.novelSpecific,
        field: 'ALTERNATE_HISTORY',
        oldValue: null,
        newValue: 'rewritten history',
      );

      await expectLater(command.execute(), throwsArgumentError);
      // nothing was written, siblings intact
      final states = await repo.getScopeStates(id);
      expect(states[CharacterScopeLayer.novelSpecific]!.role, 'role-lama');
      expect(states[CharacterScopeLayer.novelSpecific]!.arc, 'arc-lama');
      expect(
        states[CharacterScopeLayer.novelSpecific]!.alternateHistory,
        isNull,
      );
    },
  );

  test(
    'clearing a novel override nulls only that field and preserves siblings',
    () async {
      final (_, repo) = await setup('clear');
      final character = await repo.createCharacter(name: 'Qowner');
      final id = character.assetId;

      // canonical layer owns IDENTITY/BASE_* only (disjoint ownership contract)
      await repo.updateScopeState(
        id,
        CharacterScopeLayer.canonical,
        const CharacterScopeState(
          identity: 'identitas-kanon',
          baseVoice: 'tenang',
        ),
      );
      await repo.updateScopeState(
        id,
        CharacterScopeLayer.novelSpecific,
        const CharacterScopeState(role: 'antagonis', currentStatus: 'Dead'),
      );

      final command = UpdateCharacterScopeFieldCommand(
        id: 'scope-clear-1',
        projectId: 'p1',
        repository: repo,
        characterId: id,
        targetLayer: CharacterScopeLayer.novelSpecific,
        field: 'CURRENT_STATUS',
        oldValue: 'Dead',
        newValue: null,
      );

      await command.execute();
      final states = await repo.getScopeStates(id);
      // the novel override is cleared -> resolver falls back to the layer below
      // (CURRENT_STATUS is owned by no lower layer, so the effective value is null)
      expect(states[CharacterScopeLayer.novelSpecific]!.currentStatus, isNull);
      // sibling preserved
      expect(states[CharacterScopeLayer.novelSpecific]!.role, 'antagonis');
      // canonical rows untouched by the novel-scoped clear
      expect(
        states[CharacterScopeLayer.canonical]!.identity,
        'identitas-kanon',
      );
      expect(states[CharacterScopeLayer.canonical]!.baseVoice, 'tenang');

      final effective = CharacterScopeEffectiveResolver(
        canonical: states[CharacterScopeLayer.canonical]!,
        universeTimeline: states[CharacterScopeLayer.universeTimeline]!,
        novelSpecific: states[CharacterScopeLayer.novelSpecific]!,
      );
      expect(effective.currentStatus, isNull);
      expect(effective.identity, 'identitas-kanon');
    },
  );
}
