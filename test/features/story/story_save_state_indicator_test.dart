// Friksi UX 145.43 #3 (native journey 117f157): status scene
// 'Belum tersimpan' tampil tanpa aksi edit - save-state indicator
// perlu diperjelas. Label dua-state menyembunyikan window save
// in-flight: suntingan yang sedang dipersist harus terlihat
// 'Menyimpan...' dan berpindah ke 'Tersimpan HH:MM' saat selesai.
import 'dart:async';
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
  testWidgets(
    'save state shows Menyimpan while autosave is in flight and Tersimpan '
    'after it completes',
    (tester) async {
      final journal = _FakeDurableDraftJournal();
      final repository = _GatedFakeStoryRepository();
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

      // Baseline: draf dimuat, belum ada autosave layar.
      expect(find.text('Belum tersimpan'), findsOneWidget);

      // Sunting: debounce 1500 ms berlalu, persist di-gate manual agar
      // window save in-flight dapat diamati.
      repository.gateNextPersist();
      await tester.enterText(
        find.widgetWithText(TextField, 'teks awal'),
        'draf save-state',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));

      // Save in-flight harus terlihat, bukan salah lapor 'Belum tersimpan'.
      expect(find.text('Menyimpan...'), findsOneWidget);
      expect(find.text('Belum tersimpan'), findsNothing);

      // Persist selesai: label berpindah ke 'Tersimpan HH:MM'.
      repository.releasePersist();
      await tester.pumpAndSettle();
      expect(find.textContaining('Tersimpan'), findsOneWidget);
      expect(find.text('Menyimpan...'), findsNothing);
      expect(find.text('Belum tersimpan'), findsNothing);
      expect(repository.draftByScene['scene-a'], 'draf save-state');
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeDurableDraftJournal extends DurableDraftJournal {
  _FakeDurableDraftJournal() : super(dir: Directory.systemTemp);

  final Map<String, PendingDraftEntry> entries = {};

  @override
  Future<void> stage({required String sceneId, required String content}) async {
    entries[sceneId] = PendingDraftEntry(
      sceneId: sceneId,
      content: content,
      stagedAt: DateTime(2026, 9, 6, 5),
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

class _GatedFakeStoryRepository extends StoryRepositoryImpl {
  _GatedFakeStoryRepository()
    : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'T'),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  Map<String, String> draftByScene = {};

  Completer<void>? _persistGate;

  /// Menahan persist autosave berikutnya sampai [releasePersist].
  void gateNextPersist() {
    _persistGate = Completer<void>();
  }

  void releasePersist() {
    _persistGate?.complete();
    _persistGate = null;
  }

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => draftByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    final gate = _persistGate;
    if (gate != null) {
      await gate.future;
    }
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
