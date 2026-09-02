// Step 145.30 Autosave Snapshot and Crash Recovery — wiring screen
// produksi ke DurableAutosaveCoordinator (RED).
//
// Acceptance kanonik: no silent loss + visible status. Slice ini membuktikan
// screen TIDAK lagi membuang draf saat dispose: DurableAutosaveCoordinator
// mem-flush draf yang masih menunggu debounce (perbaikan terhadap
// DebouncedAutosave.dispose yang hanya membatalkan timer).
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
  testWidgets('flush-on-dispose persists draft pending on the debounce timer', (
    tester,
  ) async {
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

    // Editor memuat draft scene-a.
    expect(find.widgetWithText(TextField, 'teks awal'), findsOneWidget);

    // Sunting draf — debounce timer 1500ms BELUM lewat.
    await tester.enterText(
      find.widgetWithText(TextField, 'teks awal'),
      'draf baru sebelum debounce',
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Journal sudah di-stage inline (no-silent-loss).
    expect(await journal.pendingEntries(), isNotEmpty);

    // Layar di-dispose sebelum timer sempat fire (mis. tutup scene / keluar).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    // RED (wiring lama): DebouncedAutosave membuang timer -> draf HILANG.
    // GREEN (wiring baru): coordinator mem-flush -> draf TERSIMPAN.
    expect(
      repository.draftByScene['scene-a'],
      'draf baru sebelum debounce',
      reason:
          'flush-on-dispose harus mem-persist draf yang masih menunggu '
          'debounce (no silent loss)',
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeDurableDraftJournal extends DurableDraftJournal {
  /// Directory nyata yang TIDAK disentuh: stage/acknowledge di-override
  /// agar deterministik di fake-async zone.
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
  Future<void> acknowledge(String sceneId) async {
    entries.remove(sceneId);
  }
}

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Coordinator Story',
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
}

StoryHierarchy _hierarchy() {
  return const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Coordinator Story',
    ),
    arcs: [],
    chapters: [
      StoryChapterNode('chapter-1', 'Chapter One', [
        StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
        StorySceneNode('scene-b', 'Gema Kedalaman', [], null, []),
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
