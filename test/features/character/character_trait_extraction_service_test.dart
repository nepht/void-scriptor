import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/ai_generation_runtime.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/character/application/character_trait_extraction_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

class _TextProvider with AiStreamingFallback implements AiProvider {
  _TextProvider(this.reply);
  final String reply;
  String? lastPrompt;

  @override
  String get id => 'mock';
  @override
  String get displayName => 'Canned';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    lastPrompt = request.prompt;
    return AiGenerationResult(
      providerRequestId: 'canned-1',
      outputs: [AiGeneratedOutput(type: AiOutputType.text, text: reply)],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(target) => true;
}

void main() {
  late Directory temp;
  setUp(() => temp = Directory.systemTemp.createTempSync('trait-service'));
  tearDown(() => temp.deleteSync(recursive: true));

  Future<ProjectSession> openSession(String name) async {
    final root = Directory(p.join(temp.path, name))..createSync();
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    final session = await ProjectSessionManager().open(package);
    addTearDown(session.database.close);
    return session;
  }

  group('generateText', () {
    test('returns provider text and records prompt history', () async {
      final session = await openSession('gen-text');
      final runtime = await AiGenerationRuntime.open(
        database: session.database,
        package: session.package,
        registry: AiProviderRegistry([_TextProvider('hasil: violet')]),
      );
      addTearDown(runtime.dispose);
      final text = await runtime.generateText(
        prompt: 'Ekstraksi ciri Sera',
        providerId: 'mock',
      );
      expect(text, 'hasil: violet');
      final history = await (session.database.select(
        session.database.aiPromptHistory,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      expect(history.first.prompt, 'Ekstraksi ciri Sera');
      expect(history.first.provider, 'mock');
    });

    test('empty prompt rejected before any provider call', () async {
      final session = await openSession('gen-empty');
      final provider = _TextProvider('tidak boleh dipakai');
      final runtime = await AiGenerationRuntime.open(
        database: session.database,
        package: session.package,
        registry: AiProviderRegistry([provider]),
      );
      addTearDown(runtime.dispose);
      await expectLater(
        runtime.generateText(prompt: '   ', providerId: 'mock'),
        throwsA(isA<ArgumentError>()),
      );
      expect(provider.lastPrompt, isNull);
    });

    test('unknown provider id fails honestly', () async {
      final session = await openSession('gen-unknown');
      final runtime = await AiGenerationRuntime.open(
        database: session.database,
        package: session.package,
        registry: AiProviderRegistry([_TextProvider('x')]),
      );
      addTearDown(runtime.dispose);
      await expectLater(
        runtime.generateText(prompt: 'x', providerId: 'nope'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('buildManuscript', () {
    Future<void> seedStory(
      ProjectDatabase database, {
      required String projectId,
      required String storyId,
    }) async {
      await database
          .into(database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: storyId,
              projectId: projectId,
              title: 'Void Cube Saga',
            ),
          );
      for (final (index, title) in const ['Bab Satu', 'Bab Dua'].indexed) {
        await database
            .into(database.storyChapters)
            .insert(
              StoryChaptersCompanion.insert(
                id: '$storyId-ch-$index',
                storyId: storyId,
                title: title,
                chapterNumber: index + 1,
                sortOrder: Value(index),
              ),
            );
        await database
            .into(database.storyScenes)
            .insert(
              StoryScenesCompanion.insert(
                id: '$storyId-sc-$index',
                storyId: storyId,
                chapterId: '$storyId-ch-$index',
                title: 'Adegan',
                sceneNumber: 1,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            );
        await database
            .into(database.sceneBeats)
            .insert(
              SceneBeatsCompanion.insert(
                id: '$storyId-beat-$index',
                sceneId: '$storyId-sc-$index',
                beatType: const Value('draft'),
                content: index == 0
                    ? 'Sera melangkah masuk.'
                    : 'Tidak ada tokoh lain di bab ini.',
              ),
            );
      }
    }

    test('keeps only chapters that mention the character, numbered', () async {
      final session = await openSession('ms-filter');
      await seedStory(
        session.database,
        projectId: session.manifest.id,
        storyId: 'nov-1',
      );
      final excerpt = await CharacterTraitExtractionService.buildManuscript(
        session.database,
        projectId: session.manifest.id,
        storyId: 'nov-1',
        characterName: 'Sera',
      );
      expect(excerpt, contains('Chapter 1: Bab Satu'));
      expect(excerpt, contains('Sera melangkah masuk.'));
      expect(excerpt, isNot(contains('Bab Dua')));
    });

    test(
      'character absent yields empty excerpt (no silent full text)',
      () async {
        final session = await openSession('ms-absent');
        await seedStory(
          session.database,
          projectId: session.manifest.id,
          storyId: 'nov-2',
        );
        final excerpt = await CharacterTraitExtractionService.buildManuscript(
          session.database,
          projectId: session.manifest.id,
          storyId: 'nov-2',
          characterName: 'Tokoh Tak Ada',
        );
        expect(excerpt, isEmpty);
      },
    );
  });
}
