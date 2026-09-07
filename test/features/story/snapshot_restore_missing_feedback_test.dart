// bug-hunt-run128 BUG-11 — story_repository_impl.dart:347: firstWhere tanpa
// orElse — memulihkan snapshot yang id-nya sudah dipangkas retensi (retention
// purge terjadi saat capture) melempar StateError mentah, dan
// story_workspace_screen.dart `_restoreSnapshot` tidak menangkapnya: exception
// asinkron lepas tanpa umpan balik pengguna apa pun. Referee: REAL BUG Low.
//
// Dua kontrak yang dibuktikan file ini:
// 1. Restore dari tombol Restore atas snapshot yang sudah tidak ada TIDAK
//    boleh melepas exception tak tertangkap; pengguna melihat SnackBar
//    penjelasan (finally reset tetap berjalan — klaim lockout run128 sudah
//    dibantah Referee, proteksi finally tidak diubah).
// 2. (Diagnosability) StateError dari jalur restore menamai id snapshot dan
//    scene — bukan pesan generik "No element".
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart'
    show DraftSnapshotKind;
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  // Harness UI memakai _FakeDatabase (noSuchMethod) — warning drift
  // "multiple databases" noise di sini (preseden run132/run133).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'BUG-11: Restore atas snapshot yang sudah ter-purge retensi menampilkan '
    'SnackBar, tanpa exception lepas',
    (tester) async {
      final repository = _GatedRestoreStoryRepository();
      repository.hierarchy = _hierarchyWithScene();

      await tester.pumpWidget(
        _wrap(StoryWorkspaceScreen(storyId: 'story-1', repository: repository)),
      );
      await tester.pump();
      await tester.pump();

      // Daftar snapshot scene aktif terisi satu entri dari repository.
      repository.draftGates.single.complete('isi draf a');
      repository.snapshotGates.single.complete([
        _snapshot('snap-hilang', 'scene-a', 'Snap A'),
      ]);
      repository.quickRefGates.single.complete([_quickRef('Karakter A')]);
      await tester.pump();
      expect(find.text('Snap A'), findsOneWidget);

      // Pengguna menekan Restore pada daftar yang sudah basi: id-nya tidak
      // ada lagi di repository (di-purge retensi). Repository melempar
      // StateError — perilaku repository produksi pra-patch.
      await tester.ensureVisible(find.text('Restore'));
      await tester.pump();
      await tester.tap(find.text('Restore'));
      await tester.pump();

      // Feedback pengguna: SnackBar penjelasan, bukan exception senyap.
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'kegagalan restore wajib terlihat pengguna (BUG-11)',
      );
      expect(
        find.textContaining('Snapshot tidak dapat dipulihkan'),
        findsOneWidget,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'StateError dari restore tidak boleh lepas tak tertangkap',
      );

      // finally tetap memuat ulang daftar snapshot (kontrak proteksi run128):
      // gate kedua adalah permintaan reload pasca-kegagalan.
      expect(
        repository.snapshotGates.length,
        2,
        reason: 'finally _restoreSnapshot wajib memuat ulang daftar snapshot',
      );
      repository.snapshotGates[1].complete([
        _snapshot('snap-lain', 'scene-a', 'Snap A'),
      ]);
      await tester.pump();

      // Ratakan timer SnackBar agar tidak ada timer pending di akhir test.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
    },
  );

  test(
    'BUG-11: StateError jalur restore menamai id snapshot dan scene',
    () async {
      final root = await Directory.systemTemp.createTemp('novel-bug11-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      final database = await databaseService.open(dbPath);
      addTearDown(database.close);
      final storyService = CreateStoryService(database: database, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Novel Restore Missing',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        title: 'Bab Satu',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene Pertama',
        sceneNumber: 1,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );

      // Retensi 1: snapshot kedua memangkas snapshot pertama dari daftar,
      // sehingga id yang tercatat basi dan restore-nya miss di firstWhere —
      // mekanisme eksak temuan run128.
      await repository.setDraftSnapshotRetention(sceneId, maxSnapshots: 1);
      await repository.saveSceneDraft(sceneId, 'draf a');
      final idA = await repository.captureSceneDraftSnapshot(
        sceneId,
        label: 'A',
      );
      await repository.saveSceneDraft(sceneId, 'draf b');
      final idB = await repository.captureSceneDraftSnapshot(
        sceneId,
        label: 'B',
      );
      final remaining = await repository.getSceneDraftSnapshots(sceneId);
      expect(remaining, hasLength(1));
      final purgedId = remaining.single.id == idA ? idB : idA;
      expect(purgedId, anyOf(idA, idB));

      await expectLater(
        repository.restoreSceneDraftSnapshot(sceneId, snapshotId: purgedId),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(purgedId),
          ),
        ),
        reason:
            'pesan kegagalan harus menamai snapshot yang hilang, '
            'bukan generik "No element" (BUG-11 diagnosability)',
      );
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 1200, child: child)),
    ),
  );
}

StoryHierarchy _hierarchyWithScene() {
  return const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'Judul Uji'),
    arcs: [],
    chapters: [
      StoryChapterNode('chapter-1', 'Chapter One', [
        StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
      ]),
    ],
    scenes: [],
  );
}

SceneDraftSnapshot _snapshot(String id, String sceneId, String label) {
  return SceneDraftSnapshot(
    id: id,
    sceneId: sceneId,
    projectId: 'p1',
    kind: 'manual',
    content: '',
    label: label,
    createdAt: DateTime(2026),
  );
}

CharacterQuickRef _quickRef(String name) {
  return CharacterQuickRef(
    characterId: 'c-$name',
    name: name,
    compactDescription: 'deskripsi uji',
    role: 'participant',
  );
}

/// Repository UI: muatan ter-gate (harness run133), dan restore selalu
/// melempar StateError — meniru perilaku repository produksi ketika id
/// snapshot sudah dipangkas retensi (pra-patch).
class _GatedRestoreStoryRepository extends StoryRepositoryImpl {
  _GatedRestoreStoryRepository()
    : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = _hierarchyWithScene();

  final draftGates = <Completer<String?>>[];
  final snapshotGates = <Completer<List<SceneDraftSnapshot>>>[];
  final quickRefGates = <Completer<List<CharacterQuickRef>>>[];

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getStoryTitle(String storyId) async => hierarchy.story.title;

  @override
  Future<String?> getSceneDraft(String sceneId) {
    final gate = Completer<String?>();
    draftGates.add(gate);
    return gate.future;
  }

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {}

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(String sceneId) {
    final gate = Completer<List<CharacterQuickRef>>();
    quickRefGates.add(gate);
    return gate.future;
  }

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) {
    final gate = Completer<List<SceneDraftSnapshot>>();
    snapshotGates.add(gate);
    return gate.future;
  }

  @override
  Future<String> restoreSceneDraftSnapshot(
    String sceneId, {
    required String snapshotId,
  }) async {
    // Perilaku pra-patch repository produksi: firstWhere tanpa orElse.
    throw StateError('No element');
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
