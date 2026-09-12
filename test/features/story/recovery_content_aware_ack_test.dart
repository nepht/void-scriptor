// vs-hunt-20260912-autosave BUG-6 (Referee: REAL, Medium).
//
// Mekanisme eksak (story_workspace_screen.dart _restorePendingDraft):
//   await repository.saveSceneDraft(entry.sceneId, entry.content);
//   await widget.draftJournal?.acknowledge(entry.sceneId);   // BLIND
//
// Panel DRAFT RECOVERY dibangun dari snapshot pendingEntries() saat layar
// dibuka. Selama await saveSceneDraft berjalan (I/O nyata), pengguna yang
// sama dapat mengetik di scene tersebut — koordinator autosave men-stage
// konten BARA (C2) ke jurnal. Acknowledge blind kemudian menghapus entri C2
// yang BELUM PERNAH di-persist: crash sebelum debounce berikutnya = teks C2
// hilang diam-diam — persis silent loss yang dijaga guard content-aware
// (bug-hunt-run128 BUG-8) di jalur autosave reguler.
//
// Kontrak perbaikan: replay restore WAJIB acknowledge content-aware
// (content: entry.content). Bila jurnal masih memuat C1 = versi yang baru
// direstore, entri dihapus (perilaku lama utuh). Bila tergantikan C2, entri
// DIPERTAHANKAN — autosave berikutnya yang menyimpan dan meng-ack-nya.
// Jalur 'Buang' (keputusan eksplisit pengguna) tetap blind sesuai kontrak
// acknowledge().
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('restore replay keeps a journal entry replaced during the '
      'save await (BUG-6 content-aware acknowledge)', (tester) async {
    final journal = _GuardedJournal()
      ..stageForTest(sceneId: 'scene-a', content: 'Draf lama C1.');
    final repository = _GatedRestoreRepository()..hierarchy = _hierarchy();

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

    // Mulai replay restore; saveSceneDraft produksi tertahan di gate.
    await tester.tap(find.text('Pulihkan Draft'));
    await tester.pump();
    expect(repository.saveStarted, isTrue, reason: 'restore harus masuk IO');

    // Jendela nyata: SELAMA await save, pengguna mengetik lagi dan autosave
    // men-stage C2 ke jurnal menggantikan C1.
    journal.stageForTest(sceneId: 'scene-a', content: 'Ketikan baru C2.');

    // Save restore selesai -> acknowledge dijalankan.
    repository.releaseSave();
    await tester.pumpAndSettle();

    // BUG-6 (RED): ack blind menghapus entri C2 yang belum pernah
    // di-persist = silent loss. GREEN: entri C2 dipertahankan.
    final pending = await journal.pendingEntries();
    expect(
      pending.map((e) => e.content),
      contains('Ketikan baru C2.'),
      reason:
          'restore wajib acknowledge content-aware — entri yang tergantikan '
          'selama await save tidak boleh dihapus buta',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore replay still acknowledges when the entry was not '
      'replaced (run128 BUG-8 contract preserved)', (tester) async {
    final journal = _GuardedJournal()
      ..stageForTest(sceneId: 'scene-a', content: 'Draf lama C1.');
    final repository = _GatedRestoreRepository()..hierarchy = _hierarchy();

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

    await tester.tap(find.text('Pulihkan Draft'));
    await tester.pump();
    repository.releaseSave();
    await tester.pumpAndSettle();

    // Tanpa penggantian: entri C1 TERAP harus hilang dan konten masuk repo.
    expect(await journal.pendingEntries(), isEmpty);
    expect(repository.savedByScene['scene-a'], 'Draf lama C1.');
    expect(find.text('DRAFT RECOVERY'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

StoryHierarchy _hierarchy() => const StoryHierarchy(
  story: StoryModel(
    assetId: 'story-1',
    projectId: 'p1',
    title: 'Recovery Guard Story',
  ),
  arcs: [],
  chapters: [
    StoryChapterNode('chapter-1', 'Chapter One', [
      StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
    ]),
  ],
  scenes: [],
);

/// Fake jurnal dengan SEMANTIK content-aware yang sama dengan
/// DurableDraftJournal produksi (dibuktikan durable_draft_journal_test):
/// ack dengan content hanya menghapus bila konten di disk persis sama;
/// ack tanpa content menghapus tanpa syarat (keputusan eksplisit).
class _GuardedJournal extends DurableDraftJournal {
  _GuardedJournal() : super(dir: Directory.systemTemp);

  final Map<String, PendingDraftEntry> entries = {};

  void stageForTest({required String sceneId, required String content}) {
    entries[sceneId] = PendingDraftEntry(
      sceneId: sceneId,
      content: content,
      stagedAt: DateTime(2026, 9, 12, 23),
    );
  }

  @override
  Future<List<PendingDraftEntry>> pendingEntries() async =>
      entries.values.toList()..sort((a, b) => a.sceneId.compareTo(b.sceneId));

  @override
  Future<void> acknowledge(String sceneId, {String? content}) async {
    final existing = entries[sceneId];
    if (existing == null) return;
    if (content != null && existing.content != content) return;
    entries.remove(sceneId);
  }
}

/// Repository restore dengan saveSceneDraft tertahan — mereproduksi jendela
/// await I/O produksi tempat stage konkuren masuk jurnal.
class _GatedRestoreRepository extends StoryRepositoryImpl {
  _GatedRestoreRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: '-'),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  final Map<String, String> savedByScene = {};

  Completer<void>? _saveGate;
  bool saveStarted = false;

  void releaseSave() => _saveGate?.complete();

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => savedByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    saveStarted = true;
    final gate = Completer<void>();
    _saveGate = gate;
    await gate.future;
    savedByScene[sceneId] = content;
  }

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(
    String sceneId,
  ) async => const [];

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async => const [];
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
