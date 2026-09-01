import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_repository.dart';
import 'package:void_scriptor/features/character/domain/character_scope_layers.dart';

/// Step 145.26 Character Scope Layers persistence slice.
/// core_mvp_scope_reset_spec.json character_model contract:
///   layers: CANONICAL_CHARACTER, UNIVERSE_OR_TIMELINE_OVERRIDE,
///   NOVEL_SPECIFIC_STATE; override_never_silently_mutates_canonical: true.
void main() {
  Future<ProjectDatabase> openDb(String dir) async {
    final service = ProjectDatabaseService();
    final dbPath = '$dir/project.db';
    await service.create(dbPath);
    return service.open(dbPath);
  }

  Future<void> seedCharacter(ProjectDatabase db, {String id = 'char-1'}) async {
    final now = DateTime.now();
    await db.transaction(() async {
      await db
          .into(db.assets)
          .insert(
            AssetsCompanion.insert(
              id: id,
              projectId: 'project-1',
              name: 'Qowner',
              type: 'character',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              assetId: id,
              projectId: 'project-1',
              displayName: 'Qowner',
            ),
          );
    });
  }

  CharacterRepository repo(ProjectDatabase db, Directory dir) =>
      CharacterRepositoryImpl(
        database: db,
        projectId: 'project-1',
        paths: ProjectPaths(rootDirectory: dir),
      );

  test('scope states default to empty for a character with no rows', () async {
    final dir = await Directory.systemTemp.createTemp('scope-red-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    final states = await repo(db, dir).getScopeStates('char-1');
    expect(states, contains(CharacterScopeLayer.canonical));
    expect(states, contains(CharacterScopeLayer.universeTimeline));
    expect(states, contains(CharacterScopeLayer.novelSpecific));
    expect(states[CharacterScopeLayer.canonical]!.identity, isNull);
    expect(states[CharacterScopeLayer.novelSpecific]!.currentStatus, isNull);
  });

  test('canonical scope round-trips through persistence', () async {
    final dir = await Directory.systemTemp.createTemp('scope-red-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    final r = repo(db, dir);
    await r.updateScopeState(
      'char-1',
      CharacterScopeLayer.canonical,
      const CharacterScopeState(
        identity: 'Pemelihara Kekosongan',
        baseVoice: 'tenang',
      ),
    );

    final states = await r.getScopeStates('char-1');
    expect(
      states[CharacterScopeLayer.canonical]!.identity,
      'Pemelihara Kekosongan',
    );
    expect(states[CharacterScopeLayer.canonical]!.baseVoice, 'tenang');
  });

  test('universe override round-trips without touching canonical', () async {
    final dir = await Directory.systemTemp.createTemp('scope-red-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    final r = repo(db, dir);
    await r.updateScopeState(
      'char-1',
      CharacterScopeLayer.canonical,
      const CharacterScopeState(identity: 'identitas-kanon'),
    );
    await r.updateScopeState(
      'char-1',
      CharacterScopeLayer.universeTimeline,
      const CharacterScopeState(alternateHistory: 'garis-waktu-b'),
    );

    final states = await r.getScopeStates('char-1');
    expect(
      states[CharacterScopeLayer.universeTimeline]!.alternateHistory,
      'garis-waktu-b',
    );
    expect(states[CharacterScopeLayer.canonical]!.identity, 'identitas-kanon');
    expect(states[CharacterScopeLayer.canonical]!.alternateHistory, isNull);
  });

  test('novel-specific state round-trips', () async {
    final dir = await Directory.systemTemp.createTemp('scope-red-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    final r = repo(db, dir);
    await r.updateScopeState(
      'char-1',
      CharacterScopeLayer.novelSpecific,
      const CharacterScopeState(
        role: 'protagonis',
        arc: 'penerimaan',
        currentLocation: 'Kutub Utara',
        currentStatus: 'aktif',
        scenePov: 'Qowner',
      ),
    );

    final states = await r.getScopeStates('char-1');
    final novel = states[CharacterScopeLayer.novelSpecific]!;
    expect(novel.role, 'protagonis');
    expect(novel.arc, 'penerimaan');
    expect(novel.currentLocation, 'Kutub Utara');
    expect(novel.currentStatus, 'aktif');
    expect(novel.scenePov, 'Qowner');
    expect(states[CharacterScopeLayer.canonical]!.identity, isNull);
  });

  test('scoped states survive a close and reopen', () async {
    final dir = await Directory.systemTemp.createTemp('scope-red-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    await seedCharacter(db);
    await repo(db, dir).updateScopeState(
      'char-1',
      CharacterScopeLayer.novelSpecific,
      const CharacterScopeState(role: 'antagonis', arc: 'kehancuran'),
    );
    await db.close();

    final reopened = await openDb(dir.path);
    addTearDown(reopened.close);
    final states = await repo(reopened, dir).getScopeStates('char-1');
    expect(states[CharacterScopeLayer.novelSpecific]!.role, 'antagonis');
    expect(states[CharacterScopeLayer.novelSpecific]!.arc, 'kehancuran');
  });
}
