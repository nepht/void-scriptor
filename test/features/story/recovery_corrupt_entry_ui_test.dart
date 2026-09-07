// Bug-hunt-run128 BUG-1 (kontrak UI): entri journal korup/truncated yang
// di-surface oleh DurableDraftJournal.pendingEntries() (isCorrupt: true)
// harus TAMPIL di panel DRAFT RECOVERY dengan status yang jelas, dan TIDAK
// menawarkan tombol "Pulihkan Draft" (isi tidak dapat dipulihkan otomatis).
// Keputusan eksplisit pengguna yang tersedia: "Buang" (hapus entri journal).
//
// Catatan warning drift "multiple databases": _FakeExecutor (noSuchMethod)
// tidak pernah membuka file database; warning murni heuristik konstruktor
// drift karena fake dibuat 2x dalam satu proses test. Disable one-shot di
// harness ini saja (tidak menyentuh warning database produksi).
import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('corrupt journal entry is shown in DRAFT RECOVERY with discard '
      'only', (tester) async {
    final journal = _FakeDurableDraftJournal()
      ..entries['scene-korup'] = const PendingDraftEntry.corrupt(
        sceneId: 'scene-korup',
      );
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
                sceneId: 'scene-lain',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Panel recovery muncul dan menampilkan status korup yang jelas.
    expect(find.text('DRAFT RECOVERY'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recovery_corrupt_entry')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Isi draf tidak dapat dibaca (file journal korup atau '
        'terpotong). Draf ini tidak dapat dipulihkan otomatis.',
      ),
      findsOneWidget,
    );
    // Restore tidak ditawarkan untuk entri korup; buang tetap tersedia.
    expect(find.text('Pulihkan Draft'), findsNothing);
    expect(find.text('Buang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discard on a corrupt entry removes it from the panel', (
    tester,
  ) async {
    final journal = _FakeDurableDraftJournal()
      ..entries['scene-korup'] = const PendingDraftEntry.corrupt(
        sceneId: 'scene-korup',
      );
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
                sceneId: 'scene-lain',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();

    expect(journal.entries.containsKey('scene-korup'), isFalse);
    expect(find.text('DRAFT RECOVERY'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeDurableDraftJournal extends DurableDraftJournal {
  /// Directory nyata yang TIDAK PERNAH disentuh: semua method IO dioverride,
  /// super(dir:) hanya memenuhi kontrak constructor base class.
  _FakeDurableDraftJournal() : super(dir: Directory.systemTemp);

  final Map<String, PendingDraftEntry> entries = {};

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

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => null;
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}

StoryHierarchy _hierarchy() {
  return const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'T'),
    arcs: [],
    chapters: [],
    scenes: [],
  );
}
