import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/features/ai/application/ai_context_resolver.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Step 145.25 Character Workspace Core - quick reference propagation.
///
/// Journey: character canonical profile (alias, biography, personality,
/// hair, eyes, skin, age, gender, identity notes) + scene membership
/// (via CreateStoryService.addCharacter) -> StoryRepositoryImpl
/// .quickReferenceForScene resolves a compact quick reference ->
/// AiContextResolver.resolveScene propagates it into the AI context so
/// the prompt composer can render a stable quick reference block.
void main() {
  test(
    'quick reference resolves canonical facts into scene AI context',
    () async {
      final root = await Directory.systemTemp.createTemp('qref-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      final db = await databaseService.open(dbPath);
      addTearDown(db.close);

      const characterId = 'char-1';
      final now = DateTime.now();
      await db.transaction(() async {
        await db
            .into(db.assets)
            .insert(
              AssetsCompanion.insert(
                id: characterId,
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
                assetId: characterId,
                projectId: 'project-1',
                displayName: 'Qowner',
                alias: const Value('Void Bearer'),
                biography: const Value('Penjaga kutub penciptaan'),
                personality: const Value('tenang, observatif'),
                gender: const Value('male'),
                age: const Value(28),
                heightCm: const Value(180.0),
                hair: const Value('silver'),
                eyes: const Value('grey'),
                skin: const Value('pale'),
              ),
            );
        await db
            .into(db.characterIdentityProfiles)
            .insert(
              CharacterIdentityProfilesCompanion.insert(
                characterId: characterId,
                notes: const Value('Jangan ubah warna mata'),
              ),
            );
      });

      final storyService = CreateStoryService(database: db, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Quick Ref Story',
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
      await storyService.addCharacter(
        sceneId: sceneId,
        characterId: characterId,
      );

      final repository = StoryRepositoryImpl(
        database: db,
        projectId: 'project-1',
      );
      final quickRefs = await repository.quickReferenceForScene(sceneId);
      expect(quickRefs, hasLength(1));
      final qr = quickRefs.single;
      expect(qr.characterId, characterId);
      expect(qr.name, 'Qowner');
      expect(qr.alias, 'Void Bearer');
      expect(qr.role, 'participant');
      expect(qr.compactDescription, contains('Penjaga kutub penciptaan'));
      expect(qr.compactDescription, contains('tenang, observatif'));
      expect(qr.compactDescription, contains('Hair: silver'));
      expect(qr.compactDescription, contains('Eyes: grey'));
      expect(qr.compactDescription, contains('Skin: pale'));
      expect(qr.compactDescription, contains('Jangan ubah warna mata'));
      // Kontrak baris eksak: tidak ada baris kosong/fakta null yang bocor.
      expect(qr.compactDescription.split('\n'), [
        'Penjaga kutub penciptaan',
        'tenang, observatif',
        'Gender: male',
        'Age: 28',
        'Height: 180.0 cm',
        'Hair: silver',
        'Eyes: grey',
        'Skin: pale',
        'Jangan ubah warna mata',
      ]);

      final resolver = AiContextResolver(db);
      final context = await resolver.resolveScene(
        projectId: 'project-1',
        sceneId: sceneId,
      );
      final aiChar = context.characterContexts.single;
      expect(aiChar.name, 'Qowner');
      expect(aiChar.quickRef, isNotNull);
      expect(aiChar.quickRef!.role, 'participant');
      expect(aiChar.quickRef!.summary, contains('Hair: silver'));
      expect(aiChar.quickRef!.summary, qr.compactDescription);
    },
  );
}
