import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

/// Step 145.25 Character Workspace Core - BASE_VOICE + private notes.
///
/// core_mvp_scope_reset_spec canonical_owns = IDENTITY, BASE_VOICE,
/// BASE_VISUAL_PROFILE, BASE_RELATION_REFERENCES. Live inspection found
/// two concrete gaps: (1) Characters table/model has NO voice field, and
/// (2) CharacterRepositoryImpl.getIdentity/updateIdentity silently drop
/// the existing CharacterIdentityProfiles.notes column at both boundaries.
void main() {
  Future<ProjectDatabase> openDb(String dir) async {
    final service = ProjectDatabaseService();
    final dbPath = '$dir/project.db';
    await service.create(dbPath);
    return service.open(dbPath);
  }

  Future<void> seedCharacter(
    ProjectDatabase db, {
    String id = 'char-1',
    String voice = '',
  }) async {
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
              voice: Value(voice),
            ),
          );
    });
  }

  test('getIdentity preserves the private notes column', () async {
    final dir = await Directory.systemTemp.createTemp('voice-notes-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    await db
        .into(db.characterIdentityProfiles)
        .insert(
          CharacterIdentityProfilesCompanion.insert(
            characterId: 'char-1',
            notes: const Value('Jangan ubah warna mata'),
          ),
        );

    final repository = CharacterRepositoryImpl(
      database: db,
      projectId: 'project-1',
      paths: ProjectPaths(rootDirectory: dir),
    );
    final identity = await repository.getIdentity('char-1');
    expect(identity, isNotNull);
    expect(identity!.notes, 'Jangan ubah warna mata');
  });

  test('updateIdentity persists the private notes column', () async {
    final dir = await Directory.systemTemp.createTemp('voice-notes-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db);

    final repository = CharacterRepositoryImpl(
      database: db,
      projectId: 'project-1',
      paths: ProjectPaths(rootDirectory: dir),
    );
    await repository.updateIdentity(
      const CharacterIdentityProfile(
        characterId: 'char-1',
        notes: 'Catatan pribadi: rahasia kelahiran',
      ),
    );

    final identity = await repository.getIdentity('char-1');
    expect(identity, isNotNull);
    expect(identity!.notes, 'Catatan pribadi: rahasia kelahiran');
  });

  test(
    'CharacterModel carries BASE_VOICE through update and readback',
    () async {
      final dir = await Directory.systemTemp.createTemp('voice-notes-');
      addTearDown(() => dir.delete(recursive: true));
      final db = await openDb(dir.path);
      addTearDown(db.close);
      await seedCharacter(db);

      final repository = CharacterRepositoryImpl(
        database: db,
        projectId: 'project-1',
        paths: ProjectPaths(rootDirectory: dir),
      );
      final created = (await repository.getCharacter('char-1'))!;
      expect(created.voice, isEmpty);

      await repository.updateCharacter(
        created.copyWith(voice: 'Serak, dalam, tenang'),
      );
      final updated = (await repository.getCharacter('char-1'))!;
      expect(updated.voice, 'Serak, dalam, tenang');
    },
  );

  test('voice survives database restart', () async {
    final dir = await Directory.systemTemp.createTemp('voice-notes-');
    addTearDown(() => dir.delete(recursive: true));
    var db = await openDb(dir.path);
    await seedCharacter(db, voice: 'Melengking saat marah');
    await db.close();

    db = await openDb(dir.path);
    addTearDown(db.close);
    final repository = CharacterRepositoryImpl(
      database: db,
      projectId: 'project-1',
      paths: ProjectPaths(rootDirectory: dir),
    );
    final restored = (await repository.getCharacter('char-1'))!;
    expect(restored.voice, 'Melengking saat marah');
  });

  test('quick reference includes the canonical voice row', () async {
    final dir = await Directory.systemTemp.createTemp('voice-notes-');
    addTearDown(() => dir.delete(recursive: true));
    final db = await openDb(dir.path);
    addTearDown(db.close);
    await seedCharacter(db, voice: 'Berbisik, penuh jeda');

    final paths = ProjectPaths(rootDirectory: dir);
    final storyService = CreateStoryService(database: db, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Voice Story',
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      title: 'Bab Satu',
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Scene Pembuka',
      sceneNumber: 1,
    );
    await storyService.addCharacter(sceneId: sceneId, characterId: 'char-1');

    final repository = StoryRepositoryImpl(
      database: db,
      projectId: 'project-1',
    );
    final quickRefs = await repository.quickReferenceForScene(sceneId);
    expect(quickRefs, hasLength(1));
    expect(
      quickRefs.single.compactDescription,
      contains('Voice: Berbisik, penuh jeda'),
    );
  });
}
