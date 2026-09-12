import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/ai_generation_runtime.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_queue_screen.dart'
    show aiGenerationRuntimeProvider;
import 'package:void_scriptor/features/character/presentation/widgets/character_trait_extraction_sheet.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Canned text provider (id matches the sheet's default dropdown) that
/// returns a fixed strict-JSON reply and records the last prompt sent.
class _CannedProvider with AiStreamingFallback implements AiProvider {
  _CannedProvider(this.id, this.reply);
  @override
  final String id;
  final String reply;
  String? lastPrompt;

  @override
  String get displayName => 'Canned $id';
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
  bool validateTarget(PromptTarget target) => true;
}

class _BoundSession extends ProjectSessionController {
  _BoundSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

const _replyJson = '''
{"traits":[
 {"field":"eyes","value":"Violet","tag":"explicit",
  "citations":[{"chapter":1,"quote":"mata violetnya menyala"}]},
 {"field":"hair","value":"putih bersemu lavender","tag":"inferred",
  "citations":[{"chapter":2,"quote":"rambut putih bergelombang"}]}
],"unknown":["voice"]}
''';

void main() {
  testWidgets(
    'consent gate: no text leaves the app until Analisis, only ticked '
    'proposals are applied, citations are shown per proposal',
    (tester) async {
      late ProjectSession session;
      late AiGenerationRuntime runtime;
      late _CannedProvider provider;
      final root = await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp('trait-sheet-');
        final package = await ProjectPackageService(
          rootDirectory: dir,
        ).create(name: 'Trait Sheet');
        session = await ProjectSessionManager().open(package);
        addTearDown(session.database.close);
        final now = DateTime(2026);
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: 'char-1',
                projectId: session.manifest.id,
                name: 'Sera',
                type: 'character',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await session.database
            .into(session.database.characters)
            .insert(
              CharactersCompanion.insert(
                assetId: 'char-1',
                projectId: session.manifest.id,
                displayName: 'Sera',
              ),
            );
        await session.database
            .into(session.database.stories)
            .insert(
              StoriesCompanion.insert(
                assetId: 'novel-1',
                projectId: session.manifest.id,
                title: 'Void Cube Saga',
              ),
            );
        await session.database
            .into(session.database.storyChapters)
            .insert(
              StoryChaptersCompanion.insert(
                id: 'ch-1',
                storyId: 'novel-1',
                title: 'Bab Satu',
                chapterNumber: 1,
              ),
            );
        await session.database
            .into(session.database.storyScenes)
            .insert(
              StoryScenesCompanion.insert(
                id: 'sc-1',
                storyId: 'novel-1',
                chapterId: 'ch-1',
                title: 'Adegan Satu',
                sceneNumber: 1,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await session.database
            .into(session.database.sceneBeats)
            .insert(
              SceneBeatsCompanion.insert(
                id: 'beat-1',
                sceneId: 'sc-1',
                beatType: const Value('draft'),
                content: 'Sera menatap; mata violetnya menyala di gelap.',
              ),
            );
        provider = _CannedProvider('openai', _replyJson);
        runtime = await AiGenerationRuntime.open(
          database: session.database,
          package: session.package,
          registry: AiProviderRegistry([provider]),
        );
        addTearDown(runtime.dispose);
        addTearDown(() async {
          try {
            await dir.delete(recursive: true);
          } catch (_) {}
        });
        return dir;
      });
      expect(root != null && root.existsSync(), isTrue);

      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: session.package.root.parent),
            ),
            aiGenerationRuntimeProvider.overrideWith((ref) async => runtime),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CharacterTraitExtractionSheet.show(
                      context,
                      characterId: 'char-1',
                      characterName: 'Sera',
                    ),
                    child: const Text('open-sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 60; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump(const Duration(milliseconds: 80));
        }
      }

      await tester.tap(find.text('open-sheet'));
      await settle();
      expect(find.text('Ekstraksi ciri dari naskah — Sera'), findsOneWidget);
      // Gate konsen: belum ada satu byte pun terkirim sebelum tap.
      expect(provider.lastPrompt, isNull);

      await tester.tap(find.byKey(const ValueKey('trait-analyze')));
      await settle();
      // Payload benar-benar berisi potongan naskah + nama karakter.
      expect(provider.lastPrompt, contains('Sera'));
      expect(provider.lastPrompt, contains('mata violetnya menyala'));
      expect(find.textContaining('Proposal (2)'), findsOneWidget);
      expect(
        find.textContaining('Bab 1: "mata violetnya menyala"'),
        findsOneWidget,
      );
      expect(find.text('unknown: voice'), findsOneWidget);

      // Belum ada yang tercentang: Terapkan mati.
      final applyButton = find.byKey(const ValueKey('trait-apply'));
      final applyFilled = tester.widget<FilledButton>(
        find.descendant(of: applyButton, matching: find.byType(FilledButton)),
      );
      expect(applyFilled.onPressed, isNull);

      // Centang eyes saja, terapkan.
      await tester.tap(find.byKey(const ValueKey('trait-proposal-0')));
      await tester.pump();
      await tester.tap(applyButton);
      await settle();

      final model = await tester.runAsync(
        () => session.database.characterDao.getCharacter('char-1'),
      );
      expect(model!.eyes, 'Violet');
      expect(model.hair, isEmpty); // tidak dicentang => tidak ditulis
      expect(find.text('Ekstraksi ciri dari naskah — Sera'), findsNothing);
    },
  );

  testWidgets(
    'character absent from the manuscript: honest failure, zero API call',
    (tester) async {
      late ProjectSession session;
      late AiGenerationRuntime runtime;
      late _CannedProvider provider;
      await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp('trait-absent-');
        addTearDown(() async {
          try {
            await dir.delete(recursive: true);
          } catch (_) {}
        });
        final package = await ProjectPackageService(
          rootDirectory: dir,
        ).create(name: 'Trait Absent');
        session = await ProjectSessionManager().open(package);
        addTearDown(session.database.close);
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: 'char-2',
                projectId: session.manifest.id,
                name: 'Narenya',
                type: 'character',
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            );
        await session.database
            .into(session.database.characters)
            .insert(
              CharactersCompanion.insert(
                assetId: 'char-2',
                projectId: session.manifest.id,
                displayName: 'Narenya',
              ),
            );
        await session.database
            .into(session.database.stories)
            .insert(
              StoriesCompanion.insert(
                assetId: 'novel-x',
                projectId: session.manifest.id,
                title: 'Novel Lain',
              ),
            );
        provider = _CannedProvider('openai', _replyJson);
        runtime = await AiGenerationRuntime.open(
          database: session.database,
          package: session.package,
          registry: AiProviderRegistry([provider]),
        );
        addTearDown(runtime.dispose);
      });

      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _BoundSession(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: session.package.root.parent),
            ),
            aiGenerationRuntimeProvider.overrideWith((ref) async => runtime),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CharacterTraitExtractionSheet.show(
                      context,
                      characterId: 'char-2',
                      characterName: 'Narenya',
                    ),
                    child: const Text('open-sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> settle() async {
        for (var i = 0; i < 60; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump(const Duration(milliseconds: 80));
        }
      }

      await tester.tap(find.text('open-sheet'));
      await settle();
      await tester.tap(find.byKey(const ValueKey('trait-analyze')));
      await settle();
      // Jujur: gagal tanpa mengirim apa pun, bukan hasil karangan kosong.
      expect(provider.lastPrompt, isNull);
      expect(find.text('Ekstraksi gagal'), findsOneWidget);
      expect(find.textContaining('tidak muncul di naskah'), findsOneWidget);
    },
  );
}
