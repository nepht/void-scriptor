import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

/// Widget journey test untuk Step 145.30 - lapisan UI recovery prompt:
/// 1. Saat DurableDraftJournal berisi draf pending (crash/power-loss), layar
///    menampilkan panel 'DRAFT RECOVERY' (visible status, no silent loss).
/// 2. 'Pulihkan Draft' meng-replay entri pending ke repository via
///    saveSceneDraft, meng-acknowledge journal, dan memuat ke editor.
/// 3. 'Buang' menghapus entri pending tanpa menulis ke repository.
/// 4. Journal kosong: panel tidak muncul (negatif).
///
/// Memakai _FakeStoryRepository + _FakeDurableDraftJournal deterministik (tanpa
/// SQLite / tanpa real IO) agar widget test tetap berjalan di fake-async zone.
/// Durabilitas lintas restart domain dibuktikan di durable_draft_journal_test.dart.
void main() {
  testWidgets('recovery prompt restores pending drafts into the editor', (
    tester,
  ) async {
    final journal = _FakeDurableDraftJournal()
      ..stageForTest(sceneId: 'scene-a', content: 'Draf belum autosave.');

    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchyWith(
        chapterTitle: 'Chapter One',
        sceneATitle: 'Kedatangan Void',
        sceneBTitle: 'Gema Kedalaman',
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'story-1',
                repository: repository,
                sceneId: 'scene-a',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Visible status + user-controlled restore prompt.
    expect(find.text('DRAFT RECOVERY'), findsOneWidget);
    expect(find.textContaining('1 draf belum tersimpan'), findsOneWidget);

    await tester.tap(find.text('Pulihkan Draft'));
    await tester.pumpAndSettle();

    // Journal ter-replay ke repository dan di-acknowledge (no silent loss).
    expect(repository.savedByScene['scene-a'], 'Draf belum autosave.');
    expect(await journal.pendingEntries(), isEmpty);
    expect(
      find.widgetWithText(TextField, 'Draf belum autosave.'),
      findsOneWidget,
    );
    // Panel recovery hilang setelah restore selesai.
    expect(find.text('DRAFT RECOVERY'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovery prompt discard acknowledges without writing', (
    tester,
  ) async {
    final journal = _FakeDurableDraftJournal()
      ..stageForTest(sceneId: 'scene-a', content: 'Isi yang dibuang.');

    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchyWith(
        chapterTitle: 'Chapter One',
        sceneATitle: 'Kedatangan Void',
        sceneBTitle: 'Gema Kedalaman',
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'story-1',
                repository: repository,
                sceneId: 'scene-a',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DRAFT RECOVERY'), findsOneWidget);
    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();

    // Acknowledge tanpa replay: repository tidak menerima konten.
    expect(repository.savedByScene.containsKey('scene-a'), isFalse);
    expect(await journal.pendingEntries(), isEmpty);
    expect(find.text('DRAFT RECOVERY'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no recovery panel when journal has no pending drafts', (
    tester,
  ) async {
    final journal = _FakeDurableDraftJournal();

    final repository = _FakeStoryRepository()
      ..hierarchy = _hierarchyWith(
        chapterTitle: 'Chapter One',
        sceneATitle: 'Kedatangan Void',
        sceneBTitle: 'Gema Kedalaman',
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'story-1',
                repository: repository,
                sceneId: 'scene-a',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DRAFT RECOVERY'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeDurableDraftJournal extends DurableDraftJournal {
  /// Directory nyata yang TIDAK PERNAH disentuh: semua method IO dioverride,
  /// super(dir:) hanya memenuhi kontrak constructor base class.
  _FakeDurableDraftJournal() : super(dir: Directory.systemTemp);

  final Map<String, PendingDraftEntry> entries = {};

  void stageForTest({required String sceneId, required String content}) {
    entries[sceneId] = PendingDraftEntry(
      sceneId: sceneId,
      content: content,
      stagedAt: DateTime(2026, 9, 1, 8),
    );
  }

  @override
  Future<List<PendingDraftEntry>> pendingEntries() async =>
      entries.values.toList()..sort((a, b) => a.sceneId.compareTo(b.sceneId));

  @override
  Future<void> acknowledge(String sceneId, {String? content}) async {
    entries.remove(sceneId);
  }
}

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Recovery Story',
    ),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  final Map<String, String> savedByScene = {};

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => savedByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    savedByScene[sceneId] = content;
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
      title: 'Recovery Story',
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
