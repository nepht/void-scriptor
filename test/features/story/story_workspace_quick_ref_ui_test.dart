import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart'
    show DraftSnapshotKind;
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

/// Step 145.25 Character Workspace Core - propagasi quick reference ke
/// lapisan UI Story Workspace: memilih scene memuat kartu quick reference
/// kanonik karakter (nama, deskripsi ringkas, role) dari repository
/// .quickReferenceForScene tanpa dialog dan tanpa input manual.
void main() {
  testWidgets('selecting a scene loads character quick reference cards', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchy()
      ..quickRefsByScene = {
        'scene-a': const <CharacterQuickRef>[
          CharacterQuickRef(
            characterId: 'char-1',
            name: 'Qowner',
            alias: 'Void Bearer',
            compactDescription:
                'Penjaga kutub penciptaan\nHair: silver\nEyes: grey',
            role: 'participant',
          ),
        ],
      };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'story-1',
                repository: repository,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Run62: hierarchy termuat langsung memilih scene pertama, sehingga
    // kartu quick reference scene-a otomatis dimuat (jalur yang sama dengan
    // tap eksplisit pada scene).
    await tester.ensureVisible(find.text('CHARACTER QUICK REF'));
    await tester.pumpAndSettle();

    expect(repository.quickRefSceneIds, ['scene-a']);
    expect(find.text('Qowner'), findsWidgets);
    expect(find.textContaining('Penjaga kutub penciptaan'), findsOneWidget);
    expect(find.textContaining('Hair: silver'), findsOneWidget);
    expect(find.text('participant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty hierarchy keeps the explicit quick-ref hint', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()..hierarchy = _emptyHierarchy();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'story-1',
                repository: repository,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CHARACTER QUICK REF'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pilih scene untuk melihat quick reference karakter.'),
      findsOneWidget,
    );
    expect(repository.quickRefSceneIds, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

StoryHierarchy _emptyHierarchy() => const StoryHierarchy(
  story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'Quick Ref'),
  arcs: [],
  chapters: [],
  scenes: [],
);

StoryHierarchy _hierarchy() => const StoryHierarchy(
  story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'Quick Ref'),
  arcs: [],
  chapters: [
    StoryChapterNode('chapter-1', 'Chapter One', [
      StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
    ]),
  ],
  scenes: [],
);

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'Quick Ref'),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  Map<String, List<CharacterQuickRef>> quickRefsByScene = {};
  final List<String> quickRefSceneIds = [];

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => null;

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {}

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async => const [];

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(String sceneId) async {
    quickRefSceneIds.add(sceneId);
    return quickRefsByScene[sceneId] ?? const [];
  }
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
