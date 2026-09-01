import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

/// Widget journey test untuk Step 145.24 Novel Workspace Core — lapisan UI:
/// 1. Search UI journey: ketik query di kolom pencarian, tekan "Cari Novel",
///    hasil lintas scene dari repository.searchNovel dirender sebagai daftar.
/// 2. Snapshot UI journey: pilih scene, rekam snapshot manual berlabel,
///    daftar snapshot muncul, lalu Restore memulihkan isi snapshot ke editor.
///
/// Menggunakan _FakeStoryRepository (deterministik, tanpa SQLite) agar widget
/// test tetap berjalan di fake-async zone. Persistensi lintas close/reopen
/// sudah dibuktikan di draft_snapshot_persistence_test.dart (domain+DB), dan
/// searchNovel di novel_search_test.dart.
void main() {
  testWidgets('search UI renders cross-scene results from repository', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchyWith(
        chapterTitle: 'Chapter One',
        sceneATitle: 'Kedatangan Void',
        sceneBTitle: 'Gema Kedalaman',
      )
      ..searchResults = const [
        NovelSearchResult(
          sceneId: 'scene-a',
          sceneTitle: 'Kedatangan Void',
          chapterTitle: 'Chapter One',
          matchCount: 1,
        ),
        NovelSearchResult(
          sceneId: 'scene-b',
          sceneTitle: 'Gema Kedalaman',
          chapterTitle: 'Chapter One',
          matchCount: 1,
        ),
      ];

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

    // Search journey: buka dialog pencarian, ketik query, jalankan.
    await tester.ensureVisible(find.text('Cari Novel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari Novel'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'kristal',
    );
    await tester.pump();
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    expect(repository.lastSearchQuery, 'kristal');
    expect(find.textContaining('Kedatangan Void'), findsWidgets);
    expect(find.textContaining('Gema Kedalaman'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snapshot UI captures, lists, and restores a scene snapshot', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchyWith(
        chapterTitle: 'Chapter One',
        sceneATitle: 'Kedatangan Void',
        sceneBTitle: 'Gema Kedalaman',
      )
      ..draftByScene = {'scene-a': 'teks awal scene A'};

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

    // Pilih scene A di CHAPTERS sehingga editor memuat draft-nya.
    await tester.ensureVisible(find.text('Kedatangan Void'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kedatangan Void'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'teks awal scene A'), findsOneWidget);

    // Snapshot UI journey: buka dialog snapshot, isi label, rekam.
    await tester.ensureVisible(find.text('Snapshot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snapshot'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'checkpoint',
    );
    await tester.pump();
    await tester.tap(find.text('Rekam'));
    await tester.pumpAndSettle();

    expect(repository.capturedLabels, ['checkpoint']);
    expect(find.text('checkpoint'), findsOneWidget);

    // Ubah draft editor, lalu pulihkan lewat tombol Restore.
    await tester.enterText(
      find.widgetWithText(TextField, 'teks awal scene A'),
      'teks sudah berubah jauh',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(repository.restoredSnapshotId, repository.capturedIds.single);
    expect(find.widgetWithText(TextField, 'teks awal scene A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Fake repository deterministik untuk lapisan UI. Semua method yang dipakai
/// StoryWorkspaceScreen di-override; method lain memakai implementasi induk
/// yang tidak pernah dipanggil di jalur UI ini.
class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Search Story',
    ),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  List<NovelSearchResult> searchResults = const <NovelSearchResult>[];
  Map<String, String> draftByScene = {};
  String? lastSearchQuery;
  final List<String> capturedLabels = [];
  final List<String> capturedIds = [];
  String? restoredSnapshotId;

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<List<NovelSearchResult>> searchNovel(String query) async {
    lastSearchQuery = query;
    return searchResults;
  }

  @override
  Future<String?> getSceneDraft(String sceneId) async => draftByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    draftByScene[sceneId] = content;
  }

  @override
  Future<String> captureSceneDraftSnapshot(
    String sceneId, {
    required String label,
    DraftSnapshotKind kind = DraftSnapshotKind.manual,
  }) async {
    capturedLabels.add(label);
    final id = 'snap-${capturedLabels.length}';
    capturedIds.add(id);
    return id;
  }

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async {
    var rows = <SceneDraftSnapshot>[
      for (var i = 0; i < capturedIds.length; i++)
        SceneDraftSnapshot(
          id: capturedIds[i],
          sceneId: sceneId,
          projectId: projectId,
          kind: 'manual',
          content: 'teks awal scene A',
          label: capturedLabels[i],
          createdAt: DateTime.utc(2026, 9, 1, 8, i),
        ),
    ];
    if (snapshotId != null) {
      rows = rows.where((s) => s.id == snapshotId).toList();
    }
    if (kind != null) {
      rows = rows.where((s) => s.kind == kind.name).toList();
    }
    return rows;
  }

  @override
  Future<String> restoreSceneDraftSnapshot(
    String sceneId, {
    required String snapshotId,
  }) async {
    restoredSnapshotId = snapshotId;
    draftByScene[sceneId] = 'teks awal scene A';
    return 'teks awal scene A';
  }
}

StoryHierarchy _hierarchyWith({
  required String chapterTitle,
  required String sceneATitle,
  required String sceneBTitle,
}) {
  return StoryHierarchy(
    story: const StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Search Story',
    ),
    arcs: const [],
    chapters: [
      StoryChapterNode('chapter-1', chapterTitle, [
        StorySceneNode('scene-a', sceneATitle, const [], null, const []),
        StorySceneNode('scene-b', sceneBTitle, const [], null, const []),
      ]),
    ],
    scenes: const [],
  );
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
