// Step 145.28 Writing Room Focus — lapisan UI (RED).
//
// Acceptance kanonik sprint_145.json 145.28: editor memprioritaskan
// writing canvas, chapter navigation, save state, word count, focus mode,
// search/lore reference, dan minimal distraction.
//
// Domain FocusWritingSession (Step 109.20) sudah teruji di
// test/features/story/focus_writing_mode_test.dart. Slice ini membuktikan:
// 1. Label autosave bukan lagi 'Autosave aktif' — setelah autosave
//    terschedule dan flush, label berubah menjadi "Tersimpan HH:MM".
// 2. Tombol "Mode Fokus" dapat mengaktifkan sesi fokus; panel chrome
//    (CHAPTERS, STORY BIBLE, NOVEL SEARCH, SCENE SNAPSHOTS,
//    CHARACTER QUICK REF) tidak lagi dirender saat sesi aktif;
//    tombol "Keluar Fokus" mengembalikannya.
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  testWidgets('autosave label reflects live save state, not static text', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchy()
      ..draftByScene = {'scene-a': 'teks awal'};

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

    // Pilih scene sehingga editor memuat draft scene.
    await tester.ensureVisible(find.text('Kedatangan Void'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kedatangan Void'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'teks awal'), findsOneWidget);

    // Baseline: label autosave dinamis. Draft dimuat dari repository tapi
    // jalur autosave layar belum pernah menyimpan -> label jujur
    // 'Belum tersimpan' (bukan teks statis 'Autosave aktif').
    expect(find.text('Autosave aktif'), findsNothing);
    expect(find.text('Belum tersimpan'), findsOneWidget);

    // Sunting draft.
    await tester.enterText(
      find.widgetWithText(TextField, 'teks awal'),
      'teks baru yang lebih panjang',
    );
    await tester.pump(const Duration(seconds: 2));

    // Label berubah menjadi "Tersimpan HH:MM" setelah autosave selesai.
    expect(find.text('Autosave aktif'), findsNothing);
    expect(find.textContaining('Tersimpan'), findsOneWidget);
    expect(repository.draftByScene['scene-a'], 'teks baru yang lebih panjang');
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus mode hides side chrome and exits restore it', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()..hierarchy = _hierarchy();

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

    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(find.text('STORY BIBLE'), findsOneWidget);

    // RED: tombol 'Mode Fokus' belum ada.
    await tester.ensureVisible(find.text('Mode Fokus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode Fokus'));
    await tester.pumpAndSettle();

    // Chrome samping hilang saat sesi fokus aktif.
    expect(find.text('CHAPTERS'), findsNothing);
    expect(find.text('STORY BIBLE'), findsNothing);
    expect(find.text('Keluar Fokus'), findsOneWidget);

    await tester.tap(find.text('Keluar Fokus'));
    await tester.pumpAndSettle();
    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(find.text('STORY BIBLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('escape key exits active focus session via keyboard reason', (
    tester,
  ) async {
    final repository = _FakeStoryRepository()..hierarchy = _hierarchy();

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

    // Masuk mode fokus lewat tombol terlebih dahulu.
    await tester.ensureVisible(find.text('Mode Fokus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mode Fokus'));
    await tester.pumpAndSettle();
    expect(find.text('CHAPTERS'), findsNothing);

    // Pintasan hanya memeriksa key event yang naik dari subtree di bawah
    // CallbackShortcuts layar; permintaan fokus dari root scope juga
    // berakhir di node scope layar (aturan modifikasi fokus).
    FocusManager.instance.rootScope.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Sesudah wire: chrome kembali dan sesi keluar.
    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(find.text('Keluar Fokus'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Focus Story',
    ),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  Map<String, String> draftByScene = {};

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => draftByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    draftByScene[sceneId] = content;
  }

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(
    String sceneId,
  ) async => const <CharacterQuickRef>[];

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async => const <SceneDraftSnapshot>[];
}

StoryHierarchy _hierarchy() {
  return const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Focus Story',
    ),
    arcs: [],
    chapters: [
      StoryChapterNode('chapter-1', 'Chapter One', [
        StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
      ]),
    ],
    scenes: [],
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
