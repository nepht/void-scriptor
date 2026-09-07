// Prioritas Core 2026-09-04 (kontrak Step 145.30 visible failure):
// kegagalan persist autosave pada Story Workspace Screen harus TERLIHAT:
// banner error ditampilkan (bukan silent, bukan uncaught async error),
// dan menghilang setelah simpan berikutnya berhasil.
import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  testWidgets('failed autosave shows a visible banner; later success clears '
      'it', (tester) async {
    final journal = _FakeDurableDraftJournal();
    final repository = _FakeStoryRepository();
    repository
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
                sceneId: 'scene-a',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sunting draf: persist di-fake gagal.
    repository.failNextSave = true;
    await tester.enterText(
      find.widgetWithText(TextField, 'teks awal'),
      'draf gagal simpan',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));

    // Banner error terlihat, tanpa uncaught exception.
    expect(find.byKey(const ValueKey('autosave_error_banner')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Simpan berikutnya berhasil (tombol retry banner) -> banner hilang.
    repository.failNextSave = false;
    await tester.ensureVisible(find.text('Simpan ulang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan ulang'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('autosave_error_banner')), findsNothing);
  });
}

class _FakeDurableDraftJournal extends DurableDraftJournal {
  _FakeDurableDraftJournal() : super(dir: Directory.systemTemp);

  final Map<String, PendingDraftEntry> entries = {};

  @override
  Future<void> stage({required String sceneId, required String content}) async {
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
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'T'),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  Map<String, String> draftByScene = {};

  /// Ketika true, saveSceneDraft berikutnya gagal (simulasi disk penuh).
  bool failNextSave = false;

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => draftByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    if (failNextSave) throw StateError('disk penuh');
    draftByScene[sceneId] = content;
  }
}

StoryHierarchy _hierarchy() {
  return const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'T'),
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
