// vs-hunt-20260912-autosave BUG-17 (penomoran referee on-disk; run270).
//
// `DurableDraftJournal.close()` punya kontrak nyata (drain stage in-flight,
// tolak stage pasca-close — bug-hunt-run197 BUG-4) tetapi TIDAK punya satu
// pun caller produksi: `workspace_resolver.dart` mengkonstruksi journal per
// StoryWorkspaceScreen dan layar tidak pernah menutupnya saat di-dispose.
// Setelah layar ditutup, instance journal yang ditinggalkan tetap bebas
// bermutasi di direktori journal tanpa batas lifecycle yang ditegakkan.
//
// Kontrak perbaikan: dispose layar story MENUTUP journal milik instance itu
// SETELAH flush autosave tuntas (persist -> acknowledge -> close). Screen
// lain / sesi berikutnya memakai instance baru dan tidak terpengaruh.
//
// Jurnal di sini adalah fake in-memory TANPA I/O (pola
// durable_autosave_wiring_test) supaya deterministik di fake-async zone;
// urutan event yang dicatat membuktikan close terjadi SETELAH ack flush.
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
    'disposing the story screen closes its durable journal after the flush',
    (tester) async {
      final journal = _RecordingJournal();
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
                  sceneId: 'scene-a',
                  draftJournal: journal,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'teks awal'), findsOneWidget);

      // Sunting draf; debounce 1500ms belum lewat (timer belum fire).
      await tester.enterText(
        find.widgetWithText(TextField, 'teks awal'),
        'draf sebelum tutup',
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Layar dibuang SEBELUM timer debounce fire.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      // 1) Flush-on-dispose tetap bekerja (kontrak lama dipertahankan).
      expect(repository.draftByScene['scene-a'], 'draf sebelum tutup');
      expect(journal.events, contains('ack:scene-a'));

      // 2) RED: journal milik layar yang sudah pergi HARUS ditutup setelah
      //    flush — sebelum patch tidak ada satu pun panggilan close() di
      //    jalur dispose (kontrak run197 BUG-4 tidak ditegakkan produksi).
      expect(
        journal.events,
        contains('close'),
        reason:
            'dispose() layar story wajib menutup draftJournal miliknya '
            'setelah persist+ack flush selesai',
      );
      expect(
        journal.events.indexOf('close'),
        greaterThan(journal.events.indexOf('ack:scene-a')),
        reason: 'close sebelum ack = acknowledge flush akan gagal (StateError)',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('a fresh journal instance is unaffected by a closed sibling '
      '(per-instance close, recovery still readable)', () async {
    final root = await Directory.systemTemp.createTemp('hermes-run270-jclose-');
    addTearDown(() async {
      try {
        await root.delete(recursive: true);
      } on FileSystemException {
        // Best-effort: Windows melepas handle sedikit terlambat.
      }
    });
    final dir = Directory('${root.path}/journal');
    final first = DurableDraftJournal(dir: dir);
    await first.stage(sceneId: 'scene-x', content: 'draf sesi satu');
    await first.close();
    await expectLater(
      first.stage(sceneId: 'scene-x', content: 'pasca-close'),
      throwsStateError,
    );

    final second = DurableDraftJournal(dir: dir);
    final pending = await second.pendingEntries();
    expect(pending.map((e) => e.sceneId), contains('scene-x'));
    await second.stage(sceneId: 'scene-y', content: 'draf sesi dua');
    expect(
      (await second.pendingEntries()).map((e) => e.sceneId),
      containsAll(<String>['scene-x', 'scene-y']),
    );
  });
}

class _RecordingJournal extends DurableDraftJournal {
  _RecordingJournal() : super(dir: Directory.systemTemp);

  final List<String> events = <String>[];
  final Map<String, PendingDraftEntry> entries = {};

  @override
  Future<void> stage({required String sceneId, required String content}) async {
    events.add('stage:$sceneId');
    entries[sceneId] = PendingDraftEntry(
      sceneId: sceneId,
      content: content,
      stagedAt: DateTime(2026, 9, 13, 8),
    );
  }

  @override
  Future<List<PendingDraftEntry>> pendingEntries() async =>
      entries.values.toList()..sort((a, b) => a.sceneId.compareTo(b.sceneId));

  @override
  Future<void> acknowledge(String sceneId, {String? content}) async {
    events.add('ack:$sceneId');
    entries.remove(sceneId);
  }

  @override
  Future<void> close() async {
    events.add('close');
    await super.close();
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

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = _hierarchy();
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

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
